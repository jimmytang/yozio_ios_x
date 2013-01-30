/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */


#import <Foundation/Foundation.h>
#import "YozioRequestManager.h"

@interface YozioRequestManagerMock : YozioRequestManager

{
  SeriouslyHandler block;
  id body;
  NSHTTPURLResponse *response;
  NSError *error;
  int timeOut;
}

@property(nonatomic, copy) SeriouslyHandler block;
@property(nonatomic, retain) id body;
@property(nonatomic, retain) NSHTTPURLResponse *response;
@property(nonatomic, retain) NSError *error;
@property(nonatomic, assign) int actualTimeOut;
@end
