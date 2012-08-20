/*
 * Yozio.h
 *
 * Copyright (C) 2012 Yozio Inc.
 * 
 * This file is part of the Yozio SDK.
 * 
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */

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
 * Configures Yozio with your user's username. This is used to provide a better display to your data. (Optional)
 
 * @param userName  The application's username.
 */
+ (void)userLoggedIn:(NSString *)userName;

/**
 * Configures the Yozio SDK. Must be called when the app is initialized.
 * Connects to server to download configuration dictionary. Blocking
 *
 */
+ (void)initializeExperiments;

/**
 * Returns a configuration Object for key.
 * @param key      the key look up the Object by
 * @param defaultValue  default value in case the key isn’t found.
 */
+ (NSString*)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue;

/**
 * Returns a configuration Int for key.
 * @param key      the key look up the Int by
 * @param defaultValue  default value in case the key isn’t found.
 */
+ (NSInteger)intForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;

/**
 * Retrieve the shortened url for a dynamic link. Returns the destinationUrl if it can't get a short url. (blocking)
 *
 * @param linkName  the name of the link. Must match one of the link names created online.
 * @param destinationUrl  the url that the shortened url must redirect to.
 */
+ (NSString *)getUrl:(NSString *)linkName destinationUrl:(NSString *)destinationUrl;

/**
 * Alert Yozio that a user has viewed a link.
 * To edit this linkName, go to the VIRAL section of the Yozio website to find the appropriate link name to track.
 * @param linkName  the name of the link. Must match one of the link names created online.
 */
+ (void)viewedLink:(NSString *)linkName;

/**
 * Alert Yozio that a user has clicked on a link.
 * To edit this linkName, go to the VIRAL section of the Yozio website to find the appropriate link name to track.
 * @param linkName  the name of the link. Must match one of the link names created online.
 */
+ (void)sharedLink:(NSString *)linkName;

@end

#endif /* ! __YOZIO__ */