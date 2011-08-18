//
//  CouchDBSyncerUpdateContext.m
//  CouchDBSyncer-iOS
//
//  Created by Andrew on 17/08/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerUpdateContext.h"


@implementation CouchDBSyncerUpdateContext

@synthesize managedObjectContext, database, moDatabase;

- (id)initWithContext:(NSManagedObjectContext *)context {
    self = [super init];
    if(self) {
        managedObjectContext = [context retain];
    }
    return self;
}

- (void)dealloc {
    [managedObjectContext release];
    [moDatabase release];
    [database release];
    
    [super dealloc];
}

@end
