//
//  CouchDBSyncerDelegate.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

@class CouchDBSyncer;
@class CouchDBSyncerDocument;
@class CouchDBSyncerAttachment;

@protocol CouchDBSyncerDelegate <NSObject>

- (void)couchDBSyncer:(CouchDBSyncer *)syncer didFetchChanges:(NSArray *)changes;
- (void)couchDBSyncer:(CouchDBSyncer *)syncer didFetchDocument:(CouchDBSyncerDocument *)doc;
- (void)couchDBSyncer:(CouchDBSyncer *)syncer didFetchAttachment:(CouchDBSyncerAttachment *)att;
- (void)couchDBSyncer:(CouchDBSyncer *)syncer didFindDeletedDocument:(CouchDBSyncerDocument *)doc;
- (void)couchDBSyncer:(CouchDBSyncer *)syncer didFailWithError:(NSError *)error;
- (void)couchDBSyncerCompleted:(CouchDBSyncer *)s;

@optional

// progress has been made
- (void)couchDBSyncerProgress:(CouchDBSyncer *)s;

// db information
- (void)couchDBSyncer:(CouchDBSyncer *)syncer didFetchDatabaseInformation:(NSDictionary *)info;

@end
