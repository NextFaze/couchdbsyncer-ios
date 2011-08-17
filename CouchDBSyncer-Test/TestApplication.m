//
//  TestApplication.m
//  CouchDBSyncer-iOS
//
//  Created by Andrew on 17/08/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "TestApplication.h"


@implementation TestApplication

@synthesize dataStore;

- (id)init {
    self = [super init];
    if(self) {
        dataStore = [[CouchDBSyncerStore alloc] init];
    }
    return self;
}

- (void)dealloc {
    [dataStore release];
    [super dealloc];
}

@end
