//
//  TestApplication.h
//  CouchDBSyncer-iOS
//
//  Created by Andrew on 17/08/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CouchDBSyncerStore.h"

@interface TestApplication : UIApplication {
    CouchDBSyncerStore *dataStore;
}

@property (nonatomic, readonly) CouchDBSyncerStore *dataStore;

+ (TestApplication *)sharedApplication;

@end
