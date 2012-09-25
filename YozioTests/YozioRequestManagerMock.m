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
@synthesize body;
@synthesize response;
@synthesize error;
@synthesize timeOut;

- (void)urlRequest:(NSString *)urlString handler:(SeriouslyHandler)block {
  if (timeOut) {
    [NSTimer scheduledTimerWithTimeInterval:timeOut
                                     target:instance
                                   selector:@selector(block(body, response, error))
                                   userInfo:nil
                                    repeats:NO];
  } else {
    block(body, response, error);
  }
}

@end
