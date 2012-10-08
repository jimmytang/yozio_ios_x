//
//  Seriously.h
//  Prototype
//
//  Created by Corey Johnson on 6/18/10.
//  Copyright 2010 Probably Interactive. All rights reserved.
//

#if !defined(__YSeriously__)
#define __YSeriously__ 1

#import <Foundation/Foundation.h>
#import "YSeriouslyConstants.h"

@interface YSeriously : NSObject {
}

+ (YSeriouslyOperation *)request:(NSMutableURLRequest *)request options:(NSDictionary *)options handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)requestURL:(id)url options:(NSDictionary *)options handler:(SeriouslyHandler)handler;
+ (NSMutableDictionary *)options;
+ (NSOperationQueue *)operationQueue;

+ (YSeriouslyOperation *)get:(id)url handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)get:(id)url options:(NSDictionary *)options handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)post:(id)url handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)post:(id)url options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)post:(id)url body:(NSDictionary *)body handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)put:(id)url handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)put:(id)url options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)delete:(id)url handler:(SeriouslyHandler)handler;
+ (YSeriouslyOperation *)delete:(id)url options:(NSDictionary *)userOptions handler:(SeriouslyHandler)handler;

// Utility Methods
// ---------------
+ (NSURL *)url:(id)url params:(id)params;
+ (NSString *)formatQueryParams:(id)params;
+ (NSString *)escapeQueryParam:(id)param;

@end

#endif /* ! __YSeriously__ */
