#import <Foundation/Foundation.h>

@interface Timer : NSObject {
  NSDate *startTime;
  NSDate *endTime;
}

- (void)start;
- (void)stop;
- (double)timeElapsed;

@end
