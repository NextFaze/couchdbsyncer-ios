//
//  CouchDBSyncerFetch.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CouchDBSyncerResponse.h"

typedef enum {
    CouchDBSyncerFetchTypeUnknown,
    CouchDBSyncerFetchTypeDBInfo,          // serverPath
    CouchDBSyncerFetchTypeChanges,         // serverPath/_changes
    CouchDBSyncerFetchTypeDocument,        // serverPath/$_id
    CouchDBSyncerFetchTypeBulkDocuments,   // serverPath/_all_docs?include_docs=true
    CouchDBSyncerFetchTypeAttachment       // serverPath/$_id/attachment
} CouchDBSyncerFetchType;

@protocol CouchDBSyncerFetchDelegate;

@interface CouchDBSyncerFetch : NSOperation {
    NSError *error;
    NSMutableData *data;
    NSURL *url;
    NSURLConnection *conn;
    BOOL isExecuting, isFinished;
    NSString *username, *password;
    CouchDBSyncerFetchType fetchType;
    
    CouchDBSyncerResponse *response;
    
    id<CouchDBSyncerFetchDelegate> delegate;
}

@property (nonatomic, assign) CouchDBSyncerFetchType fetchType;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, readonly) BOOL isExecuting, isFinished;
@property (nonatomic, retain) CouchDBSyncerResponse *response;
@property (nonatomic, retain) NSString *username, *password;

- (id)initWithURL:(NSURL *)u delegate:(id<CouchDBSyncerFetchDelegate>)d;

- (void)fetch;
- (NSData *)data;
- (NSDictionary *)dictionary;
- (NSString *)string;
- (NSMutableURLRequest *)urlRequest;

@end

@protocol CouchDBSyncerFetchDelegate

- (void)couchDBSyncerFetchCompleted:(CouchDBSyncerFetch *)fetcher;

@end
