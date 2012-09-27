/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */

#import "YozioRequestManager.h"
#import "Yozio.h"
#import "YSeriously.h"
#import "UIKit/UIKit.h"
#import "YNSTimer+Blocks.h"

@implementation YozioRequestManager

static YozioRequestManager *instance = nil;

+ (void)initialize
{
  if (instance == nil) {
    instance = [[self alloc] init];
  }
}

+ (YozioRequestManager *)sharedInstance
{
  return instance;
}

+ (YozioRequestManager *)setInstance:(YozioRequestManager *)newInstance{
  instance = newInstance;
  return instance;
}

- (void)urlRequest:(NSString *)urlString timeOut:(NSInteger)timeOut handler:(SeriouslyHandler)callback {
  __block BOOL blocking = true;
  [NSTimer scheduledTimerWithTimeInterval:timeOut block:^{blocking = false;} repeats:NO];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  
  void (^requestBlock)(id body, NSHTTPURLResponse *response, NSError *error);
  requestBlock = ^(id body, NSHTTPURLResponse *response, NSError *error){
    callback(body, response, error);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    blocking = false;
  };
  
  [YSeriously get:urlString handler:requestBlock];
  if (timeOut > 0) {
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.05];
    while (blocking && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil]) {
      loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.05];
    }
  }
}

@end
