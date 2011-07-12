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

@synthesize name, delegate, error, syncer, modelTypeKey;

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
    
    // fetch or create server record
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:name, @"NAME", nil];
    NSError *err = nil;
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"databaseByName" substitutionVariables:data];
    NSArray *databases = [managedObjectContext executeFetchRequest:fetch error:&err];
    db = databases.count ? [[databases objectAtIndex:0] retain] : nil;
    
    if(db == nil) {
        // add server record
        db = [[NSEntityDescription insertNewObjectForEntityForName:@"Database" inManagedObjectContext:managedObjectContext] retain];
        db.name = name;
        db.url = serverPath;
        db.sequenceId = 0;
        [self saveDatabase];
    }
    
    syncer.sequenceId = [db.sequenceId intValue];    
}

#pragma mark -

- (id)initWithName:(NSString *)n serverPath:(NSString *)url delegate:(id)d {
    if((self = [super init])) {
        name = [n retain];
        delegate = d;
        serverPath = [url retain];
        
        // initialise syncer 
        syncer = [[CouchDBSyncer alloc] initWithServerPath:url delegate:self];
        self.modelTypeKey = DefaultModelTypeKey;
        
        [self initDB];
    }
    
    return self;
}

- (void)dealloc {
    [name release];
    [serverPath release];
    [db release];
    [error release];
    [syncer release];
    [modelTypeKey release];
    
    [super dealloc];
}

#pragma mark Accessors

- (NSString *)serverPath {
    return serverPath;
}

- (void)setServerPath:(NSString *)s {
    if(s != serverPath) {
        [serverPath release];
        serverPath = [s retain];
        syncer.serverPath = s;
    }
}

#pragma mark -

// save database
- (BOOL)saveDatabase {
    NSError *err = nil;
    if (![managedObjectContext save:&err]) {
        LOG(@"error: %@, %@", err, [err userInfo]);
        [error release];
        error = [err retain];
        
        [syncer abort];
        [delegate couchDBSyncerStoreFailed:self];
    }
    return err ? NO : YES;
}

// save database and set sequence id
- (void)saveDatabase:(int)sequenceId {
    int origSequenceId = syncer.sequenceId;
    
    // attempt database save
    db.sequenceId = [NSNumber numberWithInt:sequenceId];
    syncer.sequenceId = sequenceId;
    if(![self saveDatabase]) {
        // save failed, revert to previous sequence id
        db.sequenceId = [NSNumber numberWithInt:origSequenceId];
        syncer.sequenceId = origSequenceId;
    }
}

- (void)reportError {
    [delegate performSelectorOnMainThread:@selector(couchDBSyncerStoreFailed:) withObject:self waitUntilDone:YES];
}

#pragma mark -

-(void)fetchChanges {
    [syncer fetchDatabaseInformation];  // detect if database has been deleted since last fetch - purge all local data in that case.
}

// purge this store
- (void)purge {
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(purge) withObject:nil waitUntilDone:YES];
        return;
    }
    LOG(@"purging content for %@", name);
    for(MOCouchDBSyncerDocument *doc in db.documents) {
        [managedObjectContext deleteObject:doc];
    }
    [self saveDatabase:0];
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
            db.sequenceId, @"sequenceId",
            [NSNumber numberWithInt:syncer.bytes], @"bytes transferred",
            [NSNumber numberWithInt:syncer.countHttpFin], @"HTTP requests",
            nil];
}

- (NSArray *)documents {
    return [db.documents allObjects];
}

- (NSArray *)documentsMatching:(NSPredicate *)predicate {	
    NSError *err = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Document" inManagedObjectContext:managedObjectContext]];
    [request setPredicate:predicate];
    NSArray *ret = [managedObjectContext executeFetchRequest:request error:&err];
    [request release];
    
    return ret;
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
    NSString *dbfile = [NSString stringWithFormat:@"%@.sqlite", name];
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent:dbfile]];	
    
    // handle db upgrade
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:storeUrl.path]) {
        // database doesn't exist.
        // inform delegate that the database is about to be created - it can install its own database here if required
        if([delegate respondsToSelector:@selector(couchDBSyncerStore:willReplaceDatabase:)])
            [delegate couchDBSyncerStore:self willReplaceDatabase:storeUrl.path];
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
 
            if(i == 0) {
                // give the delegate a chance to do something after the first failure
                if([delegate respondsToSelector:@selector(couchDBSyncerStore:willReplaceDatabase:)])
                    [delegate couchDBSyncerStore:self willReplaceDatabase:storeUrl.path];
            }
            else if(i == 2) {
                // unrecoverable error
                LOG(@"persistent store error: %@", err);
                [error release];
                error = [[CouchDBSyncerError errorWithCode:CouchDBSyncerErrorStore] retain];
                [self reportError];
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

/*
 - (void)mainThreadDatabaseMerge:(NSNotification*)notification {
 [managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
 }
 - (void)managedObjectContextChanges:(NSNotification*)notification {
 [self performSelectorOnMainThread:@selector(mainThreadDatabaseMerge:) withObject:notification waitUntilDone:YES];
 }
 */

// return the managed object document for the given document
- (MOCouchDBSyncerDocument *)managedObjectDocument:(CouchDBSyncerDocument *)doc {
    NSError *err = nil;
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:doc.documentId, @"DOCUMENT_ID", nil];
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"documentById" substitutionVariables:data];
    NSArray *documents = [managedObjectContext executeFetchRequest:fetch error:&err];
    return documents.count ? [documents objectAtIndex:0] : nil;	
}

// return the managed object attachment for the given attachment
- (MOCouchDBSyncerAttachment *)managedObjectAttachment:(CouchDBSyncerAttachment *)att {
    NSError *err = nil;
    NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:att.documentId, @"DOCUMENT_ID", att.filename, @"FILENAME", nil];
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"attachmentByDocumentIdAndFilename" substitutionVariables:data];
    NSArray *attachments = [managedObjectContext executeFetchRequest:fetch error:&err];
    return attachments.count ? [attachments objectAtIndex:0] : nil;	
}

- (CouchDBSyncerDocument *)documentFromManagedObject:(MOCouchDBSyncerDocument *)document {
    CouchDBSyncerDocument *doc = [[CouchDBSyncerDocument alloc] initWithDocumentId:document.documentId revision:document.revision sequenceId:0 deleted:NO];
    // doc.sequenceId
    // doc.attachments
    
    return [doc autorelease];
}

// return a CouchDBSyncerAttachment object corresponding to the managed object
// (used for re-downloading unfetched attachments)
- (CouchDBSyncerAttachment *)attachmentFromManagedObject:(MOCouchDBSyncerAttachment *)attachment {

    CouchDBSyncerAttachment *att = [[CouchDBSyncerAttachment alloc] init];
    CouchDBSyncerDocument *doc = [self documentFromManagedObject:attachment.document];
    
    att.filename = attachment.filename;
    att.contentType = attachment.contentType;
    att.documentId = attachment.documentId;
    att.length = [attachment.length intValue];
    att.revpos = [attachment.revpos intValue];
    att.deleted = NO;
    att.document = doc;

    // don't need the content as this object is only used for fetch requests currently
    //att.content = attachment.content;

    return [att autorelease];
}

// returns all MOCouchDBSyncerAttachment objects that haven't been fetched yet
- (NSArray *)unfetchedAttachments {
    NSFetchRequest *fetch = [managedObjectModel fetchRequestFromTemplateWithName:@"attachmentsUnfetched" substitutionVariables:[NSDictionary dictionary]];
    return [managedObjectContext executeFetchRequest:fetch error:nil];
}

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

#pragma mark CouchDBSyncerDelegate handlers (to be run on main thread)

- (void)syncerFoundDeletedDocument:(CouchDBSyncerDocument *)doc {
    LOG(@"removing document: %@ (seq %d)", doc, doc.sequenceId);
    
    // delete document & attachments
    MOCouchDBSyncerDocument *document = [self managedObjectDocument:doc];
    if(document) {
        [managedObjectContext deleteObject:document];
    }
    
    // save database (updates sequence id)
    [self saveDatabase:doc.sequenceId];
}

- (void)syncerDidFetchDocument:(CouchDBSyncerDocument *)doc {
    
    LOG(@"fetched document: %@ (seq %d)", doc, doc.sequenceId);
    
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
    [self downloadAttachments:[new allObjects]];
    
}

- (void)syncerDidFetchAttachment:(CouchDBSyncerAttachment *)att {
    LOG(@"fetched attachment: %@", att);
    
    MOCouchDBSyncerAttachment *attachment = [self managedObjectAttachment:att];
    if(attachment == nil) {
        // attachment record should be in the database (added by didFetchDocument)
        LOG(@"internal error: no attachment record found for %@", att);
        return;
    }
    
    attachment.content = att.content;
    attachment.length = [NSNumber numberWithInt:[att.content length]];
    attachment.unfetchedChanges = [NSNumber numberWithBool:NO];
    attachment.revpos = [NSNumber numberWithInt:att.revpos];
    
    // save database (doesn't update sequence)
    [self saveDatabase];
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

- (void)couchDBSyncerProgress:(CouchDBSyncer *)s {
    [delegate performSelectorOnMainThread:@selector(couchDBSyncerStoreProgress:) withObject:self waitUntilDone:YES];
}

- (void)couchDBSyncerCompleted:(CouchDBSyncer *)s {
    LOG(@"finished");
    [delegate performSelectorOnMainThread:@selector(couchDBSyncerStoreCompleted:) withObject:self waitUntilDone:YES];
}

@end
