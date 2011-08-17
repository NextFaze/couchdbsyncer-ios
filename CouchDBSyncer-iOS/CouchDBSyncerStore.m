//
//  CouchDBSyncerStore.m
//  CouchDBSyncer
//
//  Created by ASW on 26/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerStore.h"
#import "CouchDBSyncerError.h"

#define DefaultModelTypeKey @"type"

@interface CouchDBSyncerStore(CouchDBSyncerStorePrivate)
- (NSManagedObjectContext *)managedObjectContext;
- (BOOL)saveDatabase;
@end


@implementation CouchDBSyncerStore

@synthesize error, modelTypeKey;

#pragma mark -

// initialise core data
- (void)initDB {
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(initDB) withObject:nil waitUntilDone:YES];
        return;
    }
    
    // set up core data
    [self managedObjectContext];
    if(managedObjectContext == nil) return;  // error with core data
}

#pragma mark -

- (id)initWithShippedDatabasePath:(NSString *)path {
    self = [super init];
    if(self) {
        self.modelTypeKey = DefaultModelTypeKey;
        shippedPath = [path retain];
        [self initDB];        
    }
    return self;
}

- (id)init {
    self = [self initWithShippedDatabasePath:nil];
    return self;
}

- (void)dealloc {
    [shippedPath release];
    [error release];
    [modelTypeKey release];
    
    [super dealloc];
}

#pragma mark Accessors


// save database
- (BOOL)saveDatabase {
    NSError *err = nil;
    if (![managedObjectContext save:&err]) {
        LOG(@"error: %@, %@", err, [err userInfo]);
        self.error = err;
    }
    return err ? NO : YES;
}

#pragma mark -
#pragma mark Conversion to/from managed objects

- (CouchDBSyncerDatabase *)databaseObject:(MOCouchDBSyncerDatabase *)moDatabase {
    CouchDBSyncerDatabase *database = [[[CouchDBSyncerDatabase alloc] init] autorelease];
    return database;
}

- (CouchDBSyncerDocument *)documentObject:(MOCouchDBSyncerDocument *)moDocument {
    CouchDBSyncerDocument *doc = [[CouchDBSyncerDocument alloc] initWithDocumentId:moDocument.documentId revision:moDocument.revision sequenceId:0 deleted:NO];
    return doc;
}

// return a CouchDBSyncerAttachment object corresponding to the managed object
// (used for re-downloading unfetched attachments)
- (CouchDBSyncerAttachment *)attachmentObject:(MOCouchDBSyncerAttachment *)attachment {
    
    CouchDBSyncerAttachment *att = [[[CouchDBSyncerAttachment alloc] init] autorelease];
    CouchDBSyncerDocument *doc = [self documentObject:attachment.document];
    
    att.filename = attachment.filename;
    att.contentType = attachment.contentType;
    att.documentId = attachment.documentId;
    att.length = [attachment.length intValue];
    att.revpos = [attachment.revpos intValue];
    att.deleted = NO;
    att.document = doc;
    
    // don't need the content as this object is only used for fetch requests currently
    //att.content = attachment.content;
    
    return att;
}

- (MOCouchDBSyncerDatabase *)moDatabaseObjectName:(NSString *)name {
    NSError *err = nil;
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:name, @"NAME", nil];
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"databaseByName" substitutionVariables:data];
    NSArray *databases = [managedObjectContext executeFetchRequest:fetch error:&err];
    MOCouchDBSyncerDatabase *db = databases.count ? [[databases objectAtIndex:0] retain] : nil;
    return db;
}

- (MOCouchDBSyncerDatabase *)moDatabaseObject:(CouchDBSyncerDatabase *)database {
    return [self moDatabaseObjectName:database.name];
}

// return the managed object document for the given document
- (MOCouchDBSyncerDocument *)moDocumentObject:(CouchDBSyncerDocument *)doc {
    NSError *err = nil;
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:doc.documentId, @"DOCUMENT_ID", nil];
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"documentById" substitutionVariables:data];
    NSArray *documents = [managedObjectContext executeFetchRequest:fetch error:&err];
    return documents.count ? [documents objectAtIndex:0] : nil;	
}

// return the managed object attachment for the given attachment
- (MOCouchDBSyncerAttachment *)moAttachmentObject:(CouchDBSyncerAttachment *)att {
    NSError *err = nil;
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:att.documentId, @"DOCUMENT_ID", att.filename, @"FILENAME", nil];
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"attachmentByDocumentIdAndFilename" substitutionVariables:data];
    NSArray *attachments = [managedObjectContext executeFetchRequest:fetch error:&err];
    return attachments.count ? [attachments objectAtIndex:0] : nil;	
}

#pragma mark -

// get database with the given name. if the database is not found locally, creates a new database with the 
// given name and url.
- (CouchDBSyncerDatabase *)database:(NSString *)name url:(NSURL *)url {
    // fetch or create database record
    MOCouchDBSyncerDatabase *db = [self moDatabaseObjectName:name];
    
    if(db == nil) {
        // add database record
        db = [NSEntityDescription insertNewObjectForEntityForName:@"Database" inManagedObjectContext:managedObjectContext];
        db.name = name;
        db.url = [url absoluteString];
        db.sequenceId = 0;

        [self saveDatabase];
    }
    
    return [self databaseObject:db];
}

// remove the specified database completely
- (void)destroy:(CouchDBSyncerDatabase *)database {
    MOCouchDBSyncerDatabase *moDatabase = [self moDatabaseObject:database];
    [managedObjectContext deleteObject:moDatabase];
}

// purge all data for the specified database
- (void)purge:(CouchDBSyncerDatabase *)database {
    MOCouchDBSyncerDatabase *moDatabase = [self moDatabaseObject:database];
    for(MOCouchDBSyncerDocument *moDocument in moDatabase.documents) {
        [managedObjectContext deleteObject:moDocument];
    }
    [self saveDatabase];
}

// purge this store
- (void)purge {
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(purge) withObject:nil waitUntilDone:YES];
        return;
    }
    LOG(@"purging all content");
    
    NSArray *databases = nil;  // TODO: select all databases
    
    for(MOCouchDBSyncerDatabase *moDatabase in databases) {
        [managedObjectContext deleteObject:moDatabase];
    }
    [self saveDatabase];
}

- (int)countForEntityName:(NSString *)entityName {
    NSError *err = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:managedObjectContext]];
    NSUInteger count = [managedObjectContext countForFetchRequest:request error:&err];	
    [request release];
    
    return count;	
}

- (NSDictionary *)statistics {
    int docs = [self countForEntityName:@"Document"];
    int attachments = [self countForEntityName:@"Attachment"];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:attachments], @"attachments",
            [NSNumber numberWithInt:docs], @"documents",
            nil];
}

- (NSArray *)documents:(CouchDBSyncerDatabase *)database {
    MOCouchDBSyncerDatabase *moDatabase = [self moDatabaseObject:database];
    NSMutableArray *documents = [NSMutableArray array];
    for(MOCouchDBSyncerDocument *moDocument in moDatabase.documents) {
        CouchDBSyncerDocument *document = [self documentObject:moDocument];
        [documents addObject:document];
    }
    return documents;
}

- (NSArray *)documentsMatching:(NSPredicate *)predicate {	
    NSError *err = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Document" inManagedObjectContext:managedObjectContext]];
    [request setPredicate:predicate];
    NSArray *moDocuments = [managedObjectContext executeFetchRequest:request error:&err];
    [request release];
    
    NSMutableArray *documents = [NSMutableArray array];
    for(MOCouchDBSyncerDocument *moDocument in moDocuments) {
        CouchDBSyncerDocument *document = [self documentObject:moDocument];
        [documents addObject:document];
    }
    
    return documents;
}

- (NSArray *)documentsOfType:(NSString *)type {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == $TYPE"];
    predicate = [predicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:type, @"TYPE", nil]];
    return [self documentsMatching:predicate];
}

- (NSArray *)documentsTagged:(NSString *)tag {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tags CONTAINS[c] $TAG", tag];
    predicate = [predicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:tag, @"TAG", nil]];
    return [self documentsMatching:predicate];
}

- (NSArray *)documentsOfType:(NSString *)type tagged:(NSString *)tag {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"type == $TYPE AND tags CONTAINS[c] $TAG", tag];
    predicate = [predicate predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:type, @"TYPE", tag, @"TAG", nil]];
    return [self documentsMatching:predicate];
}

#pragma mark -

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) return managedObjectModel;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"CouchDBSyncer" ofType:@"momd"];
    NSURL *momURL = [NSURL fileURLWithPath:path];
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    
    return managedObjectModel;
}

/**
 Returns the persistent store coordinator.
 If the coordinator doesn't already exist, it is created and the store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (persistentStoreCoordinator != nil) return persistentStoreCoordinator;
    
    NSError *err = nil;
    NSString *dbfile = [NSString stringWithFormat:@"couchdbsyncer.sqlite"];
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:dbfile]];	
    
    // handle db upgrade
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:storeUrl.path]) {
        // database doesn't exist.
        // install shipped database if provided
        if(shippedPath) {
            LOG(@"installing shipped database");
            [[NSFileManager defaultManager] copyItemAtPath:shippedPath toPath:storeUrl.path error:&err];
        }
    }
    
    // iteration 0: on failure, delete database, notify delegate  (delegate may install its own database here)
    // iteration 1: no options. on failure, delete database, do not notify delegate
    // iteration 2: failed to work with no database installed - abort
    for(int i = 0; i < 3; i++) {
        
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&err]) {
            LOG(@"persistent store error: %@, code = %d", err, [err code]);
        
            // delete the database and try again
            [[NSFileManager defaultManager] removeItemAtPath:storeUrl.path error:&err];

            options = nil;
 
            if(i == 0 && shippedPath) {
                // install shipped database
                LOG(@"installing shipped database");
                [[NSFileManager defaultManager] copyItemAtPath:shippedPath toPath:storeUrl.path error:&err];
            }
            else if(i == 2) {
                // unrecoverable error
                LOG(@"persistent store error: %@", err);
                self.error = [CouchDBSyncerError errorWithCode:CouchDBSyncerErrorStore];
                //[self reportError];
            }
        } else {
            // no error
            break;
        }
    }
    
    return persistentStoreCoordinator;
}

/**
 Returns the managed object context.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator.
 */
- (NSManagedObjectContext *)managedObjectContext {
    
    if (managedObjectContext != nil) return managedObjectContext;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setUndoManager:nil];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}

#pragma mark -

// returns all MOCouchDBSyncerAttachment objects that haven't been fetched yet
- (NSArray *)unfetchedAttachments {
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"attachmentsUnfetched" substitutionVariables:[NSDictionary dictionary]];
    return [managedObjectContext executeFetchRequest:fetch error:nil];
}

/*
// downloads the given attachment list
- (void)downloadAttachments:(NSArray *)attachments {
    CouchDBSyncerStorePolicy *policy = [[CouchDBSyncerStorePolicy alloc] init];
    for(CouchDBSyncerAttachment *att in attachments) {
        policy.download = YES;
        policy.priority = NSOperationQueuePriorityLow;
        if([delegate respondsToSelector:@selector(couchDBSyncerStore:attachment:policy:)])
            [delegate couchDBSyncerStore:self attachment:att policy:policy];
        
        if(policy.download)
            [syncer fetchAttachment:att priority:policy.priority];
    }
    [policy release];
}

 */

#pragma mark CouchDBSyncerDelegate handlers (to be run on main thread)

/*
- (void)syncerFoundDeletedDocument:(CouchDBSyncerDocument *)doc {

}

- (void)syncerDidFetchDatabaseInformation:(NSDictionary *)info {
    LOG(@"database info: %@", info);
    
    int docDelCount = [[info valueForKey:@"doc_del_count"] intValue];
    int docUpdateSeq = [[info valueForKey:@"doc_update_seq"] intValue];
    NSString *dbName = [info valueForKey:@"db_name"];
    
    if(docDelCount < [db.docDelCount intValue] || docUpdateSeq < [db.docUpdateSeq intValue]) {
        LOG(@"lower deletion or update sequence count on server - removing local store");
        [self purge];
    }
    else if(dbName && ![db.dbName isEqualToString:dbName]) {
        LOG(@"database name changed - removing local store");
        [self purge];
    }
    db.dbName = dbName;
    db.docDelCount = [NSNumber numberWithInt:docDelCount];
    db.docUpdateSeq = [NSNumber numberWithInt:docUpdateSeq];
    
    [self saveDatabase];  // save database without updating sequence
    
    // continue with sync
    [syncer fetchChanges];
}
 */

/*
#pragma mark CouchDBSyncerDelegate

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

- (void)couchDBSyncer:(CouchDBSyncer *)s didFindDeletedDocument:(CouchDBSyncerDocument *)doc {
    [self performSelectorOnMainThread:@selector(syncerFoundDeletedDocument:) withObject:doc waitUntilDone:YES];
}

- (void)couchDBSyncer:(CouchDBSyncer *)s didFetchDocument:(CouchDBSyncerDocument *)doc {
    [self performSelectorOnMainThread:@selector(syncerDidFetchDocument:) withObject:doc waitUntilDone:YES];
}

- (void)couchDBSyncer:(CouchDBSyncer *)s didFetchAttachment:(CouchDBSyncerAttachment *)att {
    [self performSelectorOnMainThread:@selector(syncerDidFetchAttachment:) withObject:att waitUntilDone:YES];
}

- (void)couchDBSyncer:(CouchDBSyncer *)s didFetchDatabaseInformation:(NSDictionary *)info {
    [self performSelectorOnMainThread:@selector(syncerDidFetchDatabaseInformation:) withObject:info waitUntilDone:YES];
}

- (void)couchDBSyncer:(CouchDBSyncer *)s didFailWithError:(NSError *)err {	
    LOG(@"error: %@", err);
    if(err != error) {
        [error release];
        error = [err retain];
    }
    [self reportError];
}

 */

#pragma mark -
#pragma mark Syncer support

// update methods
// used by couchdbsyncer
// get an update context for the given database and current thread
- (CouchDBSyncerUpdateContext *)updateContext:(CouchDBSyncerDatabase *)database {
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] init];
    [moc setPersistentStoreCoordinator:self.persistentStoreCoordinator];    
    CouchDBSyncerUpdateContext *context = [[[CouchDBSyncerUpdateContext alloc] initWithContext:moc database:database] autorelease];
    [moc release];
    
    return context;
}

- (void)update:(CouchDBSyncerUpdateContext *)context document:(CouchDBSyncerDocument *)document {
    MOCouchDBSyncerDatabase *moDatabase = context.moDatabase;
    
    LOG(@"document: %@ (seq %d)", doc, doc.sequenceId);
    
    if(document.deleted) {
        LOG(@"removing document: %@ (seq %d)", doc, doc.sequenceId);
        
        // delete document & attachments
        MOCouchDBSyncerDocument *document = [self managedObjectDocument:doc];
        if(document) {
            [managedObjectContext deleteObject:document];
        }
        
        // save database (updates sequence id)
        [self saveDatabase];
        return;
    }
    
    // save document
    // add/update server record
    MOCouchDBSyncerDocument *document = [self managedObjectDocument:doc];
    NSDictionary *dict = [doc dictionary];
    NSData *dictData = [NSKeyedArchiver archivedDataWithRootObject:dict];
    NSArray *tags = [dict valueForKey:@"tags"];
    
    if(document == nil) {
        // create new document
        document = [NSEntityDescription insertNewObjectForEntityForName:@"Document" inManagedObjectContext:managedObjectContext];
    }
    
    document.documentId = doc.documentId;
    document.revision = doc.revision;
    document.dictionaryData = dictData;
    document.type = [dict valueForKey:modelTypeKey];
    document.parentId = [dict valueForKey:@"parent_id"];
    document.tags = [tags isKindOfClass:[NSArray class]] ? [tags componentsJoinedByString:@","] : nil;
    document.database = db;
    
    NSMutableSet *old = [NSMutableSet setWithSet:document.attachments];
    NSMutableSet *new = [NSMutableSet set];
    
    for(CouchDBSyncerAttachment *att in doc.attachments) {
        MOCouchDBSyncerAttachment *attachment = [self managedObjectAttachment:att];
        BOOL is_new = NO;
        
        if(attachment == nil) {
            is_new = YES;
            attachment = [NSEntityDescription insertNewObjectForEntityForName:@"Attachment" inManagedObjectContext:managedObjectContext];   
        }
        else {
            [old removeObject:attachment];
        }
        
        if(is_new || ([attachment.revpos intValue] != att.revpos)) {
            // attachment not yet downloaded or revision has changed
            
            // update attachment attributes
            attachment.unfetchedChanges = [NSNumber numberWithBool:YES];
            attachment.filename = att.filename;
            attachment.contentType = att.contentType;
            attachment.documentId = att.documentId;
            attachment.document = document;
            attachment.revpos = [NSNumber numberWithInt:att.revpos];
            
            [new addObject:att];  // add to list to be downloaded
        }
    }
    
    // remove local attachments that are no longer attached to the document
    if([old count]) {
        LOG(@"removing %d old attachments", [old count]);
        for(MOCouchDBSyncerAttachment *moatt in [old allObjects]) {
            [managedObjectContext deleteObject:moatt];
        }
        [document removeAttachments:old];
    }
    
    // save database (updates sequence id)
    [self saveDatabase:doc.sequenceId];
    
    // download attachments. 
    // at this point attachment metadata should be saved in the database.
    LOG(@"new attachments: %d", [new count]);
    //[self downloadAttachments:[new allObjects]];

}

- (void)update:(CouchDBSyncerUpdateContext *)context attachment:(CouchDBSyncerAttachment *)attachment {
    LOG(@"attachment: %@", attachment);
    
    MOCouchDBSyncerAttachment *moAttachment = [self moAttachmentObject:attachment];
    if(moAttachment == nil) {
        // attachment record should be in the database (added by didFetchDocument)
        LOG(@"internal error: no attachment record found for %@", attachment);
        return;
    }
    
    moAttachment.content = attachment.content;
    moAttachment.length = [NSNumber numberWithInt:[attachment.content length]];
    moAttachment.unfetchedChanges = [NSNumber numberWithBool:NO];
    moAttachment.revpos = [NSNumber numberWithInt:attachment.revpos];
    
    // save database 
    [self saveDatabase];
}

@end
