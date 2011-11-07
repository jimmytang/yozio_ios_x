//
//  YozioTests.m
//  YozioTests
//
//  Created by Dounan Shi on 11/4/11.
//  Copyright (c) 2011 University of California at Berkeley. All rights reserved.
//

#import "Yozio_Private.h"
#import "YozioTests.h"


@implementation YozioTests

- (void)setUp
{
  [super setUp];
  [Yozio configure:@"http://m.snapette.yozio.com"
            userId:@"MyUserId"
               env:@"production"
        appVersion:@"1.0.1"];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testStartTimerEntry
{
//  mock [NSDate date]
//  [Yozio startTimer:@"MyTimer"];
//  Yozio * instance = [Yozio getInstance];  
}

- (void)testFunnelEntry
{
  NSString *type = @"funnel";
  NSString *key = @"Checkout";
  NSString *value = @"Start Checkout";
  NSString *category = @"MyCategory";
  [Yozio funnel:key value:value category:category];
  Yozio *instance = [Yozio getInstance];  
  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                           type, @"type", 
                           key, @"key", 
                           value, @"value", 
                           category, @"category", 
                           nil];
  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
  [self assertDataEqual:expected actual:actual];
}
- (void)testRevenueEntry
{
  NSString *type = @"revenue";
  NSString *key = @"PowerShield";
  double value = 20.5;
  NSString *category = @"Defence";
  [Yozio revenue:key cost:value category:category];
  Yozio *instance = [Yozio getInstance];  
  NSString *stringValue = [NSString stringWithFormat:@"%d", value];
  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   type, @"type", 
                                   key, @"key", 
                                   stringValue, @"value", 
                                   category, @"category", 
                                   nil];
  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
  [self assertDataEqual:expected actual:actual];  
}

- (void)testActionEntry
{
  NSString *type = @"action";
  NSString *key = @"jump";
  NSString *value = @"Level 1";
  NSString *category = @"play";
  [Yozio action:key context:value category:category];
  Yozio *instance = [Yozio getInstance];  
  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   type, @"type", 
                                   value, @"key", 
                                   key, @"value", 
                                   category, @"category", 
                                   nil];
  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
  [self assertDataEqual:expected actual:actual];
}

- (void)testErrorEntry
{
  NSString *type = @"error";
  NSString *key = @"Save Error";
  NSString *value = @"error message";
  NSString *category = @"persistence";
  [Yozio error:key message:value category:category];
  Yozio *instance = [Yozio getInstance];  
  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   type, @"type", 
                                   key, @"key", 
                                   value, @"value", 
                                   category, @"category", 
                                   nil];
  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
  [self assertDataEqual:expected actual:actual];
}

- (void)testCollectEntry
{
  NSString *type = @"misc";
  NSString *key = @"SomeEvent";
  NSString *value = @"SomeValue";
  NSString *category = @"MyCategory";
  [Yozio collect:key value:value category:category];
  Yozio *instance = [Yozio getInstance];  
  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   type, @"type", 
                                   key, @"key", 
                                   value, @"value", 
                                   category, @"category", 
                                   nil];
  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
  [self assertDataEqual:expected actual:actual];
}

// Test Helper Methods

- (void)assertDataEqual:(NSMutableDictionary *)expected
                 actual:(NSMutableDictionary *)actual
{
  NSLog(@"expected: %@", expected);
  NSLog(@"actual: %@", actual);
  STAssertEqualObjects([expected valueForKey:@"type"], [actual valueForKey:@"type"], @"Wrong type");
  STAssertEqualObjects([expected valueForKey:@"key"], [actual valueForKey:@"key"], @"Wrong key");
  STAssertEqualObjects([expected valueForKey:@"value"], [actual valueForKey:@"value"], @"Wrong value");
  STAssertEqualObjects([expected valueForKey:@"category"], [actual valueForKey:@"category"], @"Wrong category");
}

@end
