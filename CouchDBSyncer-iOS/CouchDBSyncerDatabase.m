//
//  CouchDBSyncerDatabase.m
//  CouchDBSyncer-iOS
//
//  Created by Andrew on 14/07/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerDatabase.h"


@implementation CouchDBSyncerDatabase

@synthesize name, url, sequenceId;

- (void)dealloc {
    [name release];
    [url release];
    [super dealloc];
}

@end
