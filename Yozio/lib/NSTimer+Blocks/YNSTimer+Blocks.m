//
//  NSTimer+Blocks.m
//  Yozio
//
//  Created by Jimmy Tang on 9/26/12.
//  Copyright (c) 2012 University of California at Berkeley. All rights reserved.
//

#import "NSTimer+Blocks.h"

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
