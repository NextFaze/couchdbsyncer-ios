//
//  CouchDBSyncer.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CouchDBSyncerDelegate.h"
#import "CouchDBSyncerDocument.h"
#import "CouchDBSyncerFetch.h"
#import "CouchDBSyncerAttachment.h"
#import "CouchDBSyncerBulkFetch.h"

@interface CouchDBSyncer : NSObject <CouchDBSyncerFetchDelegate,CouchDBSyncerResponseDelegate> {
    NSString *serverPath;
    int sequenceId;
    id<CouchDBSyncerDelegate> delegate;
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

@property (nonatomic, retain) NSString *serverPath;
@property (nonatomic, assign) int sequenceId;
@property (nonatomic, assign) id<CouchDBSyncerDelegate> delegate;
@property (nonatomic, readonly) int bytes, bytesDoc, bytesAtt, countReq, countFin, countHttpFin;
@property (nonatomic, assign) int docsPerRequest, maxConcurrentFetches;
@property (nonatomic, readonly) NSDate *startedAt;

- (id)initWithServerPath:(NSString *)path delegate:(id<CouchDBSyncerDelegate>)d;

- (void)fetchChanges;
- (void)fetchChangesSince:(int)sid;
- (void)abort;  // abort fetch

// fetches document / attachments (adds to fetch queue)
- (void)fetchAttachment:(CouchDBSyncerAttachment *)attachment priority:(NSOperationQueuePriority)priority;
- (void)fetchAttachment:(CouchDBSyncerAttachment *)attachment;
- (void)fetchDocument:(CouchDBSyncerDocument *)doc priority:(NSOperationQueuePriority)priority;
- (void)fetchDocument:(CouchDBSyncerDocument *)doc;

// fetch database information
- (void)fetchDatabaseInformation;

// progress reporting
- (float)progress;
- (float)progressDocuments;
- (float)progressAttachments;

@end
