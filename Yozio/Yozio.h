//
//  Copyright 2011 Yozio. All rights reserved.
//

#if !defined(__YOZIO__)
#define __YOZIO__ 1

#import <Foundation/Foundation.h>

@interface Yozio : NSObject

/**
 * Configures Yozio with your application's information.
 *
 * @param appKey  The application name we provided you for your application.
 * @param secretKey  The top secret key that only you know about. Don't share this with others!
 * @param urlKeys  The array of url keys
 *
 * TODO(jt): use more realistic configure example
 * @example [Yozio configure:@"appKey" secretKey:@"mySecretKey"];
 */
+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey urlKeys:(NSArray *)urlKeys;

+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey urlKeys:(NSArray *)urlKeys async:(BOOL)async;

/**
 * getUrl returns back a shortened url based on the url keyword.
 * @param urlKey: 
 * @param defaultUrl: 
 */
+ (NSString *)getUrl:(NSString *)urlKey defaultUrl:(NSString *)defaultUrl;


/**
 * Alerts Yozio about when a user has viewed a link. Place this on pages where the link is loaded.
 */
+ (void)viewedLink;

/**
 * Alerts us about when a user has clicked on a link. Place this as a callback to your button links.
 */
+ (void)clickedLink;

/**
 * Alerts Yozio about when a user has opened their app.Place this right after configure.
 */
+ (void)openedApp;

@end

#endif /* ! __YOZIO__ */