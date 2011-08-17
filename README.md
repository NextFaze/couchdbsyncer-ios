CouchDBSyncer
=============

CouchDBSyncer - syncs couchdb databases from the server, saving data locally in a core data database.

External requirements:

* json-framework

Installation
------------

    > git clone git://github.com/2moro/couchdbsyncer.git
    > cd couchdbsyncer
    > git submodule init
    > git submodule update

CouchDBSyncer is a Cocoa Touch Static Library project, and can be incorporated into other xcode projects in the usual ways.

Usage
-----

CouchDBSyncerStore handles storage of data locally in a core data store.

Applications will typically create a single shared instance of CouchDBSyncerStore.

a CouchDBSyncer object is used to download changes from a remote CouchDB database to the local store. 
The Syncer uses the bulk document fetch API (http://wiki.apache.org/couchdb/HTTP_Bulk_Document_API) to fetch all changed documents in a single HTTP request.

If you want to limit the number of documents fetched by each HTTP request, you can set the docsPerReq property on your Syncer object (see section on Tunables below).
Attachments are fetched in separate HTTP requests.

    // create a local store object
    CouchDBSyncerStore *store = [[CouchDBSyncerStore alloc] init];

    // or, to use a shipped database as a starting point:
    CouchDBSyncerStore *store = [[CouchDBSyncerStore alloc] initWithShippedDatabase:@"shipped_db.sqlite"];

    // get the database DB_NAME.  updates the database url to the given DB_URL.
    // creates a new local database record if it has not been created yet.
    CouchDBSyncerDatabase *database = [store database:DB_NAME url:[NSURL urlWithString:DB_URL]];

    // create a syncer to fetch changes
    CouchDBSyncer *syncer = [[CouchDBSyncer alloc] initWithStore:store database:database];
    [syncer update];   // asynchronous call - creates an update thread

Sync Progress
-------------

CouchDBSyncer broadcasts progress notifications which you can listen to if required.
The notifications are:

* CouchDBSyncerProgressNotification - some progress has been made
* CouchDBSyncerCompleteNotification - sync has completed
* CouchDBSyncerErrorNotification - sync encountered an error

Database/Document/Attachment API
--------------------------------

the following attributes are saved separately as part of a document record, if available:

* type      (to change this, set the store.modelTypeKey tunable property)
* parent_id (accessible as "parentId" in the document record)

Download policies
-----------------

A variant of the update method of CouchDBSyncer accepts an object implementing the CouchDBSyncerDownloadPolicy protocol.
This can be used to download documents/attachments selectively, or with different priorities.

e.g.
    [syncer update:self];  // assumes self implements the CouchDBSyncerDownloadPolicy protocol

The default is to download all documents and attachments.  By default, documents are downloaded with priority NSOperationQueuePriorityNormal, and attachments
are downloaded with priority NSOperationQueuePriorityLow.
To change the download policy for a given document or attachment, the protocol method should modify the provided policy object.
For example, to only download attachments less than 1MB in size, and to download text attachments with high priority:

    - (void)couchDBSyncerStore:(CouchDBSyncerStore *)store attachment:(CouchDBSyncerAttachment *)att policy:(CouchDBSyncerStorePolicy *)policy {
        policy.download = att.length < (1024 * 1024) ? YES : NO;
        policy.priority = [att.contentType hasPrefix:@"text/"] ? NSOperationQueuePriorityHigh : NSOperationQueuePriorityLow;
    }

Metadata for attachments that are not downloaded is stored in the database, and is accessible via the attachments method of MOCouchDBSyncerDocument.
(This allows attachments to be accessed later if required).  If an attachment has newer content on the server, its unfetchedChanges attribute will be true.

Accessing databases / documents / attachments
---------------------------------------------

see CouchDBSyncerStore.h for public API methods.

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

    syncer.docsPerReq = 100;          // 0 (unlimited) by default, limit the number of documents per fetch request
    syncer.maxConcurrentFetches = 3;  // 3 by default, limit the number of maximum concurrent fetch requests
    
    store.modelTypeKey = @"type";     // "type" by default, the document field to store in the document.type attribute.

License
-------
Copyright 2011 2moro mobile
see also LICENSE.txt

