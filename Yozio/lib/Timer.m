//
//  Timer.m
//  GrenadeGame
//
//  Created by Jimmy Tang on 10/2/11.
//  Copyright 2011 UC Berkeley. All rights reserved.
//

#import "Timer.h"

@implementation Timer

- (id) init {
  self = [super init];
  if (self != nil) {
    start = nil;
    end = nil;
  }
  return self;
}

- (void) startTimer {
  start = [NSDate date];
}

- (void) stopTimer {
  end = [NSDate date];
}

- (double) timeElapsedInSeconds {
  return [end timeIntervalSinceDate:start];
}

- (double) timeElapsedInMilliseconds {
  return [self timeElapsedInSeconds] * 1000.0f;
}

- (double) timeElapsedInMinutes {
  return [self timeElapsedInSeconds] / 60.0f;
}

@end