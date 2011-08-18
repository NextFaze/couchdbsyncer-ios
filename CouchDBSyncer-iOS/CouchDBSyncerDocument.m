//
//  CouchDBSyncerDocument.m
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerDocument.h"
#import "CouchDBSyncerAttachment.h"
#import "NSObject+SBJson.h"

@implementation CouchDBSyncerDocument

@synthesize deleted, documentId, revision, sequenceId, attachments;

#pragma mark -

- (id)initWithDocumentId:(NSString *)docid revision:(NSString *)rev sequenceId:(int)seq deleted:(BOOL)del {
    if((self = [super init])) {
        deleted = del;
        sequenceId = seq;
        documentId = [docid retain];
        revision = [rev retain];
    }
    return self;
}

- (void)dealloc {
    [documentId release];
    [revision release];
    [attachments release];
    
    [super dealloc];
}

#pragma mark -

- (BOOL)isDesignDocument {
    return [self.documentId hasPrefix:@"_design/"];
}

- (NSString *)description {
    return documentId;
}

- (id)valueForKey:(NSString *)key {
    return [dictionary valueForKey:key];
}
- (NSString *)stringValueForKey:(NSString *)key {
    return [NSString stringWithFormat:@"%@", [dictionary valueForKey:key]];
}

- (NSNumber *)numberValueForKey:(NSString *)key {
    id val = [self valueForKey:key];
    if([val isKindOfClass:[NSNumber class]]) {
        return val;
    } else {
        return nil;
    }
}

- (int)intValueForKey:(NSString *)key {
    return [[self stringValueForKey:key] intValue];
}

- (float)floatValueForKey:(NSString *)key {
    return [[self stringValueForKey:key] floatValue];
}

#pragma mark -

- (void)setDictionary:(NSDictionary *)dict {
    if(dict == dictionary) return;
    
    NSDictionary *oldDict = dictionary;
    dictionary = [dict retain];
    [oldDict release];
    
    NSDictionary *attlist = [dictionary valueForKey:@"_attachments"];
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    for(NSString *fname in [attlist allKeys]) {
        CouchDBSyncerAttachment *a = [[CouchDBSyncerAttachment alloc] init];
        NSDictionary *attdata = [attlist valueForKey:fname];
        a.filename = fname;
        a.contentType = [attdata valueForKey:@"content_type"];
        a.length = [[attdata valueForKey:@"length"] intValue];
        a.revpos = [[attdata valueForKey:@"revpos"] intValue];
        a.documentId = documentId;
        a.deleted = deleted;
        [list addObject:a];
        [a release];
    }
    [attachments release];
    attachments = list;
}

@end
