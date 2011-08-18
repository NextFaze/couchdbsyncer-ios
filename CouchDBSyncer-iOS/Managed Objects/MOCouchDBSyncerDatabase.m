//
//  MOCouchDBSyncerDatabase.m
//  CouchDBSyncer-iOS
//
//  Created by Andrew Williams on 18/08/11.
//  Copyright (c) 2011 2moro mobile. All rights reserved.
//

#import "MOCouchDBSyncerDatabase.h"
#import "MOCouchDBSyncerAttachment.h"
#import "MOCouchDBSyncerDocument.h"


@implementation MOCouchDBSyncerDatabase
@dynamic dbName;
@dynamic docUpdateSeq;
@dynamic sequenceId;
@dynamic docDelCount;
@dynamic name;
@dynamic url;
@dynamic documents;
@dynamic attachments;

- (void)addDocumentsObject:(MOCouchDBSyncerDocument *)value {    
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"documents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"documents"] addObject:value];
    [self didChangeValueForKey:@"documents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeDocumentsObject:(MOCouchDBSyncerDocument *)value {
    NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value count:1];
    [self willChangeValueForKey:@"documents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"documents"] removeObject:value];
    [self didChangeValueForKey:@"documents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)addDocuments:(NSSet *)value {    
    [self willChangeValueForKey:@"documents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"documents"] unionSet:value];
    [self didChangeValueForKey:@"documents" withSetMutation:NSKeyValueUnionSetMutation usingObjects:value];
}

- (void)removeDocuments:(NSSet *)value {
    [self willChangeValueForKey:@"documents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
    [[self primitiveValueForKey:@"documents"] minusSet:value];
    [self didChangeValueForKey:@"documents" withSetMutation:NSKeyValueMinusSetMutation usingObjects:value];
}


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
