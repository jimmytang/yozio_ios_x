//
//  Yozio.h
//  GrenadeGame
//
//  Copyright 2011 Yozio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Yozio : NSObject

+ (void)configure:(NSString *)appId
           userId:(NSString *)userId
           bucket:(NSString *)bucket
              env:(NSString *)env
       appVersion:(NSString *)appVersion;

+ (void)startTimer:(NSString *)timerName;

+ (void)endTimer:(NSString *)timerName category:(NSString *)category;

+ (void)collect:(NSString *)key value:(NSString *)value category:(NSString *)category;

+ (void)funnel:(NSString *)funnelName funnelValue:(NSString *)funnelValue category:(NSString *)category;

+ (void)revenue:(NSString *)itemName itemCost:(double)itemCost category:(NSString *)category;

+ (void)action:(NSString *)actionName actionValue:(NSString *)actionValue category:(NSString *)category;

+ (void)error:(NSString *)errorName errorMessage:(NSString *)errorMessage category:(NSString *)category;

+ (void)flush;

@end
