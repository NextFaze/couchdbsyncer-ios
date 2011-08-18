//
//  MOCouchDBSyncerAttachment.h
//  CouchDBSyncer-iOS
//
//  Created by Andrew Williams on 18/08/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MOCouchDBSyncerDatabase, MOCouchDBSyncerDocument;

@interface MOCouchDBSyncerAttachment : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * revpos;
@property (nonatomic, retain) NSData * content;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * contentType;
@property (nonatomic, retain) NSNumber * stale;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * documentId;
@property (nonatomic, retain) MOCouchDBSyncerDocument * document;
@property (nonatomic, retain) MOCouchDBSyncerDatabase * database;

@end
