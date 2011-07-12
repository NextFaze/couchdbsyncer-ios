//
//  CouchDBSyncerBulkFetch.h
//  CouchDBSyncer
//
//  Created by Andrew on 13/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CouchDBSyncerFetch.h"
#import "CouchDBSyncerDocument.h"

@interface CouchDBSyncerBulkFetch : CouchDBSyncerFetch {
}

- (id)initWithServerPath:(NSString *)path delegate:(id<CouchDBSyncerFetchDelegate>)d;

- (void)addDocument:(CouchDBSyncerDocument *)doc;
- (int)documentCount;

@end
