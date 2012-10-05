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
 * Configures the Yozio SDK. Must be called when your app is launched and
 * before any other method.
 *
 * @param appKey  Application specific key provided by Yozio.
 * @param secretKey  Application specific secret key provided by Yozio.
 */
+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey;

/**
 * Makes a blocking HTTP request to download the experiment configurations.
 * Must be called prior to using any experiment related SDK calls
 * (i.e. stringForKey and intForKey).
 */
+ (void)initializeExperiments;

/**
 * Makes an asynchronous HTTP request to download the experiment configurations.
 * Must be called prior to using any experiment related SDK calls
 * (i.e. stringForKey and intForKey).
 *
 * @param callback  Called when experiments has been initialized. 
 */
+ (void)initializeExperimentsAsync:(void(^)(void))callback;

/**
 * Retrieve the string value for a given configuration key.
 *
 * @param key  Key of the value to retrieve.
 * @param defaultValue  Value to return if the key is not found.
 * @return String value, or defaultValue if the key is not found.
 */
+ (NSString*)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue;

/**
 * Retrieve the integer value for a given configuration key.
 *
 * @param key  Key of the value to retrieve.
 * @param defaultValue  Value to return if the key is not found.
 * @return Integer value, or defaultValue if the key is not found.
 */
+ (NSInteger)intForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;

/**
 * Notify Yozio that your user logged in.
 * This allows you to tie your data with Yozio's by user name.
 *
 * @param userName  Name of the user that just logged in.
 */
+ (void)userLoggedIn:(NSString *)userName;

/**
 * Notify Yozio that your user logged in.
 * This allows you to tie your data with Yozio's by user name.
 *
 * @param userName  Name of the user that just logged in.
 * @param properties  Arbitrary meta data to attach to this event.
 */
+ (void)userLoggedIn:(NSString *)userName properties:(NSDictionary *)properties;

/**
 * Makes a blocking HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @return A Yozio link, or the destinationUrl if there is an error generating
 *         the Yozio link.
 */
+ (NSString *)getYozioLink:(NSString *)viralLoopName
            destinationUrl:(NSString *)destinationUrl;

/**
 * Makes a blocking HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @param properties  Arbitrary meta data to attach to the generated Yozio link.
 * @return A Yozio link, or the destinationUrl if there is an error generating
 *         the Yozio link.
 */
+ (NSString *)getYozioLink:(NSString *)viralLoopName
            destinationUrl:(NSString *)destinationUrl
                properties:(NSDictionary *)properties;

/**
 * Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @param callback  Called when the HTTP request completes.
 *                  The argument passed into the callback will be the Yozio
 *                  link, or the destinationUrl if there is an error generating
 *                  the Yozio link.
 */
+ (void)getYozioLinkAsync:(NSString *)viralLoopName
           destinationUrl:(NSString *)destinationUrl
                 callback:(void(^)(NSString *))callback;

/**
 * Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @param properties  Arbitrary meta data to attach to the generated Yozio link.
 * @param callback  Called when the HTTP request completes.
 *                  The argument passed into the callback will be the Yozio
 *                  link, or the destinationUrl if there is an error generating
 *                  the Yozio link.
 */
+ (void)getYozioLinkAsync:(NSString *)viralLoopName
           destinationUrl:(NSString *)destinationUrl
               properties:(NSDictionary *)properties
                 callback:(void(^)(NSString *))callback;

/**
 * Makes a blocking HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param iosDestinationUrl  URL that the generated Yozio link will redirect to
 *                           for iOS devices.
 * @param androidDestinationUrl URL that the generated Yozio link will redirect
 *                              to for Android devices.
 * @param nonMobileDestinationUrl  URL that the generated Yozio link will
 *                                 redirect to for all other devices.
 * @return A Yozio link, or the nonMobileDestinationUrl if there is an error
 *         generating the Yozio link.
 */
+     (NSString *)getYozioLink:(NSString *)viralLoopName
             iosDestinationUrl:(NSString *)iosDestinationUrl
         androidDestinationUrl:(NSString *)androidDestinationUrl
       nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl;

/**
 * Makes a blocking HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param iosDestinationUrl  URL that the generated Yozio link will redirect to
 *                           for iOS devices.
 * @param androidDestinationUrl URL that the generated Yozio link will redirect
 *                              to for Android devices.
 * @param nonMobileDestinationUrl  URL that the generated Yozio link will
 *                                 redirect to for all other devices.
 * @param properties  Arbitrary meta data to attach to the generated Yozio link.
 * @return A Yozio link, or the nonMobileDestinationUrl if there is an error
 *         generating the Yozio link.
 */
+     (NSString *)getYozioLink:(NSString *)viralLoopName
             iosDestinationUrl:(NSString *)iosDestinationUrl
         androidDestinationUrl:(NSString *)androidDestinationUrl
       nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                    properties:(NSDictionary *)properties;

/**
 * Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param iosDestinationUrl  URL that the generated Yozio link will redirect to
 *                           for iOS devices.
 * @param androidDestinationUrl URL that the generated Yozio link will redirect
 *                              to for Android devices.
 * @param nonMobileDestinationUrl  URL that the generated Yozio link will
 *                                 redirect to for all other devices.
 * @param callback  Called when the HTTP request completes.
 *                  The argument passed into the callback will be the Yozio
 *                  link, or the nonMobileDestinationUrl if there is an error
 *                  generating the Yozio link.
 */
+     (void)getYozioLinkAsync:(NSString *)viralLoopName
            iosDestinationUrl:(NSString *)iosDestinationUrl
        androidDestinationUrl:(NSString *)androidDestinationUrl
      nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                     callback:(void(^)(NSString *))callback;

/**
 * Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param iosDestinationUrl  URL that the generated Yozio link will redirect to
 *                           for iOS devices.
 * @param androidDestinationUrl URL that the generated Yozio link will redirect
 *                              to for Android devices.
 * @param nonMobileDestinationUrl  URL that the generated Yozio link will
 *                                 redirect to for all other devices.
 * @param properties  Arbitrary meta data to attach to the generated Yozio link.
 * @param callback  Called when the HTTP request completes.
 *                  The argument passed into the callback will be the Yozio
 *                  link, or the nonMobileDestinationUrl if there is an error
 *                  generating the Yozio link.
 */
+     (void)getYozioLinkAsync:(NSString *)viralLoopName
            iosDestinationUrl:(NSString *)iosDestinationUrl
        androidDestinationUrl:(NSString *)androidDestinationUrl
      nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                   properties:(NSDictionary *)properties
                     callback:(void(^)(NSString *))callback;

/**
 * Notify Yozio that a user has viewed a link.
 *
 * @param linkName  Name of the viral tracking link. Must match one of the
 *                  viral tracking link names created on the Yozio dashboard.
 */
+ (void)viewedLink:(NSString *)linkName;

/**
 * Notify Yozio that a user has viewed a link.
 *
 * @param linkName  Name of the viral tracking link. Must match one of the
 *                  viral tracking link names created on the Yozio dashboard.
 * @param properties  Arbitrary meta data to attach to the event.
 */
+ (void)viewedLink:(NSString *)linkName properties:(NSDictionary *)properties;

/**
 * Notify Yozio that a user has shared a link.
 *
 * @param linkName  Name of the viral tracking link. Must match one of the
 *                  viral tracking link names created on the Yozio dashboard.
 * @param properties  Additional meta properties to tag your event.
 */
+ (void)sharedLink:(NSString *)linkName;

/**
 * Notify Yozio that a user has shared a link.
 *
 * @param linkName  Name of the viral tracking link. Must match one of the
 *                  viral tracking link names created on the Yozio dashboard.
 * @param properties  Arbitrary meta data to attach to the event.
 */
+ (void)sharedLink:(NSString *)linkName properties:(NSDictionary *)properties;

@end

#endif /* ! __YOZIO__ */