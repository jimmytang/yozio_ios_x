//
//  Timer.h
//  GrenadeGame
//
//  Created by Jimmy Tang on 10/2/11.
//  Copyright 2011 UC Berkeley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Timer : NSObject {
  NSDate *start;
  NSDate *end;
}

- (void) startTimer;
- (void) stopTimer;
- (double) timeElapsedInSeconds;
- (double) timeElapsedInMilliseconds;
- (double) timeElapsedInMinutes;

@end
