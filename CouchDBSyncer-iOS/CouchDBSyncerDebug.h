//
//  Debugging.h
//
//  Created by Andrew Williams on 14/09/10.
//  Copyright 2010 2moro mobile. All rights reserved.
//

// "DEBUG=1" needs to be added to the "Preprocessor Macros" for the Debug configuration

#ifndef LOG
#ifdef DEBUG
#define LOG(format, ...) NSLog(@"%s:%@", __PRETTY_FUNCTION__,[NSString stringWithFormat:format, ## __VA_ARGS__])
#else
#define LOG(format, ...)
#endif
#endif
