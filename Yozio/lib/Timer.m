#import "Timer.h"

@implementation Timer

- (id) init {
  self = [super init];
  if (self != nil) {
    startTime = nil;
    endTime = nil;
  }
  return self;
}

- (void)start {
  startTime = [NSDate date];
}

- (void)stop {
  endTime = [NSDate date];
}

- (double) timeElapsed {
  return [endTime timeIntervalSinceDate:startTime];
}

@end