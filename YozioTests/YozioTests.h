//
//  YozioTests.h
//  YozioTests
//
//  Created by Dounan Shi on 11/4/11.
//  Copyright (c) 2011 University of California at Berkeley. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface YozioTests : SenTestCase

- (void)setMockDate:(NSDate *)aMockDate;

- (void)assertDataEqual:(NSMutableDictionary *)expected
                 actual:(NSMutableDictionary *)actual;

@end
