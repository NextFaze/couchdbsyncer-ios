//
//  CouchDBSyncerResponse.h
//  CouchDBSyncer
//
//  Created by ASW on 27/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CouchDBSyncerDocument.h"
#import "CouchDBSyncerAttachment.h"
#import "CouchDBSyncerDelegate.h"

@protocol CouchDBSyncerResponseDelegate;

@interface CouchDBSyncerResponse : NSOperation {
    //NSString *dbInfo;
    BOOL isExecuting, isFinished, fetched;
    id<CouchDBSyncerResponseDelegate> delegate;
    CouchDBSyncer *syncer;
    NSMutableArray *objects;
}

@property (nonatomic, readonly) BOOL isExecuting, isFinished;
@property (nonatomic, assign) id<CouchDBSyncerResponseDelegate> delegate;
@property (nonatomic, readonly) NSMutableArray *objects;

- (void)markCompleted;
- (void)addObject:(CouchDBSyncerObject *)obj;

@end

@protocol CouchDBSyncerResponseDelegate
- (void)couchDBSyncerResponseComplete:(CouchDBSyncerResponse *)r;
@end
