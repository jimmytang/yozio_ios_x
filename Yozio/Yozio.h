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
 * @param urlLinks  The dictionary of url names and links. This can not be empty.
 *  Example: [NSDictionary dictionaryWithObjectsAndKeys:@"www.example.com/twitter", @"twitter", 
                                                        @"www.example.com/facebook", @"facebook", nil];
 */
+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey urlLinks:(NSDictionary *)urlLinks;

+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey urlLinks:(NSDictionary *)urlLinks async:(BOOL)async;

/**
 * Set the userName for the device. Do this if you can to enable finding your most influential users.
 * @param userName: 
 */
+ (void)setUserName:(NSString *)userName;

/**
 * getUrl returns back a shortened url based on the url keyword.
 * @param urlName: 
 * @param defaultUrl: 
 */
+ (NSString *)getUrl:(NSString *)urlName;

/**
 * Alerts Yozio about when a user has viewed a link. Place this on pages where the link is loaded.
 */
+ (void)viewedLink:(NSString *)urlName;

/**
 * Alerts us about when a user has clicked on a link. Place this as a callback to your button links.
 */
+ (void)sharedLink:(NSString *)urlName;

@end

#endif /* ! __YOZIO__ */