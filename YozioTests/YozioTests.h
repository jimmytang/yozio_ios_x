//
//  YozioTests.h
//  YozioTests
//
// All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface YozioTests : SenTestCase

- (void)setMockDate:(NSDate *)aMockDate;
- (void)setMockUUID:(NSString *)uuid;
- (NSString*)formatTimeStampString:(NSDate *)date;
- (void)assertDataEqual:(NSMutableDictionary *)expected
                 actual:(NSMutableDictionary *)actual;

@end
