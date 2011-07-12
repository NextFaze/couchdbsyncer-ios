//
//  MOCouchDBSyncerDocument.h
//  CouchDBSyncer
//
//  Created by ASW on 27/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MOCouchDBSyncerAttachment;
@class MOCouchDBSyncerDatabase;

@interface MOCouchDBSyncerDocument :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * revision;
@property (nonatomic, retain) NSData * dictionaryData;
@property (nonatomic, retain) NSString * parentId;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * documentId;
@property (nonatomic, retain) MOCouchDBSyncerDatabase * database;
@property (nonatomic, retain) NSSet* attachments;

- (NSDictionary *)dictionary;
- (BOOL)isDesignDocument;

@end


@interface MOCouchDBSyncerDocument (CoreDataGeneratedAccessors)

- (void)addAttachmentsObject:(MOCouchDBSyncerAttachment *)value;
- (void)removeAttachmentsObject:(MOCouchDBSyncerAttachment *)value;
- (void)addAttachments:(NSSet *)value;
- (void)removeAttachments:(NSSet *)value;

@end

