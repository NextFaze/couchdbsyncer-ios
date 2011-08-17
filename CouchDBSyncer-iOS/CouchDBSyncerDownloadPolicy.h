//
//  CouchDBSyncerDownloadPolicy.h
//  CouchDBSyncer
//
//  Created by Andrew on 15/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CouchDBSyncerDocument.h"
#import "CouchDBSyncerAttachment.h"

@protocol CouchDBSyncerDownloadPolicy <NSObject>

@optional
- (BOOL)couchDBSyncerDownloadPolicyDocument:(CouchDBSyncerDocument *)document;
- (BOOL)couchDBSyncerDownloadPolicyAttachment:(CouchDBSyncerAttachment *)attachment;
- (NSOperationQueuePriority)couchDBSyncerDownloadPolicyDocumentPriority:(CouchDBSyncerDocument *)document;
- (NSOperationQueuePriority)couchDBSyncerDownloadPolicyAttachmentPriority:(CouchDBSyncerDocument *)document;

@end
