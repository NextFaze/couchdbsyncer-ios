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
@synthesize downloadPolicy;

// readonly
@synthesize countReq, countFin, countHttpFin, bytes, bytesDoc, bytesAtt;
@synthesize startedAt;

#pragma mark -

- (id)initWithStore:(CouchDBSyncerStore *)s database:(CouchDBSyncerDatabase *)d {
    self = [super init];
    if(self) {
        fetchQueue = [[NSOperationQueue alloc] init];
        [fetchQueue setMaxConcurrentOperationCount:MaxDownloadCount];
        responseQueue = [[NSOperationQueue alloc] init];
        [responseQueue setMaxConcurrentOperationCount:1];
        
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
    [store release];
    [database release];
    
    [fetchQueue release];
    [responseQueue release];
    [changeFetcher release];
    [startedAt release];
    
    [super dealloc];
}

#pragma mark Private

- (NSString *)urlEncodeValue:(NSString *)str {
    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL,
                                                                            CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
    return [result autorelease];
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
    
    running = NO;
    aborted = NO;
    
    [fetchQueue cancelAllOperations];
    [responseQueue cancelAllOperations];
    
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
    aborted = YES;
    running = NO;
}

- (void)completed {
    running = NO;
    //[delegate couchDBSyncerCompleted:self];
}

- (void)update {
    if([fetchThread isExecuting]) {
        LOG(@"already fetching changes, returning");
        return;
    }
    [fetchThread release];
    fetchThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateThread) object:nil];
    [fetchThread start];
}

- (void)updateThread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self resetReqCounters];
    running = YES;
    aborted = NO;
    changesReported = NO;
    
    [startedAt release];
    startedAt = [[NSDate date] retain];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/_changes?since=%d", database.url, database.sequenceId]];
    [changeFetcher release];
    changeFetcher = [[CouchDBSyncerFetch alloc] initWithURL:url delegate:self];
    changeFetcher.fetchType = CouchDBSyncerFetchTypeChanges;
    [changeFetcher fetch];
    countReq++;
    
    [pool release];
}

// fetches document / attachments (adds to fetch queue)
- (void)fetchAttachment:(CouchDBSyncerAttachment *)att priority:(NSOperationQueuePriority)priority {

    if(aborted) {
        LOG(@"syncer is aborted, returning");
        return;
    }
    
    if(att.document.deleted) {
        // document deleted
        LOG(@"attachment document is deleted, returning");
        return;  // do nothing
    }
    
    /*
    
    // don't fetch attachment if it is already in the queue to be fetched.
    // (this could happen if there was an attachment with unfetched changes, and the attachment has changed again).
    for(CouchDBSyncerFetch *fetch in fetchQueue.operations) {
        if(![fetch isCancelled] && fetch.fetchType == CouchDBSyncerFetchTypeAttachment) {
            CouchDBSyncerAttachment *att_fetching = [[fetch.response objects] objectAtIndex:0];
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
     */
    
    // fetch attachment
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@", database.url, [self urlEncodeValue:att.documentId], [self urlEncodeValue:att.filename]];    
    NSURL *url = [NSURL URLWithString:path];
    
    CouchDBSyncerFetch *fetcher = [[CouchDBSyncerFetch alloc] initWithURL:url delegate:self];
    fetcher.queuePriority = priority;
    fetcher.fetchType = CouchDBSyncerFetchTypeAttachment;
    [fetchQueue addOperation:fetcher];
    [fetcher release];
    
    countReqAtt++;
}

- (void)fetchDocument:(CouchDBSyncerDocument *)doc priority:(NSOperationQueuePriority)priority {
    if(aborted) {
        LOG(@"syncer is aborted, returning");
        return;
    }
    
    if(bulkFetcher == nil) {
        // create a new bulk fetch operation
        bulkFetcher = [[CouchDBSyncerBulkFetch alloc] initWithURL:database.url delegate:self];
        bulkFetcher.queuePriority = priority;
    } else {
        // need to manually increment request count
        countReq++;
    }
    
    // add document to bulk fetcher list
    [bulkFetcher addDocument:doc];
    
    if(docsPerRequest > 0 && [bulkFetcher documentCount] >= docsPerRequest) {
        // bulk fetcher is ready to start
        [fetchQueue addOperation:bulkFetcher];
        [bulkFetcher release];
        bulkFetcher = nil;
        
    }
    
    countReqDoc++;
}

- (void)fetchAttachment:(CouchDBSyncerAttachment *)att {
    [self fetchAttachment:att priority:NSOperationQueuePriorityLow];
}

- (void)fetchDocument:(CouchDBSyncerDocument *)doc {
    [self fetchDocument:doc priority:NSOperationQueuePriorityNormal];
}

- (void)fetchDatabaseInformation {
    CouchDBSyncerFetch *fetcher = [[CouchDBSyncerFetch alloc] initWithURL:database.url delegate:self];
    fetcher.fetchType = CouchDBSyncerFetchTypeDBInfo;
    [fetchQueue addOperation:fetcher];
    [fetcher release];
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

- (void)couchDBSyncerFetchCompleted:(CouchDBSyncerFetch *)fetcher {
    countHttpFin++;
    
    if(fetcher.error) {
        // error occurred
        // TODO: retry fetches a few times ?
        
        // abort all outstanding fetch requests
        [self abort];
        
        // notify delegate
        //[delegate couchDBSyncer:self didFailWithError:fetcher.error];
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
        
        // report completion if no changes were detected
        if([list count] == 0) {
            [self completed];
            return;
        }
        
        // download changed documents
        for(CouchDBSyncerDocument *doc in changes) {
            policy.download = [doc isDesignDocument] ? NO : YES;
            policy.priority = NSOperationQueuePriorityNormal;
            
            if([delegate respondsToSelector:@selector(couchDBSyncerStore:document:policy:)])
                [delegate couchDBSyncerStore:self document:doc policy:policy];
            
            if(policy.download)
                [syncer fetchDocument:doc priority:policy.priority];
        }
        
        [policy release];
        
        // download unfetched attachments.
        // need to convert managed objects to CouchDBSyncerAttachments first
        NSArray *unfetchedAttachments = [self unfetchedAttachments];
        NSMutableArray *list = [NSMutableArray array];
        for(MOCouchDBSyncerAttachment *attachment in unfetchedAttachments) {
            [list addObject:[self attachmentFromManagedObject:attachment]];
        }
        if([list count] > 0) {
            LOG(@"downloading %d unfetched attachments", [list count]);
            [self downloadAttachments:list];
        }
        

    }
    else {
        // fetched data
        LOG(@"fetched data: %d", fetcher.fetchType);
        int len = [[fetcher data] length];
        bytes += len;
        
        if(fetcher.fetchType == CouchDBSyncerFetchTypeBulkDocuments) {
            // fetched multiple documents
            bytesDoc += len;
        }
        else if(fetcher.fetchType == CouchDBSyncerFetchTypeAttachment) {
            // fetched attachment
            CouchDBSyncerAttachment *att = [[fetcher.response objects] objectAtIndex:0];
            att.content = [fetcher data];
            bytesAtt += len;
        }
        else if(fetcher.fetchType == CouchDBSyncerFetchTypeDBInfo) {
            // fetched db info
            CouchDBSyncerObject *dbinfo = [[CouchDBSyncerObject alloc] initWithDictionary:[fetcher dictionary]];
            [fetcher.response addObject:dbinfo];
            [dbinfo release];
        }
        
        [fetcher.response markCompleted];        
        bytes += len;
        
        //if([delegate respondsToSelector:@selector(couchDBSyncerProgress:)])
        //    [delegate couchDBSyncerProgress:self];
    }
}

/*
- (void)couchDBSyncer:(CouchDBSyncer *)s didFetchChanges:(NSArray *)changes {
    LOG(@"fetched changelist: %d items", [changes count]);
    CouchDBSyncerStorePolicy *policy = [[CouchDBSyncerStorePolicy alloc] init];
    
    // download changed documents
    for(CouchDBSyncerDocument *doc in changes) {
        policy.download = [doc isDesignDocument] ? NO : YES;
        policy.priority = NSOperationQueuePriorityNormal;
        
        if([delegate respondsToSelector:@selector(couchDBSyncerStore:document:policy:)])
            [delegate couchDBSyncerStore:self document:doc policy:policy];
        
        if(policy.download)
            [syncer fetchDocument:doc priority:policy.priority];
    }
    
    [policy release];
    
    // download unfetched attachments.
    // need to convert managed objects to CouchDBSyncerAttachments first
    NSArray *unfetchedAttachments = [self unfetchedAttachments];
    NSMutableArray *list = [NSMutableArray array];
    for(MOCouchDBSyncerAttachment *attachment in unfetchedAttachments) {
        [list addObject:[self attachmentFromManagedObject:attachment]];
    }
    if([list count] > 0) {
        LOG(@"downloading %d unfetched attachments", [list count]);
        [self downloadAttachments:list];
    }
}
 
 */

/*
#pragma mark CouchDBSyncerResponseDelegate

- (void)couchDBSyncerResponseComplete:(CouchDBSyncerResponse *)response {
    if([response.objects count] == 0) {
        // response with no objects, single request
        countFin++;
    }
    for(CouchDBSyncerObject *obj in response.objects) {
        LOG(@"response object: %@", obj);
        
        if([obj isKindOfClass:[CouchDBSyncerDocument class]]) {
            // fetched document contents
            CouchDBSyncerDocument *doc = (CouchDBSyncerDocument *)obj;
            if(doc.deleted) {
                [delegate couchDBSyncer:self didFindDeletedDocument:doc];
            } else {
                [delegate couchDBSyncer:self didFetchDocument:doc];
            }
            countFinDoc++;
        }
        else if([obj isKindOfClass:[CouchDBSyncerAttachment class]]) {
            // fetched attachment
            [delegate couchDBSyncer:self didFetchAttachment:(CouchDBSyncerAttachment *)obj];
            countFinAtt++;
        }
        else {
            // fetched database information
            if([delegate respondsToSelector:@selector(couchDBSyncer:didFetchDatabaseInformation:)])
                [delegate couchDBSyncer:self didFetchDatabaseInformation:obj.dictionary];
        }
        // request completed
        countFin++;
    }	
        
    if(changesReported && countFin == countReq)
        [self completed];
}
 */

@end
