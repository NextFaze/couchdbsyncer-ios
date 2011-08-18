//
//  TestAppDocViewController.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CouchDBSyncerDocument.h"

@interface TestAppDocViewController : UIViewController {
	CouchDBSyncerDocument *document;
	UIScrollView *scrollView;
	UILabel *labelContent;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UILabel *labelContent;
@property (nonatomic, retain) CouchDBSyncerDocument *document;

- (id)initWithDocument:(CouchDBSyncerDocument *)doc;

@end
