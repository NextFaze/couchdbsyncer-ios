//
//  CouchDBSyncerStore.h
//  CouchDBSyncer
//
//  Created by ASW on 26/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CouchDBSyncer.h"
#import <CoreData/CoreData.h>
#import "MOCouchDBSyncerDatabase.h"
#import "MOCouchDBSyncerDocument.h"
#import "MOCouchDBSyncerAttachment.h"
#import "CouchDBSyncerStorePolicy.h"

@protocol CouchDBSyncerStoreDelegate;

@interface CouchDBSyncerStore : NSObject <CouchDBSyncerDelegate> {
    CouchDBSyncer *syncer;
    NSString *name, *serverPath, *modelTypeKey;
    
    // core data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;	
    
    NSError *error;
    
    MOCouchDBSyncerDatabase *db;
    NSObject<CouchDBSyncerStoreDelegate> *delegate;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, retain) NSString *serverPath, *modelTypeKey;
@property (nonatomic, retain) NSObject<CouchDBSyncerStoreDelegate> *delegate;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) CouchDBSyncer *syncer;

- (id)initWithName:(NSString *)n serverPath:(NSString *)url delegate:(id)d;

- (void)fetchChanges;
- (void)purge;
- (NSDictionary *)statistics;

- (NSArray *)documents;
- (NSArray *)documentsMatching:(NSPredicate *)predicate;
- (NSArray *)documentsOfType:(NSString *)type;
- (NSArray *)documentsOfType:(NSString *)type tagged:(NSString *)tag;
- (NSArray *)documentsTagged:(NSString *)tag;

@end


@protocol CouchDBSyncerStoreDelegate <NSObject>

- (void)couchDBSyncerStoreProgress:(CouchDBSyncerStore *)store;
- (void)couchDBSyncerStoreCompleted:(CouchDBSyncerStore *)store;
- (void)couchDBSyncerStoreFailed:(CouchDBSyncerStore *)store;

@optional

- (void)couchDBSyncerStore:(CouchDBSyncerStore *)store document:(CouchDBSyncerDocument *)doc policy:(CouchDBSyncerStorePolicy *)policy;
- (void)couchDBSyncerStore:(CouchDBSyncerStore *)store attachment:(CouchDBSyncerAttachment *)att policy:(CouchDBSyncerStorePolicy *)policy;

- (void)couchDBSyncerStore:(CouchDBSyncerStore *)store willReplaceDatabase:(NSString *)path;

@end
