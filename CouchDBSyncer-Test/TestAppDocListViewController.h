//
//  TestAppDocListViewController.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TestAppDocListViewController : UITableViewController {
	NSArray *documents;
}

- (id)initWithDocuments:(NSArray *)docs;

@end
