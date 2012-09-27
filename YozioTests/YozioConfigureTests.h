/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */


#import <SenTestingKit/SenTestingKit.h>

@interface YozioConfigureTests : SenTestCase

- (void)setMockDate:(NSDate *)aMockDate;
- (void)setMockEventID:(NSString *)uuid;
@end
