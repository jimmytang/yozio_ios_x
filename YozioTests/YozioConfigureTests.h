//
//  YozioTests.h
//  YozioTests
//
// All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface YozioConfigureTests : SenTestCase

- (void)setMockDate:(NSDate *)aMockDate;
- (void)setMockEventID:(NSString *)uuid;
@end
