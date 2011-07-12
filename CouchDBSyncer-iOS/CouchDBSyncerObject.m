//
//  CouchDBSyncerObject.m
//  CouchDBSyncer
//
//  Created by Andrew on 13/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerObject.h"


@implementation CouchDBSyncerObject

@synthesize dictionary;

- (id)initWithDictionary:(NSDictionary *)dict {
    if((self = [super init])) {
        dictionary = [dict retain];
    }
    return self;
}

- (void)dealloc {
    [dictionary release];
    [super dealloc];
}

@end
