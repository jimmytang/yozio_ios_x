//
//  YozioRequestManager.m
//  Yozio
//
//  Created by Jimmy Tang on 9/24/12.
//  Copyright (c) 2012 University of California at Berkeley. All rights reserved.
//

#import "YozioRequestManagerMock.h"
#import "YozioRequestManager.h"
#import "Yozio.h"
#import "YSeriously.h"

@implementation YozioRequestManagerMock
@synthesize block;
@synthesize body;
@synthesize response;
@synthesize error;
@synthesize timeOut;

- (void)urlRequest:(NSString *)urlString handler:(SeriouslyHandler)handler {
  self.block = handler;
  
  if (timeOut) {
    [NSTimer scheduledTimerWithTimeInterval:timeOut
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
