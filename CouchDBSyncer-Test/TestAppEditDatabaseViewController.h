//
//  TestAppEditDatabaseViewController.h
//  CouchDBSyncer-iOS
//
//  Created by Andrew Williams on 18/08/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CouchDBSyncerDatabase.h"

@interface TestAppEditDatabaseViewController : UIViewController <UITextFieldDelegate> {
    CouchDBSyncerDatabase *database;
    
    @private
    UITextField *tfName, *tfUrl;
    UIButton *buttonSave;
}

@property (nonatomic, retain) CouchDBSyncerDatabase *database;
@property (nonatomic, retain) IBOutlet UITextField *tfName, *tfUrl;
@property (nonatomic, retain) IBOutlet UIButton *buttonSave;

- (IBAction)buttonPressed:(id)sender;

@end
