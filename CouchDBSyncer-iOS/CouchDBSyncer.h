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

@protocol CouchDBSyncerDelegate;
@protocol CouchDBSyncerDownloadPolicyDelegate;

@interface CouchDBSyncer : NSObject <CouchDBSyncerFetchDelegate> {
    NSObject<CouchDBSyncerDownloadPolicyDelegate> *downloadPolicyDelegate;
    NSObject<CouchDBSyncerDelegate> *delegate;
    
    CouchDBSyncerDatabase *database;
    CouchDBSyncerStore *store;
    
    NSThread *fetchThread;
    CouchDBSyncerFetch *changeFetcher;
    NSOperationQueue *fetchQueue;       // SyncerFetch objects go here when ready to be fetched
    NSDate *startedAt;
    
    int docsPerRequest;                      // documents per request - tunable parameter
    int maxConcurrentFetches;                // maximum concurrent fetch operations
    CouchDBSyncerBulkFetch *bulkFetcher;     // current bulk fetch operation
    
    // counters
    int countReq, countReqDoc, countReqAtt;  // requests
    int countFin, countFinDoc, countFinAtt;  // requests (completed)
    int countHttpFin;                        // http requests (completed)
    
    int bytes, bytesDoc, bytesAtt;
}

@property (nonatomic, retain) NSError *error;
@property (nonatomic, readonly) int bytes, bytesDoc, bytesAtt, countReq, countFin, countHttpFin;
@property (nonatomic, assign) int docsPerRequest, maxConcurrentFetches;
@property (nonatomic, readonly) NSDate *startedAt;
@property (nonatomic, assign) NSObject<CouchDBSyncerDownloadPolicyDelegate> *downloadPolicyDelegate;
@property (nonatomic, assign) NSObject<CouchDBSyncerDelegate> *delegate;

- (id)initWithStore:(CouchDBSyncerStore *)store database:(CouchDBSyncerDatabase *)database;

- (void)update;
- (void)abort;  // abort fetch

// progress reporting
- (float)progress;
- (float)progressDocuments;
- (float)progressAttachments;

@end

@protocol CouchDBSyncerDownloadPolicyDelegate <NSObject>

@optional
- (BOOL)couchDBSyncerDownloadPolicy:(CouchDBSyncerDocument *)document;
- (BOOL)couchDBSyncerDownloadPolicy:(CouchDBSyncerDocument *)document attachment:(CouchDBSyncerAttachment *)attachment;
- (NSOperationQueuePriority)couchDBSyncerDownloadPriority:(CouchDBSyncerDocument *)document;
- (NSOperationQueuePriority)couchDBSyncerDownloadPriority:(CouchDBSyncerDocument *)document attachment:(CouchDBSyncerAttachment *)attachment;
@end

@protocol CouchDBSyncerDelegate <NSObject>

- (void)couchDBSyncerProgress:(CouchDBSyncer *)s;
- (void)couchDBSyncerCompleted:(CouchDBSyncer *)s;
- (void)couchDBSyncerFailed:(CouchDBSyncer *)s;

@end
