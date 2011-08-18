//
//  MOCouchDBSyncerDocument.m
//  CouchDBSyncer-iOS
//
//  Created by Andrew Williams on 18/08/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import "MOCouchDBSyncerDocument.h"
#import "MOCouchDBSyncerAttachment.h"
#import "MOCouchDBSyncerDatabase.h"


@implementation MOCouchDBSyncerDocument
@dynamic revision;
@dynamic parentId;
@dynamic dictionaryData;
@dynamic type;
@dynamic documentId;
@dynamic tags;
@dynamic database;
@dynamic attachments;


- (void)addAttachmentsObject:(MOCouchDBSyncerAttachment *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"attachments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"attachments"] addObject:value];
    [self didChangeValueForKey:@"attachments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeAttachmentsObject:(MOCouchDBSyncerAttachment *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"attachments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"attachments"] removeObject:value];
    [self didChangeValueForKey:@"attachments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addAttachments:(NSSet *)value {    
    [self willChangeValueForKey:@"attachments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"attachments"] unionSet:value];
    [self didChangeValueForKey:@"attachments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeAttachments:(NSSet *)value {
    [self willChangeValueForKey:@"attachments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"attachments"] minusSet:value];
    [self didChangeValueForKey:@"attachments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


@end
