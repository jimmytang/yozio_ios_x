//
//  SafeMutableDictionary.m
//  Yozio
//
//  Created by Jimmy Tang on 9/26/12.
//  Copyright (c) 2012 University of California at Berkeley. All rights reserved.
//

#import "SafeMutableDictionary.h"

@implementation SafeMutableDictionary

- (id)init
{
  if (self = [super init]) {
    lock = [[NSLock alloc] init];
    underlyingDictionary = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void) dealloc
{
  [lock release];
  [underlyingDictionary release];
  [super dealloc];
}

// forward all the calls with the lock held
- (void)forwardInvocation:(NSInvocation *)anInvocation {
  
  [lock lock];
  @try {
    [anInvocation invoke];
  }
  @finally {
    [lock unlock];
  }
}

@end
