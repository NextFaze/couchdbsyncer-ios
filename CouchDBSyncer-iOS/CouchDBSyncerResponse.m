//
//  CouchDBSyncerResponse.m
//  CouchDBSyncer
//
//  Created by ASW on 27/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerResponse.h"


@implementation CouchDBSyncerResponse

@synthesize isExecuting, isFinished, delegate, objects;

// returns true if all requests are for deleted documents
- (BOOL)allDocumentsDeleted {
    
    // if no objects, return false
    // (e.g. for fetching database information)
    if([objects count] == 0) return NO;
    
    for(CouchDBSyncerObject *obj in objects) {
        if([obj isKindOfClass:[CouchDBSyncerDocument class]]) {
            CouchDBSyncerDocument *doc = (CouchDBSyncerDocument *)obj;
            if(!doc.deleted)
                return NO;
        }
        else {
            // fetching attachments / other objects
            return NO;
        }
    }
    // if we get here, all objects in the fetch list are deleted (or there are no objects)
    return YES;
}

#pragma mark -

- (id)init {
    if((self = [super init])) {
        objects = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [objects release];
    objects = nil;
    [super dealloc];
}

#pragma mark -

- (void)addObject:(CouchDBSyncerObject *)obj {
    [objects addObject:obj];
}

- (void)markCompleted {
    @synchronized(self) {
        if(isFinished) return;  // already marked completed
        
        LOG(@"marking completed");
        fetched = YES;
        [delegate couchDBSyncerResponseComplete:self];
        
        [self willChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        isExecuting = NO;
        isFinished = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
    }
}

#pragma mark NSOperation methods

- (void)start {
    isExecuting = YES;
    
    if(fetched || [self allDocumentsDeleted]) {
        // completed
        [self markCompleted];
    }
}

- (BOOL)isConcurrent {
    return YES;
}

@end
