//
//  TestAppEditDatabaseViewController.m
//  CouchDBSyncer-iOS
//
//  Created by Andrew Williams on 18/08/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "TestAppEditDatabaseViewController.h"
#import "CouchDBSyncerStore.h"
#import "TestApplication.h"

@implementation TestAppEditDatabaseViewController

@synthesize tfUrl, tfName, buttonSave, database;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)deallocView {
    self.tfUrl = nil;
    self.tfName = nil;
    self.buttonSave = nil;
}

- (void)dealloc
{
    [self deallocView];
    [database release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if(database) {
        self.title = @"Edit Database";
        tfUrl.text = [database.url absoluteString];
        tfName.text = database.name;
    } else {
        self.title = @"New Database";
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [self deallocView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -

- (IBAction)buttonPressed:(id)sender {
    NSString *name = [tfName.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *urlString = [tfUrl.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL *url = [NSURL URLWithString:urlString];
    CouchDBSyncerStore *store = [[TestApplication sharedApplication] dataStore];
    
    if(sender == buttonSave) {
        if(database) {
            // update existing database
            database.name = name;
            database.url = url;
            
            CouchDBSyncerUpdateContext *context = [store updateContext:database];
            [store update:context database:database];
        }
        else {
            // create new database
            CouchDBSyncerDatabase *newdb = [store database:name url:url];
            LOG(@"new db: %@", newdb);
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end
