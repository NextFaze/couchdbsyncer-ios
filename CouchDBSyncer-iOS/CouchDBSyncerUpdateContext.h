//
//  CouchDBSyncerUpdateContext.h
//  CouchDBSyncer-iOS
//
//  Created by Andrew on 17/08/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MOCouchDBSyncerDatabase.h"
#import "CouchDBSyncerDatabase.h"

@interface CouchDBSyncerUpdateContext : NSObject {
    NSManagedObjectContext *managedObjectContext;
    MOCouchDBSyncerDatabase *moDatabase;
    CouchDBSyncerDatabase *database;
}

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) MOCouchDBSyncerDatabase *moDatabase;
@property (nonatomic, retain) CouchDBSyncerDatabase *database;

- (id)initWithContext:(NSManagedObjectContext *)context;

@end
