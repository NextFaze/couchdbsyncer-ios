//
//  MOCouchDBSyncerDocument.h
//  CouchDBSyncer-iOS
//
//  Created by Andrew Williams on 18/08/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MOCouchDBSyncerAttachment, MOCouchDBSyncerDatabase;

@interface MOCouchDBSyncerDocument : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * revision;
@property (nonatomic, retain) NSString * parentId;
@property (nonatomic, retain) NSData * dictionaryData;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * documentId;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) MOCouchDBSyncerDatabase * database;
@property (nonatomic, retain) NSSet* attachments;

@end
