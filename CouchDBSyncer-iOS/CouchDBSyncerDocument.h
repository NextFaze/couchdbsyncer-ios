//
//  CouchDBSyncerDocument.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CouchDBSyncerObject.h"

@interface CouchDBSyncerDocument : CouchDBSyncerObject {
    int sequenceId;   // sequence id associated with changes list
    BOOL deleted;
    NSString *documentId, *parentId, *revision;
    NSArray *attachments;
}

@property (nonatomic, readonly) BOOL deleted;
@property (nonatomic, readonly) int sequenceId;
@property (nonatomic, retain) NSString *documentId, *parentId, *revision;
@property (nonatomic, readonly) NSArray *attachments;

- (id)initWithDocumentId:(NSString *)docid revision:(NSString *)rev sequenceId:(int)seq deleted:(BOOL)del;
- (void)setDictionary:(NSDictionary *)dict;
- (BOOL)isDesignDocument;

// data accessors
- (id)valueForKey:(NSString *)key;
- (NSString *)stringValueForKey:(NSString *)key;
- (NSNumber *)numberValueForKey:(NSString *)key;
- (int)intValueForKey:(NSString *)key;
- (float)floatValueForKey:(NSString *)key;

@end
