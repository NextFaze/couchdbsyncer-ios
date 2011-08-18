//
//  MOCouchDBSyncerDatabase.h
//  CouchDBSyncer-iOS
//
//  Created by Andrew Williams on 18/08/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MOCouchDBSyncerAttachment, MOCouchDBSyncerDocument;

@interface MOCouchDBSyncerDatabase : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * dbName;
@property (nonatomic, retain) NSNumber * docUpdateSeq;
@property (nonatomic, retain) NSNumber * sequenceId;
@property (nonatomic, retain) NSNumber * docDelCount;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet* documents;
@property (nonatomic, retain) NSSet* attachments;

@end
