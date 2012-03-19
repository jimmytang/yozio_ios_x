//
//  YozioTests.m
//  YozioTests
//
//  Created by Dounan Shi on 11/4/11.
//  Copyright (c) 2011 University of California at Berkeley. All rights reserved.
//

#import "Yozio_Private.h"
#import "YozioTests.h"
#import "OCMock.h"
#import <objc/runtime.h>

@implementation YozioTests


static char mockDateKey;
static char mockUUID;
Method originalMethod = nil;
Method swizzleMethod = nil;

- (void)setUp
{
  [super setUp];
  
  // Start by having the mock return the test startup date
  [self setMockDate:[NSDate date]];
  
  // Save these as instance variables so test teardown can swap the implementation back
  originalMethod = class_getClassMethod([NSDate class], @selector(date));
  swizzleMethod = class_getInstanceMethod([self class], @selector(mockDateSwizzle));
  method_exchangeImplementations(originalMethod, swizzleMethod);       
  [Yozio configure:@"app key"
         secretKey:@"secret key"];
  [self setMockUUID:@"mock UUID"];
  id mock = [OCMockObject partialMockForObject:[Yozio getInstance]];
  [[[mock stub] andCall:@selector(mockUUID) onObject:mock] makeUUID];
}

- (void)tearDown
{ 
  // Revert the swizzle   
  method_exchangeImplementations(swizzleMethod, originalMethod);   
  [super tearDown];
}

// Mock Method, replaces [NSDate date]
- (NSDate *)mockDateSwizzle {    
  return objc_getAssociatedObject([NSDate class], &mockDateKey);
}

// Convenience method so tests can set want they want [NSDate date] to return
- (void)setMockDate:(NSDate *)aMockDate {
  objc_setAssociatedObject([NSDate class], &mockDateKey, aMockDate, OBJC_ASSOCIATION_RETAIN);    
}

- (void)setMockUUID:(NSString *)uuid {
  objc_setAssociatedObject([NSString class], &mockUUID, uuid, OBJC_ASSOCIATION_RETAIN);    
}


- (void)testTimerEntry
{
  NSDate* startDate = [NSDate date];
  [self setMockDate:startDate];
  [Yozio startTimer:@"MyTimer"];

  NSDate* endDate = [startDate dateByAddingTimeInterval:10];
  [self setMockDate:endDate];
  [Yozio stopTimer:@"MyTimer"];

  [Yozio log:@"1"];


  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   @"", @"av", 
                                   [NSNumber numberWithInteger:1], @"dc", 
                                   @"u", @"dot", 
                                   @"MyTimer", @"en", 
                                   @"", @"exp", 
                                   @"", @"rev", 
                                   @"", @"revc", 
                                   @"mock UUID", @"sid", 
                                   @"10.00", @"ti", 
                                   @"t", @"tp", 
                                   [self formatTimeStampString:startDate], @"ts", 
                                   @"", @"uid", 
                                   @"u", @"uot", 
                                   nil];
  [Yozio log:@"2"];

  NSMutableDictionary *actual = [[Yozio getInstance].dataQueue lastObject];
  
  NSLog(@"%@", actual);
  [self assertDataEqual:expected actual:actual];
}

- (NSString*)formatTimeStampString:(NSDate*)date
{
  NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  NSDateFormatter *tmpDateFormatter = [[NSDateFormatter alloc] init];
  [tmpDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss SSS"];
  [tmpDateFormatter setTimeZone:gmt];
  NSString *timeStamp = [tmpDateFormatter stringFromDate:[NSDate date]];
  [tmpDateFormatter release];
  return timeStamp;
}

//- (void)testRevenueEntry
//{
//  NSString *type = @"revenue";
//  NSString *itemName = @"PowerShield";
//  double cost = 20.5;
//  [Yozio revenue:itemName cost:cost];
//  Yozio *instance = [Yozio getInstance];  
//
//  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
//                                   type, @"type", 
//                                   key, @"revenue", 
//                                   nil];
//  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
//  [self assertDataEqual:expected actual:actual];  
//}
//
//- (void)testActionEntry
//{
//  NSString *type = @"action";
//  NSString *key = @"jump";
//  NSString *value = @"Level 1";
//  [Yozio action:key];
//  Yozio *instance = [Yozio getInstance];  
//  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
//                                   type, @"type", 
//                                   value, @"key", 
//                                   key, @"value", 
//                                   nil];
//  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
//  [self assertDataEqual:expected actual:actual];
//}
//
//- (void)testErrorEntry
//{
//  NSString *type = @"error";
//  NSString *key = @"Save Error";
//  NSString *value = @"error message";
//  [Yozio error:key];
//  Yozio *instance = [Yozio getInstance];  
//  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
//                                   type, @"type", 
//                                   key, @"key", 
//                                   value, @"value", 
//                                   nil];
//  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
//  [self assertDataEqual:expected actual:actual];
//}
//
//- (void)testCollectEntry
//{
//  NSString *type = @"misc";
//  NSString *key = @"SomeEvent";
//  NSString *value = @"SomeValue";
//  [Yozio collect:key value:value];
//  Yozio *instance = [Yozio getInstance];  
//  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
//                                   type, @"type", 
//                                   key, @"key", 
//                                   value, @"value", 
//                                   nil];
//  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
//  [self assertDataEqual:expected actual:actual];
//}

// Test Helper Methods

- (void)assertDataEqual:(NSMutableDictionary *)expected
                 actual:(NSMutableDictionary *)actual
{
  STAssertEqualObjects([expected valueForKey:@"av"], [actual valueForKey:@"av"], @"Wrong App Version");
  STAssertEqualObjects([expected valueForKey:@"dc"], [actual valueForKey:@"dc"], @"Wrong Data Count");
  STAssertEqualObjects([expected valueForKey:@"dot"], [actual valueForKey:@"dot"], @"Wrong Device Orientation");
  STAssertEqualObjects([expected valueForKey:@"en"], [actual valueForKey:@"en"], @"Wrong Event Name");
  STAssertEqualObjects([expected valueForKey:@"exp"], [actual valueForKey:@"exp"], @"Wrong Experiment");
  STAssertEqualObjects([expected valueForKey:@"rev"], [actual valueForKey:@"rev"], @"Wrong Revenue");
  STAssertEqualObjects([expected valueForKey:@"revc"], [actual valueForKey:@"revc"], @"Wrong Revenue Currency");
  STAssertEqualObjects([expected valueForKey:@"sid"], [actual valueForKey:@"sid"], @"Wrong Session ID");
  STAssertEqualObjects([expected valueForKey:@"ti"], [actual valueForKey:@"ti"], @"Wrong Time Interval");
  STAssertEqualObjects([expected valueForKey:@"tp"], [actual valueForKey:@"tp"], @"Wrong type");
  STAssertEqualObjects([expected valueForKey:@"ts"], [actual valueForKey:@"ts"], @"Wrong Time Stamp");
  STAssertEqualObjects([expected valueForKey:@"uid"], [actual valueForKey:@"uid"], @"Wrong User ID");
  STAssertEqualObjects([expected valueForKey:@"uot"], [actual valueForKey:@"uot"], @"Wrong User Device Orientation");
}

@end
