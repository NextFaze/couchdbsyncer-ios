//
//  TestAppViewController.h
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CouchDBSyncerStore.h"

@interface TestAppViewController : UIViewController <CouchDBSyncerStoreDelegate, UITextFieldDelegate> {
	CouchDBSyncerStore *store;
	
	UITextField *tfServer, *tfDocsPerReq;
	UIButton *buttonSync, *buttonReset, *buttonDocs;
	UILabel *labelStatus, *labelDocs;
	UIProgressView *progressView1, *progressView2, *progressView3;
}

@property (nonatomic, retain) IBOutlet UILabel *labelStatus, *labelDocs;
@property (nonatomic, retain) IBOutlet UIButton *buttonSync, *buttonReset, *buttonDocs;
@property (nonatomic, retain) IBOutlet UITextField *tfServer, *tfDocsPerReq;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView1, *progressView2, *progressView3;

- (IBAction)buttonPressed:(id)sender;

@end
