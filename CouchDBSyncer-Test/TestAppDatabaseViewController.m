    //
//  TestAppViewController.m
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "TestAppDatabaseViewController.h"
#import "TestAppDocListViewController.h"
#import "TestAppEditDatabaseViewController.h"
#import "TestApplication.h"

#define TestAppServerName @"ServerName"
#define TestAppDocsPerReq @"DocsPerReq"

@implementation TestAppDatabaseViewController

@synthesize tfDocsPerReq;
@synthesize buttonDocs, buttonReset, buttonSync, labelStatus, labelDocs, progressView1, progressView2, progressView3;
@synthesize database;

- (CouchDBSyncerStore *)store {
    return [[TestApplication sharedApplication] dataStore];
}

#pragma mark -

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}

- (id)initWithDatabase:(CouchDBSyncerDatabase *)db {
    self = [self initWithNibName:@"TestAppDatabaseViewController" bundle:nil];
    if(self) {
        self.database = db;
        syncer = [[CouchDBSyncer alloc] initWithStore:[self store] database:db];
        syncer.delegate = self;
    }
    return self;
}

- (void)deallocView {
    self.buttonDocs = nil;
    self.buttonReset = nil;
    self.buttonSync = nil;
    self.labelStatus = nil;
    self.labelDocs = nil;
    self.progressView1 = nil;
    self.progressView2 = nil;
    self.progressView3 = nil;
    self.tfDocsPerReq = nil;
}

- (void)dealloc {
    [self deallocView];
    [syncer abort];
    [syncer release];
    [database release];
    
    [super dealloc];
}

#pragma mark -

- (void)updateProgress {
	progressView1.progress = [syncer progressDocuments];
	progressView2.progress = [syncer progressAttachments];
	progressView3.progress = [syncer progress];
}

- (void)updateStats {
	NSDictionary *stats = [[self store] statistics:database];
	NSMutableString *str = [NSMutableString string];
	for(NSString *key in [stats allKeys]) {
		[str appendFormat:@"%@: %@\n", key, [stats valueForKey:key]];
	}
	labelDocs.text = str;
	//[labelDocs sizeToFit];
}

- (void)setStatus:(NSString *)status {
	labelStatus.text = [NSString stringWithFormat:@"status: %@", status];
}

- (IBAction)buttonPressed:(id)sender {
    CouchDBSyncerStore *store = [self store];
	if(sender == buttonDocs) {
        NSArray *docs = [store documents:database];
		TestAppDocListViewController *vc = [[TestAppDocListViewController alloc] initWithDocuments:docs];
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	}
	else if(sender == buttonReset) {
		[[self store] purge:database];
		[self updateStats];
		[self setStatus:@"inactive"];
		progressView1.progress = progressView2.progress = progressView3.progress = 0;
	}
	else if(sender == buttonSync) {
		[self setStatus:@"syncing"];
        [syncer update];
	}
}

#pragma mark -

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	tfDocsPerReq.text = [[NSUserDefaults standardUserDefaults] valueForKey:TestAppDocsPerReq];

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editDatabase:)];
    self.navigationItem.rightBarButtonItem = item;
    [item release];
     
    self.title = database.name;
    
	[self updateProgress];
	[self updateStats];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	[self deallocView];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(textField == tfDocsPerReq) {
		[[NSUserDefaults standardUserDefaults] setValue:tfDocsPerReq.text forKey:TestAppDocsPerReq];        
        syncer.docsPerRequest = [tfDocsPerReq.text intValue];
    }
}

#pragma mark CouchDBSyncerDelegate

- (void)couchDBSyncerProgress:(CouchDBSyncer *)s {
	[self updateProgress];
	[self updateStats];
}

- (void)couchDBSyncerCompleted:(CouchDBSyncer *)s {
	[self updateProgress];
	[self updateStats];
	[self setStatus:@"complete"];
    
    LOG(@"complete, progress: %.2f, %.2f, %.2f",
        [syncer progressDocuments], [syncer progressAttachments], [syncer progress]);
}

- (void)couchDBSyncerFailed:(CouchDBSyncer *)s {
	[self updateProgress];
	[self updateStats];
	[self setStatus:@"failure"];
}

#pragma mark -

- (void)editDatabase:(id)sender {
    TestAppEditDatabaseViewController *vc = [[TestAppEditDatabaseViewController alloc] init];
    vc.database = database;
    [self.navigationController pushViewController:vc animated:YES];
    [vc release];
}

@end
