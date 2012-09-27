/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */


#import "YozioRequestManagerMock.h"
#import "YozioRequestManager.h"
#import "Yozio.h"
#import "YSeriously.h"

@implementation YozioRequestManagerMock
@synthesize block;
@synthesize body;
@synthesize response;
@synthesize error;
@synthesize actualTimeOut;

- (void)urlRequest:(NSString *)urlString timeOut:(NSInteger)timeOut handler:(SeriouslyHandler)handler {
  self.block = handler;
  
  if (actualTimeOut) {
    [NSTimer scheduledTimerWithTimeInterval:actualTimeOut
                                     target:self
                                   selector:@selector(executeBlock)
                                   userInfo:nil
                                    repeats:NO];

  } else {
    [self executeBlock];
  }
}

- (void)executeBlock {
  self.block(body, response, error);
}
@end
