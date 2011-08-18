//
//  CouchDBSyncerBulkFetch.m
//  CouchDBSyncer
//
//  Created by Andrew on 13/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//
// curl -d '{"keys":["bar","baz"]}' -X POST http://127.0.0.1:5984/foo/_all_docs?include_docs=true

#import "CouchDBSyncerBulkFetch.h"
#import "NSObject+SBJson.h"

@interface CouchDBSyncerFetch (CouchDBSyncerPrivate)
- (void)finish;
@end

@implementation CouchDBSyncerBulkFetch

@synthesize documents;

- (id)initWithURL:(NSURL *)u delegate:(NSObject <CouchDBSyncerFetchDelegate> *)d {
    NSString *urlPath = [NSString stringWithFormat:@"%@/_all_docs?include_docs=true", u];
    if((self = [super initWithURL:[NSURL URLWithString:urlPath] delegate:d])) {
        fetchType = CouchDBSyncerFetchTypeBulkDocuments;
        documents = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [documents release];
    
    [super dealloc];
}

#pragma mark -

- (void)setFetchType:(CouchDBSyncerFetchType)ft {
    // do nothing (fetch type is fixed to bulk)
}

- (NSString *)httpBody {
    NSMutableArray *keys = [NSMutableArray array];
    for(CouchDBSyncerDocument *doc in documents) {
        [keys addObject:doc.documentId];
    }
    NSDictionary *req = [NSDictionary dictionaryWithObjectsAndKeys:keys, @"keys", nil];
    return [req JSONRepresentation];
}

- (NSMutableURLRequest *)urlRequest {
    NSMutableURLRequest *req = [super urlRequest];
    
    NSString *body = [self httpBody];
    if(body) {
        [req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        [req setHTTPMethod:@"POST"];
        [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    
    return req;
}

#pragma mark -

- (void)addDocument:(CouchDBSyncerDocument *)doc {
    [documents addObject:doc];
}

- (int)documentCount {
    return [documents count];
}

#pragma mark Private methods

// update the content of the documents from the fetched data
- (void)updateContent {
    NSDictionary *dict = [self dictionary];
    NSArray *rows = [dict valueForKey:@"rows"];
    NSMutableDictionary *docById = [NSMutableDictionary dictionary];
    
    for(NSDictionary *row in rows) {
        NSDictionary *doc = [row valueForKey:@"doc"];
        NSString *documentId = [row valueForKey:@"id"];        
        [docById setValue:doc forKey:documentId];
    }
    
    // update document content
    for(CouchDBSyncerDocument *doc in documents) {
        doc.dictionary = [docById valueForKey:doc.documentId];
    }
}

- (void)finish {
    // populate content in documents
    [self updateContent];
    
    // call superclass method to finish connection
    [super finish];
}

@end
