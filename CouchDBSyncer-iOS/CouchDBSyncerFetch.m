//
//  CouchDBSyncerFetch.m
//  CouchDBSyncer
//
//  Created by Andrew Williams on 25/02/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerFetch.h"
#import "NSObject+SBJson.h"
#import "NSDataAdditions.h"
#import "CouchDBSyncerError.h"

#define CouchDBSyncerFetchTimeout 20  // seconds

@implementation CouchDBSyncerFetch

@synthesize url, error, isExecuting, isFinished, username, password, fetchType, document, attachment;

#pragma mark Private

- (void)finishConnection {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    conn = nil;	
    isExecuting = NO;
    isFinished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)finish {
    // call delegate before finishConnection or we might get freed before the delegate can access our data (?)
    [delegate couchDBSyncerFetchCompleted:self];
    [self finishConnection];
}

- (NSString *)httpBody {
    return nil;
}

#pragma mark -

- (id)init {
    if((self = [super init])) {
        data = [[NSMutableData alloc] init];
        fetchType = CouchDBSyncerFetchTypeUnknown;
    }
    return self;
}

- (id)initWithURL:(NSURL *)u delegate:(NSObject<CouchDBSyncerFetchDelegate> *)d {
    if((self = [self init])) {
        self.url = u;
        delegate = d;
        
        // extract username/password from url if supplied
        self.username = u.user;
        self.password = u.password;
        
        LOG(@"url: %@, username: %@, password: %@", self.url, self.username, self.password);
    }
    return self;
}

- (void)dealloc {
    delegate = nil;
    [document release];
    [attachment release];
    [url release];
    [data release];
    [error release];
    [username release];
    [password release];
    
    [super dealloc];
}

#pragma mark -

- (NSMutableURLRequest *)urlRequest {
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:CouchDBSyncerFetchTimeout];
    
    // add http auth string
    if(username && password) {
        NSString *authString = [NSString stringWithFormat:@"%@:%@", username, password];
        LOG(@"using credentials: %@", authString);
        NSString *authString64 = [[authString dataUsingEncoding:NSUTF8StringEncoding] encodeToBase64];
        [req addValue:[NSString stringWithFormat:@"Basic %@", authString64] forHTTPHeaderField:@"Authorization"]; 
    }
    
    return req;
}

#pragma mark -

- (void)fetch {
    if(conn) {
        LOG(@"fetch already in progress, returning");
        return;
    }
    [data setLength:0];
    self.error = nil;
    
    NSMutableURLRequest *req = [self urlRequest];
    conn = [NSURLConnection alloc];
    [conn initWithRequest:req delegate:self startImmediately:NO];
    [conn scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    LOG(@"fetching URL: %@", url);
    [conn start];
    [conn release];
}

- (NSData *)data {
    return data;
}

// return data as json string
- (NSString *)string {
    return [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
}

// decode the received data as JSON and parse into a dictionary
- (NSDictionary *)dictionary {
    LOG(@"string: %@", [self string]);
    return [[self string] JSONValue];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
    if(err.code == -1200) return;  // SSL error - seems to work anyway
    self.error = err;
    LOG(@"error: %@", err);
    [self finish];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //LOG(@"connection finished loading");
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)res {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)res;
    if ([res respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *dictionary = [httpResponse allHeaderFields];
        int code = [httpResponse statusCode];
        LOG(@"response code: %d, content length: %@", code, [dictionary valueForKey:@"Content-Length"]);
        
        if(code == 404) {
            // db missing?
            self.error = (NSError *)[CouchDBSyncerError errorWithCode:CouchDBSyncerErrorDBNotFound];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)d {
    //LOG(@"received data");
    if([self isCancelled]) {
        [connection cancel];
        // no call to delegate here
        [self finishConnection];
        return;
    }
    [data appendData:d];
}


- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    LOG(@"auth challenge: %@", challenge);
    
    if ([challenge previousFailureCount] > 0) {
        // handle bad credentials here
        LOG(@"failure count: %d", [challenge previousFailureCount]);
        [[challenge sender] cancelAuthenticationChallenge:challenge];
        return;
    }
    
    if ([[challenge protectionSpace] authenticationMethod] == NSURLAuthenticationMethodServerTrust) {
        // makes connection work with ssl self signed certificates
        LOG(@"certificate challenge");
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];	
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return YES;
}

- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    // TODO: set error here?
    [self finish];
}

#pragma mark NSOperation methods

- (void)start {
    isExecuting = YES;
    [self fetch];
}
- (BOOL)isConcurrent {
    return YES;
}

@end
