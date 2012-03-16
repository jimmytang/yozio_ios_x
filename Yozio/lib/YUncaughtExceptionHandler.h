//
//  UncaughtExceptionHandler.h
//  UncaughtExceptions
//
//  Created by Matt Gallagher on 2010/05/25.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#if !defined(__YOZIO_UNCAUGHT_EXCEPTION_HANDLER__)
#define __YOZIO_UNCAUGHT_EXCEPTION_HANDLER__ 1

#import <UIKit/UIKit.h>

#define YOZIO_UNCAUGHT_EXCEPTION_HANDLER_ADDRESSES_KEY @"UncaughtExceptionHandlerAddressesKey"

@interface YUncaughtExceptionHandler : NSObject {}
@end

/**
 * Call this method to set everything up.
 */
void InstallUncaughtExceptionHandler();

/**
 * Set a custom exception handler.
 */
void SetCustomExceptionHandler(NSUncaughtExceptionHandler *customExceptionHandler);

/**
 * Private handler methods.
 */
void HandleException(NSException *exception);
void SignalHandler(int signal);

#endif /* ! __YOZIO_UNCAUGHT_EXCEPTION_HANDLER__ */