//
//  CouchDBSyncerAttachment.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 26/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CouchDBSyncerObject.h"
#import "CouchDBSyncerDocument.h"

@interface CouchDBSyncerAttachment : CouchDBSyncerObject {
    NSString *contentType, *filename, *documentId;
    int length, revpos;
    BOOL deleted, stale;
    NSData *content;
}

@property (nonatomic, retain) NSString *contentType, *filename, *documentId;
@property (nonatomic, assign) int length, revpos;
@property (nonatomic, assign) BOOL deleted, stale;
@property (nonatomic, retain) NSData *content;

@end
