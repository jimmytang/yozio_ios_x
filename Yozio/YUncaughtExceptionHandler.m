//
//  UncaughtExceptionHandler.m
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

#import "YUncaughtExceptionHandler.h"
#import "Yozio_Private.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 7;

NSUncaughtExceptionHandler *_customExceptionHandler;

@implementation YUncaughtExceptionHandler

+ (NSArray *)backtrace
{
  void* callstack[128];
  int frames = backtrace(callstack, 128);
  char **strs = backtrace_symbols(callstack, frames);
  
  NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
  for (int i = UncaughtExceptionHandlerSkipAddressCount; i < frames; i++) {
    [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
  }
  free(strs);
  return backtrace;
}

- (void)handleException:(NSException *)exception
{
  if (_customExceptionHandler != nil) {
    _customExceptionHandler(exception);
  }
  [Yozio exception:exception];

	NSSetUncaughtExceptionHandler(NULL);
	signal(SIGABRT, SIG_DFL);
	signal(SIGILL, SIG_DFL);
	signal(SIGSEGV, SIG_DFL);
	signal(SIGFPE, SIG_DFL);
	signal(SIGBUS, SIG_DFL);
	signal(SIGPIPE, SIG_DFL);
  
  NSLog(@"*** Terminating app due to uncaught exception '%@', reason: '%@'\n"
         "*** Call stack at first throw:\n%@\n"
         "terminate called throwing an exception",
        [exception name], [exception reason],
        [[exception userInfo] valueForKey:YOZIO_UNCAUGHT_EXCEPTION_HANDLER_ADDRESSES_KEY]);
	
	if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName]) {
		kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
	} else {
		[exception raise];
	}
}

@end

void HandleException(NSException *exception)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum) {
		return;
	}
	
	NSArray *callStack = [YUncaughtExceptionHandler backtrace];
	NSMutableDictionary *userInfo =
		[NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
	[userInfo
		setObject:callStack
		forKey:YOZIO_UNCAUGHT_EXCEPTION_HANDLER_ADDRESSES_KEY];
	
	[[[[YUncaughtExceptionHandler alloc] init] autorelease]
		performSelectorOnMainThread:@selector(handleException:)
		withObject:
			[NSException
				exceptionWithName:[exception name]
				reason:[exception reason]
				userInfo:userInfo]
		waitUntilDone:YES];
}

void SignalHandler(int signal)
{
	int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
	if (exceptionCount > UncaughtExceptionMaximum) {
		return;
	}
	
	NSMutableDictionary *userInfo =
		[NSMutableDictionary
			dictionaryWithObject:[NSNumber numberWithInt:signal]
			forKey:UncaughtExceptionHandlerSignalKey];

	NSArray *callStack = [YUncaughtExceptionHandler backtrace];
	[userInfo
		setObject:callStack
		forKey:YOZIO_UNCAUGHT_EXCEPTION_HANDLER_ADDRESSES_KEY];
	
	[[[[YUncaughtExceptionHandler alloc] init] autorelease]
		performSelectorOnMainThread:@selector(handleException:)
		withObject:
			[NSException
				exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
				reason:
					[NSString stringWithFormat:
						NSLocalizedString(@"Signal %d was raised.", nil),
						signal]
				userInfo:
					[NSDictionary
						dictionaryWithObject:[NSNumber numberWithInt:signal]
						forKey:UncaughtExceptionHandlerSignalKey]]
		waitUntilDone:YES];
}

void InstallUncaughtExceptionHandler()
{
  _customExceptionHandler = nil;
	NSSetUncaughtExceptionHandler(&HandleException);
	signal(SIGABRT, SignalHandler);
	signal(SIGILL, SignalHandler);
	signal(SIGSEGV, SignalHandler);
	signal(SIGFPE, SignalHandler);
	signal(SIGBUS, SignalHandler);
	signal(SIGPIPE, SignalHandler);
}

void SetCustomExceptionHandler(NSUncaughtExceptionHandler *customExceptionHandler)
{
  _customExceptionHandler = customExceptionHandler;
}