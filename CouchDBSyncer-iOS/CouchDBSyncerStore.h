//
//  CouchDBSyncerStore.h
//  CouchDBSyncer
//
//  Created by ASW on 26/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CouchDBSyncerDatabase.h"
#import "CouchDBSyncerUpdateContext.h"
#import "CouchDBSyncerDocument.h"
#import "CouchDBSyncerAttachment.h"

@interface CouchDBSyncerStore : NSObject {
    NSString *modelTypeKey;
    
    // core data
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    
    NSError *error;
    NSString *shippedPath;
}

@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, retain) NSString *modelTypeKey;
@property (nonatomic, retain) NSError *error;

- (id)initWithShippedDatabasePath:(NSString *)shippedPath;

// purge the store (removes all databases)
- (void)purge;

// purge all data for the specified database
- (void)purge:(CouchDBSyncerDatabase *)database;

// remove the specified database completely
- (void)destroy:(CouchDBSyncerDatabase *)database;

- (NSDictionary *)statistics:(CouchDBSyncerDatabase *)database;

// get database with given name
- (CouchDBSyncerDatabase *)database:(NSString *)name;
- (NSArray *)databases;

// get database with the given name. if the database is not found locally, creates a new database with the 
// given name and url.
- (CouchDBSyncerDatabase *)database:(NSString *)name url:(NSURL *)url;

// get documents
- (NSArray *)documents:(CouchDBSyncerDatabase *)database;
- (NSArray *)documents:(CouchDBSyncerDatabase *)database matching:(NSPredicate *)predicate;
- (NSArray *)documents:(CouchDBSyncerDatabase *)database ofType:(NSString *)type;
- (NSArray *)documents:(CouchDBSyncerDatabase *)database ofType:(NSString *)type tagged:(NSString *)tag;
- (NSArray *)documents:(CouchDBSyncerDatabase *)database tagged:(NSString *)tag;
- (CouchDBSyncerDocument *)document:(CouchDBSyncerDatabase *)database documentId:(NSString *)documentId;

// get document types (array of NSString)
- (NSArray *)documentTypes:(CouchDBSyncerDatabase *)database;

// get all attachments from a document
- (NSArray *)attachments:(CouchDBSyncerDocument *)document;

// get attachment
- (CouchDBSyncerAttachment *)attachment:(CouchDBSyncerDocument *)document named:(NSString *)name;

// update methods
// used by couchdbsyncer
// get an update context for the given database and current thread
- (CouchDBSyncerUpdateContext *)updateContext:(CouchDBSyncerDatabase *)database;
- (void)update:(CouchDBSyncerUpdateContext *)context database:(CouchDBSyncerDatabase *)database;
- (void)update:(CouchDBSyncerUpdateContext *)context document:(CouchDBSyncerDocument *)document;
- (void)update:(CouchDBSyncerUpdateContext *)context attachment:(CouchDBSyncerAttachment *)attachment;

// returns a list of all stale attachments (need downloading)
- (NSArray *)staleAttachments:(CouchDBSyncerDatabase *)database;

@end
