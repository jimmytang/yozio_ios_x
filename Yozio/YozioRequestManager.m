//
//  YozioRequestManager.m
//  Yozio
//
//  Created by Jimmy Tang on 9/24/12.
//  Copyright (c) 2012 University of California at Berkeley. All rights reserved.
//

#import "YozioRequestManager.h"
#import "Yozio.h"
#import "YSeriously.h"
#import "UIKit/UIKit.h"
#import "NSTimer+Blocks.h"

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

- (void)urlRequest:(NSString *)urlString timeOut:(NSInteger)timeOut handler:(SeriouslyHandler)block {
  __block BOOL blocking = true;
  [NSTimer scheduledTimerWithTimeInterval:timeOut block:^{blocking = false;} repeats:NO];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  
  void (^requestBlock)(id body, NSHTTPURLResponse *response, NSError *error);
  requestBlock = ^(id body, NSHTTPURLResponse *response, NSError *error){
    block(body, response, error);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    blocking = false;
  };
  
  [YSeriously get:urlString handler:requestBlock];
  NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
  while (blocking && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil]) {
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.5];
  }
}

@end
