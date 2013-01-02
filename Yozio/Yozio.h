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
 * @param callback  Called when the configure call completes and returns a dictionary of link meta data.
 */
+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey;
+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey callback:(void(^)(NSDictionary *))callback;

/**
 * getYozioLink - Makes an blocking HTTP request to generate a Yozio link.
 * getYozioLinkAsync - Makes an asynchronous HTTP request to generate a Yozio link.
 *
 * @param viralLoopName  Name of the viral loop. Must match the name of one of
 *                       the viral loops created on the Yozio dashboard.
 * @param channel  The social channel being used. Must match the channels
                   selected for the viral loop created on Yozio dashboard.
 * @param destinationUrl  URL that the generated Yozio link will redirect to.
 * @param iosDestinationUrl  URL that the generated Yozio link will redirect to
 *                           for iOS devices.
 * @param androidDestinationUrl URL that the generated Yozio link will redirect
 *                              to for Android devices.
 * @param nonMobileDestinationUrl  URL that the generated Yozio link will
 *                                 redirect to for all other devices.
 * @param properties  Arbitrary meta data to attach to the Yozio Link used to tie with your own data on export.
 * @param callback  Called when the HTTP request completes.
 *                  The argument passed into the callback will be the Yozio
 *                  link, or the nonMobileDestinationUrl if there is an error
 *                  generating the Yozio link.
 */
+ (NSString *)getYozioLink:(NSString *)viralLoopName
                   channel:(NSString *)channel
            destinationUrl:(NSString *)destinationUrl;
+ (NSString *)getYozioLink:(NSString *)viralLoopName
                   channel:(NSString *)channel
            destinationUrl:(NSString *)destinationUrl
                properties:(NSDictionary *)properties;
+ (void)getYozioLinkAsync:(NSString *)viralLoopName
                  channel:(NSString *)channel
           destinationUrl:(NSString *)destinationUrl
                 callback:(void(^)(NSString *))callback;
+ (void)getYozioLinkAsync:(NSString *)viralLoopName
                  channel:(NSString *)channel
           destinationUrl:(NSString *)destinationUrl
               properties:(NSDictionary *)properties
                 callback:(void(^)(NSString *))callback;

+ (NSString *)getYozioLink:(NSString *)viralLoopName
                   channel:(NSString *)channel
         iosDestinationUrl:(NSString *)iosDestinationUrl
     androidDestinationUrl:(NSString *)androidDestinationUrl
   nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl;
+ (NSString *)getYozioLink:(NSString *)viralLoopName
                   channel:(NSString *)channel
         iosDestinationUrl:(NSString *)iosDestinationUrl
     androidDestinationUrl:(NSString *)androidDestinationUrl
   nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                properties:(NSDictionary *)properties;
+ (void)getYozioLinkAsync:(NSString *)viralLoopName
                  channel:(NSString *)channel
        iosDestinationUrl:(NSString *)iosDestinationUrl
    androidDestinationUrl:(NSString *)androidDestinationUrl
  nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                 callback:(void(^)(NSString *))callback;
+ (void)getYozioLinkAsync:(NSString *)viralLoopName
                  channel:(NSString *)channel
        iosDestinationUrl:(NSString *)iosDestinationUrl
    androidDestinationUrl:(NSString *)androidDestinationUrl
  nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
               properties:(NSDictionary *)properties
                 callback:(void(^)(NSString *))callback;

/**
 * Notify Yozio that your user logged in.
 *
 * This will allow you to tie exported Yozio data with your own data.
 *
 * Warning: do not provide any personally identifiable information about your user.
 *
 * @param userName  Name of the user that just logged in.
 * @param properties  Arbitrary meta data to attach to this event used to tie with your own data on export.
 */
+ (void)userLoggedIn:(NSString *)userName;
+ (void)userLoggedIn:(NSString *)userName properties:(NSDictionary *)properties;

/**
 * Notify Yozio that the user has entered the viral loop. (Deprecated)
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
 * @param properties  Arbitrary meta data to attach to this event used to tie with your own data on export.
 */
+ (void)enteredViralLoop:(NSString *)viralLoopName channel:(NSString *)channel;
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
 * @param count  The number of shares this sharing event is creating. Example is an SMS sent to 5 people should have a count of 5.
 * @param properties  Arbitrary meta data to attach to this event used to tie with your own data on export. 
 */
+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel;
+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel count:(NSInteger)count;
+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel properties:(NSDictionary *)properties;
+ (void)sharedYozioLink:(NSString *)viralLoopName
                channel:(NSString *)channel
                  count:(NSInteger)count
             properties:(NSDictionary *)properties;

@end

#endif /* ! __YOZIO__ */