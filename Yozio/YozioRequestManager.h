/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */


#import <Foundation/Foundation.h>
#import "YSeriously.h"

@interface YozioRequestManager : NSObject

+ (YozioRequestManager *)sharedInstance;
+ (YozioRequestManager *)setInstance:(YozioRequestManager *)newInstance;
- (void)urlRequest:(NSString *)urlString timeOut:(NSInteger)timeOut handler:(SeriouslyHandler)block;

@end
