/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */

#import "YNSTimer+Blocks.h"

@implementation NSTimer (Blocks)

+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats
{
  void (^block)() = [inBlock copy];
  id ret = [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(jdExecuteSimpleBlock:) userInfo:block repeats:inRepeats];
  [block release];
  return ret;
}

+(id)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats
{
  void (^block)() = [inBlock copy];
  id ret = [self timerWithTimeInterval:inTimeInterval target:self selector:@selector(jdExecuteSimpleBlock:) userInfo:block repeats:inRepeats];
  [block release];
  return ret;
}

+(void)jdExecuteSimpleBlock:(NSTimer *)inTimer;
{
  if([inTimer userInfo])
  {
    void (^block)() = (void (^)())[inTimer userInfo];
    block();
  }
}

@end
