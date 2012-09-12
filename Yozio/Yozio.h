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
 * Notify Yozio that your user logged in.
 * This allows you to tie your data with Yozio's by user name.
 *
 * @param userName  The name of the user that just logged in.
 */
+ (void)userLoggedIn:(NSString *)userName;

/**
 * Initializes the Yozio SDK for experiments. Must be called when the app is initialized.
 * Makes a blocking HTTP request to download the experiment configurations. Not thread-safe.
 */
+ (void)initializeExperiments;

/**
 * Retrieve the String value for a given configuration key.
 *
 * @param key  The key of the value to retrieve. Must match a configuration key created online.
 * @param defaultValue  The value to return if the key is not found.
 * @return The configuration String value, or defaultValue if the key is not found.
 */
+ (NSString*)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue;

/**
 * Retrieve the Int value for a given configuration key.
 *
 * @param key  The key of the value to retrieve. Must match a configuration key created online.
 * @param defaultValue  The value to return if the key is not found.
 * @return The configuration Int value, or defaultValue if the key is not found.
 */
+ (NSInteger)intForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;

/**
 * Retrieve the Yozio short url for a given linkName. Blocking. Not thread-safe.
 *
 * @param linkName  The name of the viral tracking link.
 *                  Must match one of the link names created online.
 * @param destinationUrl  The url that the shortened url will redirect to.
 * @return The Yozio short URL for the linkName, or destinationUrl if there is an error.
 */
+ (NSString *)getUrl:(NSString *)linkName destinationUrl:(NSString *)destinationUrl;

/**
 * Retrieve the Yozio short url for a given linkName. Blocking. Not thread-safe.
 *
 * @param linkName  The name of the viral tracking link.
 *                  Must match one of the link names created online.
 * @param iosDestinationUrl  The url that the shortened url will redirect to if an iOS device.
 * @param androidDestinationUrl  The url that the shortened url will redirect to if an Android device.
 * @param nonMobileDestinationUrl  The url that the shortened url will redirect to if a non mobile device.
 * @return The Yozio short URL for the linkName, or nonMobileDestinationUrl if there is an error.
 */
+     (NSString *)getUrl:(NSString *)linkName
       iosDestinationUrl:(NSString *)iosDestinationUrl
   androidDestinationUrl:(NSString *)androidDestinationUrl
 nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl;

/**
 * Notify Yozio that a user has viewed a link.
 *
 * @param linkName  The name of the viral tracking link.
 *                  Must match one of the link names created online.
 */
+ (void)viewedLink:(NSString *)linkName;

/**
 * Notify Yozio that a user has shared a link.
 *
 * @param linkName  The name of the viral tracking link.
 *                  Must match one of the link names created online.
 */
+ (void)sharedLink:(NSString *)linkName;

@end

#endif /* ! __YOZIO__ */