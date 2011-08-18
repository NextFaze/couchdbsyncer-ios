//
//  TestAppDatabaseListViewController.h
//  CouchDBSyncer-iOS
//
//  Created by Andrew Williams on 18/08/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TestAppDatabaseListViewController : UITableViewController {
    NSArray *databases;
}

@property (nonatomic, retain) NSArray *databases;

@end
