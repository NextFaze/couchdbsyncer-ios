//
//  MOCouchDBSyncerAttachment.h
//  CouchDBSyncer
//
//  Created by Andrew on 19/03/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MOCouchDBSyncerDocument;

@interface MOCouchDBSyncerAttachment : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * revpos;
@property (nonatomic, retain) NSData * content;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSString * contentType;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * documentId;
@property (nonatomic, retain) NSNumber * unfetchedChanges;
@property (nonatomic, retain) MOCouchDBSyncerDocument * document;

@end
