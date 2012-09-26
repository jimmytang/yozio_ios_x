//
//  YozioRequestManager.h
//  Yozio
//
//  Created by Jimmy Tang on 9/24/12.
//  Copyright (c) 2012 University of California at Berkeley. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YSeriously.h"

@interface YozioRequestManager : NSObject

+ (YozioRequestManager *)sharedInstance;
+ (YozioRequestManager *)setInstance:(YozioRequestManager *)newInstance;
- (void)urlRequest:(NSString *)urlString timeOut:(NSInteger)timeOut handler:(SeriouslyHandler)block;

@end
