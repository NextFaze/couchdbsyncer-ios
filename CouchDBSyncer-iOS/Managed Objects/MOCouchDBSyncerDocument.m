// 
//  MOCouchDBSyncerDocument.m
//  CouchDBSyncer
//
//  Created by ASW on 27/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "MOCouchDBSyncerDocument.h"

#import "MOCouchDBSyncerAttachment.h"
#import "MOCouchDBSyncerDatabase.h"

@implementation MOCouchDBSyncerDocument 

@dynamic revision;
@dynamic dictionaryData;
@dynamic parentId;
@dynamic type;
@dynamic tags;
@dynamic documentId;
@dynamic database;
@dynamic attachments;

- (NSDictionary *)dictionary {
	return [NSKeyedUnarchiver unarchiveObjectWithData:self.dictionaryData];
}

- (BOOL)isDesignDocument {
    return [self.documentId hasPrefix:@"_design/"];
}

@end
