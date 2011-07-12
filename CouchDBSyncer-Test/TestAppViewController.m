    //
//  TestAppViewController.m
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "TestAppViewController.h"
#import "TestAppDocListViewController.h"

#define TestAppServerName @"ServerName"
#define TestAppDocsPerReq @"DocsPerReq"

@implementation TestAppViewController

@synthesize tfServer, tfDocsPerReq;
@synthesize buttonDocs, buttonReset, buttonSync, labelStatus, labelDocs, progressView1, progressView2, progressView3;

#pragma mark -

- (void)updateProgress {
	progressView1.progress = [store.syncer progressDocuments];
	progressView2.progress = [store.syncer progressAttachments];
	progressView3.progress = [store.syncer progress];
}

- (void)updateStats {
	NSDictionary *stats = [store statistics];
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
	if(sender == buttonDocs) {
        NSArray *documents = [store documents];
		TestAppDocListViewController *vc = [[TestAppDocListViewController alloc] initWithDocuments:documents];
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	}
	else if(sender == buttonReset) {
		[store purge];
		[self updateStats];
		[self setStatus:@"inactive"];
		progressView1.progress = progressView2.progress = progressView3.progress = 0;
	}
	else if(sender == buttonSync) {
		store.serverPath = tfServer.text;
		[self setStatus:@"syncing"];
		[store fetchChanges];
	}
}

#pragma mark -

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	tfServer.text = [[NSUserDefaults standardUserDefaults] valueForKey:TestAppServerName];
	tfDocsPerReq.text = [[NSUserDefaults standardUserDefaults] valueForKey:TestAppDocsPerReq];

	store = [[CouchDBSyncerStore alloc] initWithName:@"testapp" serverPath:tfServer.text delegate:self];
    store.syncer.docsPerRequest = [tfDocsPerReq.text intValue];

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
	
	[store release];
	store = nil;
}

- (void)dealloc {
	[tfServer release];
    [tfDocsPerReq release];
	[buttonDocs release];
	[buttonReset release];
	[buttonSync release];
	[labelStatus release];
	[labelDocs release];
	[progressView1 release];
	[progressView2 release];
	[progressView3 release];

	[store release];
    [super dealloc];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if(textField == tfServer) {
		// save value
		[[NSUserDefaults standardUserDefaults] setValue:tfServer.text forKey:TestAppServerName];
	}
    else if(textField == tfDocsPerReq) {
		[[NSUserDefaults standardUserDefaults] setValue:tfDocsPerReq.text forKey:TestAppDocsPerReq];        
        store.syncer.docsPerRequest = [tfDocsPerReq.text intValue];
    }
}

#pragma mark CouchDBSyncerStoreDelegate

- (void)couchDBSyncerStoreProgress:(CouchDBSyncerStore *)s {
	[self updateProgress];
	[self updateStats];
}

- (void)couchDBSyncerStoreCompleted:(CouchDBSyncerStore *)s {
	[self updateProgress];
	[self updateStats];
	[self setStatus:@"complete"];
    
    LOG(@"complete, progress: %.2f, %.2f, %.2f", [store.syncer progressDocuments], [store.syncer progressAttachments], [store.syncer progress]);
}

- (void)couchDBSyncerStoreFailed:(CouchDBSyncerStore *)s {
	[self updateProgress];
	[self updateStats];
	[self setStatus:@"failure"];
}

@end
