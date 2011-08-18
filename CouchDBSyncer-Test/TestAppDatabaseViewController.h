//
//  TestAppViewController.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CouchDBSyncer.h"
#import "CouchDBSyncerStore.h"
#import "CouchDBSyncerDatabase.h"

@interface TestAppDatabaseViewController : UIViewController <UITextFieldDelegate, CouchDBSyncerDelegate> {	
	UITextField *tfDocsPerReq;
	UIButton *buttonSync, *buttonReset, *buttonDocs;
	UILabel *labelStatus, *labelDocs;
	UIProgressView *progressView1, *progressView2, *progressView3;

    CouchDBSyncer *syncer;
    CouchDBSyncerDatabase *database;
}

@property (nonatomic, retain) CouchDBSyncerDatabase *database;

@property (nonatomic, retain) IBOutlet UILabel *labelStatus, *labelDocs;
@property (nonatomic, retain) IBOutlet UIButton *buttonSync, *buttonReset, *buttonDocs;
@property (nonatomic, retain) IBOutlet UITextField *tfDocsPerReq;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView1, *progressView2, *progressView3;

- (id)initWithDatabase:(CouchDBSyncerDatabase *)database;
- (IBAction)buttonPressed:(id)sender;

@end
