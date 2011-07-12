//
//  TestAppDocViewController.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MOCouchDBSyncerDocument.h"


@interface TestAppDocViewController : UIViewController {
	MOCouchDBSyncerDocument *document;
	UIScrollView *scrollView;
	UILabel *labelContent;
}

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UILabel *labelContent;

- (id)initWithDocument:(MOCouchDBSyncerDocument *)doc;

@end
