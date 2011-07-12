//
//  CouchDBSyncer.m
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncer.h"
#import "CouchDBSyncerResponse.h"
#import "NSObject+SBJson.h"
#import "CouchDBSyncerObject.h"

#define MaxDownloadCount        3   // maximum number of concurrent downloads
#define MaxResponseQueueLength 20   // maximum number of outstanding responses

@implementation CouchDBSyncer

@synthesize delegate, sequenceId, serverPath, docsPerRequest;

// readonly
@synthesize countReq, countFin, countHttpFin, bytes, bytesDoc, bytesAtt;
@synthesize startedAt;

#pragma mark Private

- (NSString *)urlEncodeValue:(NSString *)str {
    NSString *result = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)str, NULL,
                                                                            CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8);
    return [result autorelease];
}

// add a fetch response to the response queue
- (CouchDBSyncerResponse *)fetcherResponse:(CouchDBSyncerObject *)obj dependencies:(BOOL)withDeps {
    
    // set up response
    CouchDBSyncerResponse *response = [[CouchDBSyncerResponse alloc] init];    
    response.delegate = self;
    if(obj) [response addObject:obj];
    
    NSOperation *dep = nil;
    if(withDeps) {
        // find response dependencies.
        // documents/attachments should be returned in ascending sequence id order
        // (this also ensures attachments are returned after the documents are returned)
        for(NSOperation *op in [responseQueue.operations reverseObjectEnumerator]) {
            if(![op isCancelled]) {
                dep = op;
                break;
            }
        }
        if(bulkFetcher) dep = bulkFetcher;
        if(dep) [response addDependency:dep];
    }
    //LOG(@"created response, dependency: %@", dep);
    
    // add to response queue
    [responseQueue addOperation:response];
    
    countReq++;
    
    return [response autorelease];
}

- (CouchDBSyncerResponse *)fetcherResponse:(CouchDBSyncerObject *)obj {
    return [self fetcherResponse:obj dependencies:YES];
}

#pragma mark -

- (id)init {
    if((self = [super init])) {
        fetchQueue = [[NSOperationQueue alloc] init];
        [fetchQueue setMaxConcurrentOperationCount:MaxDownloadCount];
        responseQueue = [[NSOperationQueue alloc] init];
        [responseQueue setMaxConcurrentOperationCount:1];
        
        maxConcurrentFetches = MaxDownloadCount;
        docsPerRequest = 0;  // unlimited
    }
    return self;
}

- (id)initWithServerPath:(NSString *)path delegate:(id<CouchDBSyncerDelegate>)d {
    if((self = [self init])) {
        self.serverPath = path;
        self.delegate = d;
    }
    return self;
}

- (void)dealloc {
    delegate = nil;
    [fetchQueue release];
    [responseQueue release];
    [serverPath release];
    [changeFetcher release];
    [startedAt release];
    
    [super dealloc];
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
    [delegate couchDBSyncerCompleted:self];
}

- (void)fetchChanges {
    [self fetchChangesSince:sequenceId];
}

- (void)fetchChangesSince:(int)sid {
    if(running) {
        LOG(@"already fetching changes, returning");
        return;
    }
    
    [self resetReqCounters];
    running = YES;
    aborted = NO;
    changesReported = NO;
    
    [startedAt release];
    startedAt = [[NSDate date] retain];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/_changes?since=%d", serverPath, sid]];
    [changeFetcher release];
    changeFetcher = [[CouchDBSyncerFetch alloc] initWithURL:url delegate:self];
    changeFetcher.fetchType = CouchDBSyncerFetchTypeChanges;
    [changeFetcher fetch];
    countReq++;
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
    
    // fetch attachment
    NSString *path = [NSString stringWithFormat:@"%@/%@/%@", serverPath, [self urlEncodeValue:att.documentId], [self urlEncodeValue:att.filename]];    
    NSURL *url = [NSURL URLWithString:path];
    
    CouchDBSyncerFetch *fetcher = [[CouchDBSyncerFetch alloc] initWithURL:url delegate:self];
    fetcher.queuePriority = priority;
    fetcher.response = [self fetcherResponse:att];
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
    
    if(doc.deleted) {
        // document deleted - just create a response, no need to perform fetch
        [self fetcherResponse:doc];
    }
    else {
        // need to fetch document
        if(bulkFetcher == nil) {
            // create response before bulkFetcher
            // (this is important for the dependency code, so the fetcher doesn't have itself as a dependency)
            CouchDBSyncerResponse *resp = [self fetcherResponse:nil];
            
            // create a new bulk fetch operation
            bulkFetcher = [[CouchDBSyncerBulkFetch alloc] initWithServerPath:serverPath delegate:self];
            bulkFetcher.queuePriority = priority;
            bulkFetcher.response = resp;
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
    NSURL *url = [NSURL URLWithString:serverPath];
    
    CouchDBSyncerFetch *fetcher = [[CouchDBSyncerFetch alloc] initWithURL:url delegate:self];
    fetcher.response = [self fetcherResponse:nil dependencies:NO];  // dbinfo response
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
        [delegate couchDBSyncer:self didFailWithError:fetcher.error];
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
        
        // notify delegate of list of changes
        [delegate couchDBSyncer:self didFetchChanges:list];
        
        // start bulk document fetch
        if(bulkFetcher) {
        	[fetchQueue addOperation:bulkFetcher];
            [bulkFetcher release];
            bulkFetcher = nil;
        }
        
        changesReported = YES;
        
        // report completion if no changes were detected
        if([list count] == 0) {
            [self completed];
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
        
        if([delegate respondsToSelector:@selector(couchDBSyncerProgress:)])
            [delegate couchDBSyncerProgress:self];
    }
}

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

@end
