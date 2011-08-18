//
//  CouchDBSyncerAttachment.m
//  CouchDBSyncer
//
//  Created by Andrew Williams on 26/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerAttachment.h"


@implementation CouchDBSyncerAttachment

@synthesize contentType, filename, length, revpos, deleted, documentId, content, stale;

- (void)dealloc {
    [contentType release];
    [filename release];
    [documentId release];
    [content release];
    
    [super dealloc];
}

#pragma mark -

- (NSString *)description {
    return [NSString stringWithFormat:@"%@/%@", documentId, filename];
}

@end
