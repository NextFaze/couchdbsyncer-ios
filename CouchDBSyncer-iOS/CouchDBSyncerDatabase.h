//
//  CouchDBSyncerDatabase.h
//  CouchDBSyncer-iOS
//
//  Created by Andrew on 14/07/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CouchDBSyncerDatabase : NSObject {
    NSString *name;
    int sequenceId;
    NSURL *url;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, assign) int sequenceId;
@property (nonatomic, retain) NSURL *url;

@end
