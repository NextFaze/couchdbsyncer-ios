//
//  CouchDBSyncerStorePolicy.h
//  CouchDBSyncer
//
//  Created by Andrew on 15/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CouchDBSyncerStorePolicy : NSObject {
    BOOL download;
    NSOperationQueuePriority priority;
}

@property (nonatomic, assign) BOOL download;
@property (nonatomic, assign) NSOperationQueuePriority priority;

@end
