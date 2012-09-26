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

- (void)urlRequest:(NSString *)urlString handler:(SeriouslyHandler)block {
  [YSeriously get:urlString handler:block];
}

@end
