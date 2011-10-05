//
//  CouchDBSyncer.m
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncer.h"
#import "NSObject+SBJson.h"
#import "CouchDBSyncerObject.h"

#define MaxDownloadCount        3   // maximum number of concurrent downloads
#define MaxResponseQueueLength 20   // maximum number of outstanding responses

@implementation CouchDBSyncer

@synthesize docsPerRequest;
@synthesize downloadPolicyDelegate, delegate;

// readonly
@synthesize countReq, countFin, countHttpFin, bytes, bytesDoc, bytesAtt;
@synthesize startedAt;
@synthesize error;

#pragma mark -

- (id)initWithStore:(CouchDBSyncerStore *)s database:(CouchDBSyncerDatabase *)d {
    self = [super init];
    if(self) {
        fetchQueue = [[NSOperationQueue alloc] init];
        [fetchQueue setMaxConcurrentOperationCount:MaxDownloadCount];

        maxConcurrentFetches = MaxDownloadCount;
        docsPerRequest = 0;  // unlimited
        
        store = [s retain];
        database = [d retain];
    }
    return self;
}

- (id)init {
    self = [self initWithStore:nil database:nil];
    return self;
}

- (void)dealloc {
    delegate = nil;
    downloadPolicyDelegate = nil;
    
    [store release];
    [database release];
    
    [fetchQueue release];
    [changeFetcher release];
    [startedAt release];
    [error release];
    
    [super dealloc];
}

#pragma mark Private

- (void)callDelegate:(SEL)selector {
    if([delegate respondsToSelector:selector])
        [delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:YES];
}

- (NSString *)urlEncodeValue:(NSString *)str {
    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL,
                                                                            CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
    return [result autorelease];
}

- (void)enqueueBulkFetch {
    if(bulkFetcher == nil) return;
    
    // if there's any other bulk fetch operations in the queue, make sure this one executes after them
    // (maintains sequence ordering)
    for(NSOperation *operation in [[fetchQueue operations] reverseObjectEnumerator]) {
        if(![operation isFinished] && [operation isKindOfClass:[CouchDBSyncerBulkFetch class]]) {
            [bulkFetcher addDependency:operation];
            LOG(@"bulk fetch %@ dependency: %@", bulkFetcher, operation);
            break;
        }
    }
    
    [fetchQueue addOperation:bulkFetcher];
    [bulkFetcher release];
    bulkFetcher = nil;
}

- (void)completed {
    [self callDelegate:@selector(couchDBSyncerCompleted:)];
}

#pragma mark -

- (void)resetReqCounters {
    // these counters are used for progress reporting.
    // reset them after change list is fetched
    countReq = countReqDoc = countReqAtt = 0;
    countFin = countFinDoc = countFinAtt = 0;    
}

// reset counters
- (void)reset {
    LOG(@"reset");
    [self resetReqCounters];
    bytes = bytesDoc = bytesAtt = 0;
    countHttpFin = 0;
        
    [fetchThread cancel];
    [fetchQueue cancelAllOperations];
    
    [bulkFetcher release];
    bulkFetcher = nil;
}

#pragma mark Accessors

- (void)setMaxConcurrentFetches:(int)count {
    maxConcurrentFetches = count;
    [fetchQueue setMaxConcurrentOperationCount:count];
}

- (int)maxConcurrentFetches {
    return maxConcurrentFetches;
}

#pragma mark Public

- (void)abort {
    // abort all document fetches
    // (prevents new documents being fetched)
    [self reset];
}

- (void)update {
    if([fetchThread isExecuting]) {
        LOG(@"update already running, returning");
        return;
    }
    
    [fetchThread release];
    fetchThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateThread) object:nil];
    [fetchThread start];
}

// fetches document / attachments (adds to fetch queue)
- (void)fetchDocument:(CouchDBSyncerDocument *)document attachment:(CouchDBSyncerAttachment *)att priority:(NSOperationQueuePriority)priority {

    if([fetchThread isCancelled]) {
        LOG(@"syncer is aborted, returning");
        return;
    }
    
    if(document.deleted) {
        // document deleted
        LOG(@"attachment document is deleted, returning");
        return;  // do nothing
    }
    
    // don't fetch attachment if it is already in the queue to be fetched.
    // (this could happen if there was an attachment with unfetched changes, and the attachment has changed again).
    for(CouchDBSyncerFetch *fetch in fetchQueue.operations) {
        if(![fetch isCancelled] && fetch.fetchType == CouchDBSyncerFetchTypeAttachment) {
            CouchDBSyncerAttachment *att_fetching = fetch.attachment;
            if([att_fetching.documentId isEqualToString:att.documentId] && [att_fetching.filename isEqualToString:att.filename]) {
                // same attachment
                if(att_fetching.revpos >= att.revpos) {
                    // already fetching same or newer attachment
                    LOG(@"attachment %@ already in fetch queue, skipping", att);
                    return;
                }
                else {
                    // an older version of the attachment is in the fetch queue - cancel it
                    LOG(@"cancelling fetch request for older attachment %@", att);
                    [fetch cancel];
                }
            }
        }
    }
    
    // fetch attachment
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@", database.url, [self urlEncodeValue:att.documentId], [self urlEncodeValue:att.filename]];    
    NSURL *url = [NSURL URLWithString:path];
    
    CouchDBSyncerFetch *fetcher = [[CouchDBSyncerFetch alloc] initWithURL:url delegate:self];
    fetcher.queuePriority = priority;
    fetcher.fetchType = CouchDBSyncerFetchTypeAttachment;
    fetcher.attachment = att;
    fetcher.document = document;
    [fetchQueue addOperation:fetcher];
    [fetcher release];
    
    countReq++;
    countReqAtt++;
}

- (void)fetchDocument:(CouchDBSyncerDocument *)doc priority:(NSOperationQueuePriority)priority {
    if([fetchThread isCancelled]) {
        LOG(@"syncer is aborted, returning");
        return;
    }
    
    if(bulkFetcher == nil) {
        // create a new bulk fetch operation
        bulkFetcher = [[CouchDBSyncerBulkFetch alloc] initWithURL:database.url delegate:self];
        bulkFetcher.queuePriority = priority;
    }
    
    // add document to bulk fetcher list
    [bulkFetcher addDocument:doc];
    countReq++;
    countReqDoc++;
    
    if(docsPerRequest > 0 && [bulkFetcher documentCount] >= docsPerRequest) {
        // bulk fetcher is ready to start
        [self enqueueBulkFetch];
    }    
}

/*
 - (BOOL)couchDBSyncerDownloadPolicy:(CouchDBSyncerDocument *)document;
 - (BOOL)couchDBSyncerDownloadPolicy:(CouchDBSyncerDocument *)document attachment:(CouchDBSyncerAttachment *)attachment;
 - (NSOperationQueuePriority)couchDBSyncerDownloadPriority:(CouchDBSyncerDocument *)document;
 - (NSOperationQueuePriority)couchDBSyncerDownloadPriority:(CouchDBSyncerDocument *)document attachment:(CouchDBSyncerAttachment *)attachment;
 */

- (void)fetchDocument:(CouchDBSyncerDocument *)document attachment:(CouchDBSyncerAttachment *)att {
    BOOL download = YES;
    NSOperationQueuePriority priority = NSOperationQueuePriorityLow;
    
    if([downloadPolicyDelegate respondsToSelector:@selector(couchDBSyncerDownloadPolicy:attachment:)])
        download = [downloadPolicyDelegate couchDBSyncerDownloadPolicy:document attachment:att];
    if([downloadPolicyDelegate respondsToSelector:@selector(couchDBSyncerDownloadPriority:attachment:)])
        priority = [downloadPolicyDelegate couchDBSyncerDownloadPriority:document attachment:att];
    
    if(download) {
        [self fetchDocument:document attachment:att priority:priority];
    } else {
        // TODO: delete if already downloaded?
        LOG(@"not downloading attachment: %@", att);
    }
}

- (void)fetchDocument:(CouchDBSyncerDocument *)doc {
    BOOL download = [doc isDesignDocument] ? NO : YES;
    NSOperationQueuePriority priority = NSOperationQueuePriorityNormal;
    
    if([downloadPolicyDelegate respondsToSelector:@selector(couchDBSyncerDownloadPolicy:)])
        download = [downloadPolicyDelegate couchDBSyncerDownloadPolicy:doc];
    if([downloadPolicyDelegate respondsToSelector:@selector(couchDBSyncerDownloadPriority:)])
        priority = [downloadPolicyDelegate couchDBSyncerDownloadPriority:doc];
    
    if(download) {
        [self fetchDocument:doc priority:priority];
    }
    else {
        // TODO: delete if already downloaded?
        LOG(@"not downloading document: %@", doc);
    }
}

- (void)fetchDatabaseInformation {
    CouchDBSyncerFetch *fetcher = [[CouchDBSyncerFetch alloc] initWithURL:database.url delegate:self];
    fetcher.fetchType = CouchDBSyncerFetchTypeDBInfo;
    [fetchQueue addOperation:fetcher];
    [fetcher release];
    
    countReq++;
}

- (void)fetchDocument:(CouchDBSyncerDocument *)document attachments:(NSArray *)attachments {
    for(CouchDBSyncerAttachment *att in attachments) {
        [self fetchDocument:document attachment:att];
    }
}

#pragma mark -

- (void)updateThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self resetReqCounters];
    
    [startedAt release];
    startedAt = [[NSDate date] retain];
    
    // download unfetched attachments.
    // (this queries the download policy again)
    NSArray *staleAttachments = [store staleAttachments:database];
    if([staleAttachments count] > 0) {
        LOG(@"downloading %d unfetched attachments", [staleAttachments count]);
        for(CouchDBSyncerAttachment *attachment in staleAttachments) {
            CouchDBSyncerDocument *document = [store document:database documentId:attachment.documentId];
            [self fetchDocument:document attachment:attachment];
        }
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/_changes?since=%d", database.url, database.sequenceId]];
    [changeFetcher release];
    changeFetcher = [[CouchDBSyncerFetch alloc] initWithURL:url delegate:self];
    changeFetcher.fetchType = CouchDBSyncerFetchTypeChanges;
    [fetchQueue addOperation:changeFetcher];
    countReq++;
    
    // wait until all operations are finished.
    // when this returns, sync is complete
    [fetchQueue waitUntilAllOperationsAreFinished];
    
    LOG(@"all operations finished");
    [self completed];
    
    [pool release];
}

#pragma mark -

// return percentage complete as a value between 0 and 1
- (float)progress {
    return countReq == 0 ? 0 : (float)countFin / countReq;
}
- (float)progressDocuments {
    return countReqDoc == 0 ? 0 : (float)countFinDoc / countReqDoc;
}
- (float)progressAttachments {
    return countReqAtt == 0 ? 0 : (float)countFinAtt / countReqAtt;
}

#pragma mark CouchDBSyncerFetchDelegate

- (void)reportThread {
    //LOG(@"thread: %@, main: %@", [NSThread currentThread], [NSThread isMainThread] ? @"yes" : @"no");
}

- (void)couchDBSyncerFetchCompleted:(CouchDBSyncerFetch *)fetcher {
    [self reportThread];
    
    countHttpFin++;
    
    if(fetcher.error) {
        // download error occurred
        
        // ignore attachment download errors - they will be redownloaded later
        // TODO: retry fetches a few times ?
        if(fetcher.fetchType != CouchDBSyncerFetchTypeAttachment) {
            // if failure occured fetching list of changes or a document, abort sync
            self.error = fetcher.error;

            // abort all outstanding fetch requests
            [self abort];
        
            // notify delegate
            [self callDelegate:@selector(couchDBSyncerFailed:)];
        }
        
        return;
    }
    
    if(fetcher == changeFetcher) {
        // fetched list of changes
        // example changes data:
        /*
         {"results":[
         {"seq":2,"id":"test2","changes":[{"rev":"1-e18422e6a82d0f2157d74b5dcf457997"}]}
         ],
         "last_seq":2}
         */

        countFin++;
        NSDictionary *changes = [fetcher dictionary];
        NSMutableArray *list = [NSMutableArray array];
        NSArray *results = [changes valueForKey:@"results"];

        // construct list of changes
        for(NSDictionary *change in results) {
            int seq = [[change valueForKey:@"seq"] intValue];
            NSString *docid = [change valueForKey:@"id"];
            BOOL deleted = [[change valueForKey:@"deleted"] boolValue];
            
            NSArray *changeList = [change valueForKey:@"changes"];
            NSDictionary *change1 = changeList.count > 0 ? [changeList objectAtIndex:0] : nil;
            NSString *rev = [change1 valueForKey:@"rev"];
            
            CouchDBSyncerDocument *doc = [[CouchDBSyncerDocument alloc] initWithDocumentId:docid revision:rev sequenceId:seq deleted:deleted];
            [list addObject:doc];
            [doc release];
        }
        
        [changeFetcher release];
        changeFetcher = nil;
        
        // download changed documents
        for(CouchDBSyncerDocument *doc in list) {
            [self fetchDocument:doc];
        }
        
        [self enqueueBulkFetch];
    }
    else {
        // fetched data
        LOG(@"fetched data: %d", fetcher.fetchType);
        int len = [[fetcher data] length];
        bytes += len;
        
        CouchDBSyncerUpdateContext *context = [store updateContext:database];

        if(fetcher.fetchType == CouchDBSyncerFetchTypeBulkDocuments) {
            // fetched multiple documents
            bytesDoc += len;
            CouchDBSyncerBulkFetch *bfetch = (CouchDBSyncerBulkFetch *)fetcher;
            for(CouchDBSyncerDocument *document in bfetch.documents) {
                [store update:context document:document];
                countFin++;
                countFinDoc++;

                // download attachments. 
                [self fetchDocument:document attachments:document.attachments];
            }
        }
        else if(fetcher.fetchType == CouchDBSyncerFetchTypeAttachment) {
            // fetched attachment
            CouchDBSyncerAttachment *att = fetcher.attachment;
            att.content = [fetcher data];
            bytesAtt += len;
            
            [store update:context attachment:att];
            countFin++;
            countFinAtt++;
        }
        else if(fetcher.fetchType == CouchDBSyncerFetchTypeDBInfo) {
            // fetched db info
            CouchDBSyncerObject *dbinfo = [[CouchDBSyncerObject alloc] initWithDictionary:[fetcher dictionary]];
            [dbinfo release];
            countFin++;
        }
        
        bytes += len;
        
        [self callDelegate:@selector(couchDBSyncerProgress:)];
    }
}


@end
