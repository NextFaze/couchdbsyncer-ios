//
//  CouchDBSyncerError.h
//  CouchDBSyncer
//
//  Created by ASW on 8/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

#define CouchDBSyncerErrorDomain @"CouchDBSyncer"

typedef enum {
    CouchDBSyncerErrorStore,
    CouchDBSyncerErrorDBNotFound
} CouchDBSyncerErrorCode;

@interface CouchDBSyncerError : NSError {
    
}

+ (CouchDBSyncerError *)errorWithCode:(CouchDBSyncerErrorCode)code;

@end
