//
//  YozioTests.m
//  YozioTests
//
//  Created by Dounan Shi on 11/4/11.
//  Copyright (c) 2011 University of California at Berkeley. All rights reserved.
//

#import "Yozio.h"
#import "YozioTests.h"


@implementation YozioTests

- (void)setUp
{
  [super setUp];
  // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)test_startTimer_Entry
{
//  mock [NSDate date]
//  [Yozio startTimer:@"MyTimer"];
//  Yozio * instance = [Yozio getInstance];  
}

- (void)test_funnel_Entry
{
  [Yozio initialize];
  [Yozio funnel:@"Checkout" value:@"Start Checkout" category:@"MyCategory"];
  Yozio *instance = [Yozio getInstance];  
  NSLog(@"XXXX-instance:%@", instance);
  NSLog(@"XXXX:%@", [[instance dataQueue] class]);
  STAssertEquals([[[instance dataQueue] lastObject] valueForKey:@"type"], @"funnel", @"Wrong type");
}

- (void)test_revenue_Entry
{
//  STFail(@"Unit tests are not implemented yet in YozioTests");
}

- (void)test_action_Entry
{
//  STFail(@"Unit tests are not implemented yet in YozioTests");
}

- (void)test_error_Entry
{
//  STFail(@"Unit tests are not implemented yet in YozioTests");
}

- (void)test_collect_Entry
{
//  STFail(@"Unit tests are not implemented yet in YozioTests");
}

@end
