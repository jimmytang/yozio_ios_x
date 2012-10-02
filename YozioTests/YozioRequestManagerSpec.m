//
//  YozioRequestManagerSpec.m
//  Yozio
//
//  Created by Jimmy Tang on 9/26/12.
//  Copyright (c) 2012 University of California at Berkeley. All rights reserved.
//

#import "Kiwi.h"
#import "KWIntercept.h"
#import "Yozio.h"
#import "Yozio_Private.h"
#import "YozioRequestManager.h"
#import "YSeriously.h"
#import "YJSONKit.h"
#import "YOpenUDID.h"

SPEC_BEGIN(YozioRequestManagerSpec)

describe(@"urlRequest", ^{
  it(@"should return immediately after response if response is received back before timeOut", ^{
    NSDate *start = [NSDate date];
    YozioRequestManager *instance = [YozioRequestManager sharedInstance];
    
    void (^requestCallback)(id body, NSHTTPURLResponse *response, NSError *error);
    requestCallback = ^(id body, NSHTTPURLResponse *response, NSError *error){};
    
    [instance urlRequest:@"http://www.google.com" options:[NSDictionary dictionary] timeOut:1 handler:requestCallback];
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    [[theValue(timeInterval) should] beLessThan:theValue(1)];
  });

  it(@"should return after timeOut if response is not received before timeOut", ^{
    NSDate *start = [NSDate date];
    YozioRequestManager *instance = [YozioRequestManager sharedInstance];
    instance.responseDelay = 2;
    
    void (^requestCallback)(id body, NSHTTPURLResponse *response, NSError *error);
    requestCallback = ^(id body, NSHTTPURLResponse *response, NSError *error){};
    
    [instance urlRequest:@"http://www.google.com" options:[NSDictionary dictionary] timeOut:1 handler:requestCallback];
    NSTimeInterval timeInterval = [start timeIntervalSinceNow];
    [[theValue(timeInterval) should] beLessThan:theValue(2)];
  });
});

SPEC_END
