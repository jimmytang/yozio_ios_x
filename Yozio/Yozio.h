//
//  Copyright 2011 Yozio. All rights reserved.
//

#if !defined(__YOZIO__)
#define __YOZIO__ 1

#import <Foundation/Foundation.h>

@interface Yozio : NSObject

/**
 * Configures Yozio with your application's information.
 
 * @param appKey  The application name we provided you for your application.
 * @param secretKey  The top secret key that only you know about. Don't share this with others!
 */
+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey;

/**
 * getUrl returns back a shortened url based on the url keyword.
 * @param urlName: 
 * @param fallbackUrl: 
 */
+ (NSString *)getUrl:(NSString *)linkName fallbackUrl:(NSString *)fallbackUrl;

/**
 * Alerts Yozio about when a user has viewed a link. Place this on pages where the link is loaded.
 */
+ (void)viewedLink:(NSString *)linkName;

/**
 * Alerts us about when a user has clicked on a link. Place this as a callback to your button links.
 */
+ (void)sharedLink:(NSString *)linkName;

@end

#endif /* ! __YOZIO__ */