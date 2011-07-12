CouchDBSyncer
=============

CouchDBSyncer - syncs couchdb databases from the server, optionally saving data locally in a core data database.

External requirements:

* json-framework

Installation
------------

    > git clone git://github.com/2moro/couchdbsyncer.git
    > cd couchdbsyncer
    > git submodule init
    > git submodule update
  
Drag the "CouchDBSyncer" group into your xcode project (or add the Source/CouchDBSyncer directory to your project).
You will also need to add json-framework/Classes if you don't already have the json-framework in your project.

Usage
-----

CouchDBSyncerStore implements the CouchDBSyncerDelegate protocol and handles storage of data in a core data store.
(this is used by the example app TestApp).

The fetchChanges method of CouchDBSyncerStore fetches all changed documents in a bulk fetch operation. 
If you want to limit the number of documents fetched by each HTTP request, you can set the docsPerReq property on store.syncer (see section on Tunables below).
Attachments are fetched in separate HTTP requests.

    CouchDBSyncerStore *store = [[CouchDBSyncerStore alloc] initWithName:@"Store" serverPath:@"http://example.com:5984/dbname" delegate:self];
    [store fetchChanges];
    
    #pragma mark CouchDBSyncerStoreDelegate
    
    // called whenever some progress has been made.
    // check [store.syncer progress], [store.syncer progressDocuments], [store.syncer progressAttachments]
    - (void)couchDBSyncerStoreProgress:(CouchDBSyncerStore *)store {}

    // called when all downloads have completed.
    - (void)couchDBSyncerStoreCompleted:(CouchDBSyncerStore *)store {}

    // called when errors occur. check store.error for the error
    - (void)couchDBSyncerStoreFailed:(CouchDBSyncerStore *)store {}

the following attributes are saved separately as part of a document record, if available:

* type      (to change this, set the store.modelTypeKey tunable property)
* parent_id (accessible as "parentId" in the document record)

Download policies
-----------------

The following optional methods of CouchDBSyncerStoreDelegate can be used to download documents/attachments selectively, or with different priorities.

    - (void)couchDBSyncerStore:(CouchDBSyncerStore *)store document:(CouchDBSyncerDocument *)doc policy:(CouchDBSyncerStorePolicy *)policy {}
    - (void)couchDBSyncerStore:(CouchDBSyncerStore *)store attachment:(CouchDBSyncerAttachment *)att policy:(CouchDBSyncerStorePolicy *)policy {}

The default is to download all documents and attachments.  By default, documents are downloaded with priority NSOperationQueuePriorityNormal, and attachments
are downloaded with priority NSOperationQueuePriorityLow.
To change the download policy for a given document or attachment, the delegate method should modify the provided policy object.
For example, to only download attachments less than 1MB in size, and to download text attachments with high priority:

    - (void)couchDBSyncerStore:(CouchDBSyncerStore *)store attachment:(CouchDBSyncerAttachment *)att policy:(CouchDBSyncerStorePolicy *)policy {
        policy.download = att.length < (1024 * 1024) ? YES : NO;
        policy.priority = [att.contentType hasPrefix:@"text/"] ? NSOperationQueuePriorityHigh : NSOperationQueuePriorityLow;
    }

Metadata for attachments that are not downloaded is stored in the database, and is accessible via the attachments method of MOCouchDBSyncerDocument.
(This allows attachments to be accessed later if required).  If an attachment has newer content on the server, its unfetchedChanges attribute will be true.

Accessing documents / attachments
---------------------------------

documents can be accessed using the following methods of CouchDBSyncerStore.

    - (NSArray *)documents;
    - (NSArray *)documentsOfType:(NSString *)type;
    - (NSArray *)documentsMatching:(NSPredicate *)predicate;

The above methods return arrays of MOCouchDBSyncerDocument objects.  The dictionary method of MOCouchDBSyncerDocument can be used to access the 
document contents as an NSDictionary (converted from JSON).
The attachments method of MOCouchDBSyncerDocument returns an NSArray of attachments (MOCouchDBSyncerAttachment records) associated with the document.

Tunables
--------

Tunable properties:

    CouchDBSyncerStore *store = [[CouchDBSyncerStore alloc] initWithName:@"Store" serverPath:@"http://example.com:5984/dbname" delegate:self];

    store.syncer.docsPerReq = 100;          // 0 (unlimited) by default, limit the number of documents per fetch request
    store.syncer.maxConcurrentFetches = 3;  // 3 by default, limit the number of maximum concurrent fetch requests
    store.modelTypeKey = @"type";            // "type" by default, the document field to store in the document.type attribute.

