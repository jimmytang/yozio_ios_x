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
 *
 * This will allow you to tie exported Yozio data with your own data.
 *
 * Warning: do not provide any personally identifiable information.
 *
 * @param userName  Name of the user that just logged in.
 */
+ (void)userLoggedIn:(NSString *)userName;

/**
 * Notify Yozio that your user logged in.
 *
 * This will allow you to tie exported Yozio data with your own data.
 *
 * Warning: do not provide any personally identifiable information.
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
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @return A Yozio link, or the destinationUrl if there is an error generating
 *         the Yozio link.
 */
+ (NSString *)getYozioLink:(NSString *)viralLoopName
                   channel:(NSString *)channel
            destinationUrl:(NSString *)destinationUrl;

/**
 * Makes a blocking HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @param properties  Arbitrary meta data to attach to the generated Yozio link.
 * @return A Yozio link, or the destinationUrl if there is an error generating
 *         the Yozio link.
 */
+ (NSString *)getYozioLink:(NSString *)viralLoopName
                   channel:(NSString *)channel
            destinationUrl:(NSString *)destinationUrl
                properties:(NSDictionary *)properties;

/**
 * Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @param callback  Called when the HTTP request completes.
 *                  The argument passed into the callback will be the Yozio
 *                  link, or the destinationUrl if there is an error generating
 *                  the Yozio link.
 */
+ (void)getYozioLinkAsync:(NSString *)viralLoopName
                  channel:(NSString *)channel
           destinationUrl:(NSString *)destinationUrl
                 callback:(void(^)(NSString *))callback;

/**
 * Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @param properties  Arbitrary meta data to attach to the generated Yozio link.
 * @param callback  Called when the HTTP request completes.
 *                  The argument passed into the callback will be the Yozio
 *                  link, or the destinationUrl if there is an error generating
 *                  the Yozio link.
 */
+ (void)getYozioLinkAsync:(NSString *)viralLoopName
                  channel:(NSString *)channel
           destinationUrl:(NSString *)destinationUrl
               properties:(NSDictionary *)properties
                 callback:(void(^)(NSString *))callback;

/**
 * Makes a blocking HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
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
                       channel:(NSString *)channel
             iosDestinationUrl:(NSString *)iosDestinationUrl
         androidDestinationUrl:(NSString *)androidDestinationUrl
       nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl;

/**
 * Makes a blocking HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
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
                       channel:(NSString *)channel
             iosDestinationUrl:(NSString *)iosDestinationUrl
         androidDestinationUrl:(NSString *)androidDestinationUrl
       nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                    properties:(NSDictionary *)properties;

/**
 * Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
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
                      channel:(NSString *)channel
            iosDestinationUrl:(NSString *)iosDestinationUrl
        androidDestinationUrl:(NSString *)androidDestinationUrl
      nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                     callback:(void(^)(NSString *))callback;

/**
 * Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
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
                      channel:(NSString *)channel
            iosDestinationUrl:(NSString *)iosDestinationUrl
        androidDestinationUrl:(NSString *)androidDestinationUrl
      nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                   properties:(NSDictionary *)properties
                     callback:(void(^)(NSString *))callback;

/**
 * Notify Yozio that the user has entered the viral loop.
 *
 * This event should be triggered at whatever point you define the beginning
 * of the viral loop to be.
 *
 * For example, a user can enter a viral loop whenever the share button for
 * the viral loop is shown.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels 
                   selected for the viral loop created on Yozio dashboard.
 */
+ (void)enteredViralLoop:(NSString *)viralLoopName channel:(NSString *)channel;

/**
 * Notify Yozio that the user has entered the viral loop.
 *
 * This event should be triggered at whatever point you define the beginning
 * of the viral loop to be.
 *
 * For example, a user can enter a viral loop whenever the share button for
 * the viral loop is shown.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
 * @param properties  Arbitrary meta data to attach to the event.
 */
+ (void)enteredViralLoop:(NSString *)viralLoopName channel:(NSString *)channel properties:(NSDictionary *)properties;

/**
 * Notify Yozio that the user has shared a Yozio link.
 *
 * This event should be triggered whenever a user has successfully shared a
 * Yozio link generated by getYozioLink.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
 selected for the viral loop created on Yozio dashboard.
 */
+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel;

/**
 * Notify Yozio that the user has shared a Yozio link.
 *
 * This event should be triggered whenever a user has successfully shared a
 * Yozio link generated by getYozioLink.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
 selected for the viral loop created on Yozio dashboard.
 * @param count  The number of shares this sharing event is creating. Example is a text message sent to 5 people should have a count of 5.
 */
+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel count:(NSInteger)count;

/**
 * Notify Yozio that the user has shared a Yozio link.
 *
 * This event should be triggered whenever a user has successfully shared a
 * Yozio link generated by getYozioLink.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
 selected for the viral loop created on Yozio dashboard.
 * @param properties  Arbitrary meta data to attach to the event.
 */
+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel properties:(NSDictionary *)properties;

/**
 * Notify Yozio that the user has shared a Yozio link.
 *
 * This event should be triggered whenever a user has successfully shared a
 * Yozio link generated by getYozioLink.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
 selected for the viral loop created on Yozio dashboard.
 * @param count  The number of shares this sharing event is creating.
 * @param properties  Arbitrary meta data to attach to the event. Example is a text message sent to 5 people should have a count of 5.
 */
+ (void)sharedYozioLink:(NSString *)viralLoopName
                channel:(NSString *)channel
                  count:(NSInteger)count
             properties:(NSDictionary *)properties;

@end

#endif /* ! __YOZIO__ */