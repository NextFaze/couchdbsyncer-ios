//
//  CouchDBSyncerUpdateContext.m
//  CouchDBSyncer-iOS
//
//  Created by Andrew on 17/08/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerUpdateContext.h"


@implementation CouchDBSyncerUpdateContext

@synthesize managedObjectContext, database;

- (id)initWithContext:(NSManagedObjectContext *)context database:(CouchDBSyncerDatabase *)db {
    self = [super init];
    if(self) {
        managedObjectContext = [context retain];
        database = [db retain];
    }
    return self;
}

- (void)dealloc {
    [managedObjectContext release];
    [database release];
    [super dealloc];
}

@end
