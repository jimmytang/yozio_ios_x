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
  [Yozio configure:@"app key"
            userId:@"MyUserId"
               env:@"production"
        appVersion:@"1.0.1"
    campaignSource:@"google"
    campaignMedium:@"cpc"
      campaignTerm:@"twitter bird jump"
   campaignContent:@"content"
      campaignName:@"12873"
  exceptionHandler:NULL];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testTimerEntry
{
  //TODO add test for timeer here
//  mock [NSDate date]
//  [Yozio startTimer:@"MyTimer"];
//  Yozio * instance = [Yozio getInstance];  
}

- (void)testRevenueEntry
{
  NSString *type = @"revenue";
  NSString *itemName = @"PowerShield";
  double cost = 20.5;
  [Yozio revenue:itemName cost:cost];
  Yozio *instance = [Yozio getInstance];  

  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   type, @"type", 
                                   key, @"revenue", 
                                   nil];
  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
  [self assertDataEqual:expected actual:actual];  
}

- (void)testActionEntry
{
  NSString *type = @"action";
  NSString *key = @"jump";
  NSString *value = @"Level 1";
  [Yozio action:key];
  Yozio *instance = [Yozio getInstance];  
  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   type, @"type", 
                                   value, @"key", 
                                   key, @"value", 
                                   nil];
  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
  [self assertDataEqual:expected actual:actual];
}

- (void)testErrorEntry
{
  NSString *type = @"error";
  NSString *key = @"Save Error";
  NSString *value = @"error message";
  [Yozio error:key];
  Yozio *instance = [Yozio getInstance];  
  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   type, @"type", 
                                   key, @"key", 
                                   value, @"value", 
                                   nil];
  NSMutableDictionary *actual = [[instance dataQueue] lastObject];
  [self assertDataEqual:expected actual:actual];
}

- (void)testCollectEntry
{
  NSString *type = @"misc";
  NSString *key = @"SomeEvent";
  NSString *value = @"SomeValue";
  [Yozio collect:key value:value];
  Yozio *instance = [Yozio getInstance];  
  NSMutableDictionary *expected = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                                   type, @"type", 
                                   key, @"key", 
                                   value, @"value", 
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
}

@end
