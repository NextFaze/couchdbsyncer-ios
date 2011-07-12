//
//  CouchDBSyncerError.m
//  CouchDBSyncer
//
//  Created by ASW on 8/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import "CouchDBSyncerError.h"


@implementation CouchDBSyncerError

+ (NSString *)descriptionForCode:(CouchDBSyncerErrorCode)code {
    NSString *desc = nil;
    
    switch (code) {
        case CouchDBSyncerErrorStore:
            desc = @"unable to initialise persistent store";
            break;
        default:
            desc = @"An error occurred";
            break;
    }
    return desc;
}

+ (CouchDBSyncerError *)errorWithCode:(CouchDBSyncerErrorCode)code  {
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              [self descriptionForCode:code], NSLocalizedDescriptionKey,
                              nil];
    CouchDBSyncerError *err = [NSError errorWithDomain:CouchDBSyncerErrorDomain code:code userInfo:userInfo];
    return err;
}

@end
