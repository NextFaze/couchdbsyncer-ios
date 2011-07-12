//
//  MOCouchDBSyncerDatabase.h
//  CouchDBSyncer
//
//  Created by ASW on 8/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MOCouchDBSyncerDocument;

@interface MOCouchDBSyncerDatabase :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * dbName;
@property (nonatomic, retain) NSNumber * sequenceId;
@property (nonatomic, retain) NSNumber * docDelCount;
@property (nonatomic, retain) NSNumber * docUpdateSeq;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSSet* documents;

@end


@interface MOCouchDBSyncerDatabase (CoreDataGeneratedAccessors)
- (void)addDocumentsObject:(MOCouchDBSyncerDocument *)value;
- (void)removeDocumentsObject:(MOCouchDBSyncerDocument *)value;
- (void)addDocuments:(NSSet *)value;
- (void)removeDocuments:(NSSet *)value;

@end

