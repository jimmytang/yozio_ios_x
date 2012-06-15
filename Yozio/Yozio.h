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
 * Retrieve the shortened url for the linkName.
 *
 * @param linkName  the name of the link. Must match one of the link names created online.
 * @param fallbackUrl  the url to return if retrieving the short url fails.
 */
+ (NSString *)getUrl:(NSString *)linkName fallbackUrl:(NSString *)fallbackUrl;

/**
 * Retrieve the shortened url for a dynamic link. (blocking)
 *
 * @param linkName  the name of the link. Must match one of the link names created online.
 * @param destinationUrl  the url that the shortened url must redirect to.
 * @param fallbackUrl  the url to return if retrieving the short url fails.
 */
+ (NSString *)getUrl:(NSString *)linkName destinationUrl:(NSString *)destinationUrl fallbackUrl:(NSString *)fallbackUrl;

/**
 * Alert Yozio that a user has viewed a link.
 *
 * @param linkName  the name of the link. Must match one of the link names created online.
 */
+ (void)viewedLink:(NSString *)linkName;

/**
 * Alert Yozio that a user has clicked on a link.
 *
 * @param linkName  the name of the link. Must match one of the link names created online.
 */
+ (void)sharedLink:(NSString *)linkName;

@end

#endif /* ! __YOZIO__ */