//
//  CouchDBSyncer.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CouchDBSyncerDocument.h"
#import "CouchDBSyncerFetch.h"
#import "CouchDBSyncerAttachment.h"
#import "CouchDBSyncerBulkFetch.h"
#import "CouchDBSyncerStore.h"
#import "CouchDBSyncerDatabase.h"
#import "CouchDBSyncerDownloadPolicy.h"

@interface CouchDBSyncer : NSObject <CouchDBSyncerFetchDelegate> {
    NSObject<CouchDBSyncerDownloadPolicy> *downloadPolicy;
    CouchDBSyncerDatabase *database;
    CouchDBSyncerStore *store;
    
    NSThread *fetchThread;
    CouchDBSyncerFetch *changeFetcher;
    NSOperationQueue *responseQueue;    // queue of responses, returns responses in ascending sequence id order
    NSOperationQueue *fetchQueue;       // SyncerFetch objects go here when ready to be fetched
    NSDate *startedAt;
    
    BOOL aborted, running, changesReported;
    
    int docsPerRequest;                      // documents per request - tunable parameter
    int maxConcurrentFetches;                // maximum concurrent fetch operations
    CouchDBSyncerBulkFetch *bulkFetcher;     // current bulk fetch operation
    
    // counters
    int countReq, countReqDoc, countReqAtt;  // requests
    int countFin, countFinDoc, countFinAtt;  // requests (completed)
    int countHttpFin;                        // http requests (completed)
    
    int bytes, bytesDoc, bytesAtt;
}

@property (nonatomic, readonly) int bytes, bytesDoc, bytesAtt, countReq, countFin, countHttpFin;
@property (nonatomic, assign) int docsPerRequest, maxConcurrentFetches;
@property (nonatomic, readonly) NSDate *startedAt;
@property (nonatomic, retain) NSObject<CouchDBSyncerDownloadPolicy> *downloadPolicy;

- (id)initWithStore:(CouchDBSyncerStore *)store database:(CouchDBSyncerDatabase *)database;

- (void)update;
- (void)abort;  // abort fetch

// progress reporting
- (float)progress;
- (float)progressDocuments;
- (float)progressAttachments;

@end
