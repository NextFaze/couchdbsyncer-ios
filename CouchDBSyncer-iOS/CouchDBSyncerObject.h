//
//  CouchDBSyncerObject.h
//  CouchDBSyncer
//
//  Created by Andrew on 13/03/11.
//  Copyright 2011 2moro mobile. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CouchDBSyncerObject : NSObject {
    NSDictionary *dictionary;
}

@property (nonatomic, readonly) NSDictionary *dictionary;

- (id)initWithDictionary:(NSDictionary *)dict;

@end
