/*
 * Yozio_Private.h
 *
 * Copyright (C) 2012 Yozio Inc.
 * 
 * This file is part of the Yozio SDK.
 * 
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */


#if !defined(__YOZIO_PRIVATE__)
#define __YOZIO_PRIVATE__ 1

#import "Yozio.h"

#define YOZIO_SDK_VERSION @"IOS-v3.1"
#define YOZIO_DEFAULT_BASE_URL @"http://yoz.io"
#define YOZIO_GET_CONFIGURATIONS_ROUTE @"/api/yozio/v1/get_configurations"
#define YOZIO_GET_URL_ROUTE @"/api/viral/v1/get_url"
#define YOZIO_BATCH_EVENTS_ROUTE @"/api/sdk/v1/batch_events"
#define YOZIO_LAUNCH_APP @"/api/sdk/v1/launch_app"

#define YOZIO_GET_CONFIGURATION_P_APP_KEY @"app_key"
#define YOZIO_GET_CONFIGURATION_P_YOZIO_UDID @"yozio_udid"
#define YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE @"device_type"
#define YOZIO_GET_URL_P_LINK_NAME @"link_name"
#define YOZIO_GET_URL_P_CHANNEL @"channel"
#define YOZIO_GET_URL_P_YOZIO_PROPERTIES @"yozio_properties"
#define YOZIO_GET_URL_P_DEST_URL @"dest_url"
#define YOZIO_GET_URL_P_IOS_DEST_URL @"ios_dest_url"
#define YOZIO_GET_URL_P_ANDROID_DEST_URL @"android_dest_url"
#define YOZIO_GET_URL_P_NON_MOBILE_DEST_URL @"non_mobile_dest_url"
#define YOZIO_BATCH_EVENTS_P_DATA @"data"


// Set to true to show log messages.
#define YOZIO_LOG false

// Payload keys.
#define YOZIO_P_APP_KEY @"app_key"
#define YOZIO_P_APP_VERSION @"app_version"
#define YOZIO_P_COUNTRY_CODE @"country_code"
#define YOZIO_P_DEVICE_TYPE @"device_type"
#define YOZIO_P_DISPLAY_MULTIPLIER @"display_multiplier"
#define YOZIO_P_EXPERIMENT_VARIATION_SIDS @"experiment_variation_sids"
#define YOZIO_P_EXTERNAL_PROPERTIES @"external_properties"
#define YOZIO_P_MAC_ADDRESS @"mac_address"
#define YOZIO_P_LANGUAGE_CODE @"language_code"
#define YOZIO_P_IS_JAILBROKEN @"is_jailbroken"
#define YOZIO_P_HARDWARE @"hardware"
#define YOZIO_P_OPEN_UDID @"open_udid"
#define YOZIO_P_OPEN_UDID_COUNT @"open_udid_count"
#define YOZIO_P_OS_VERSION @"os_version"
#define YOZIO_P_PAYLOAD @"payload"
#define YOZIO_P_SDK_VERSION @"sdk_version"
#define YOZIO_P_USER_NAME @"external_user_id"
#define YOZIO_P_YOZIO_PROPERTIES @"yozio_properties"
#define YOZIO_P_YOZIO_UDID @"yozio_udid"

// Payload data entry keys.
#define YOZIO_D_EVENT_TYPE @"event_type"
#define YOZIO_D_LINK_NAME @"link_name"
#define YOZIO_D_CHANNEL @"channel"
#define YOZIO_D_COUNT @"count"
#define YOZIO_D_FIRST_OPEN @"first_open"
#define YOZIO_D_TIMESTAMP @"timestamp"
#define YOZIO_D_EVENT_IDENTIFIER @"event_identifier"

// Mobile configuration data keys.
#define YOZIO_URLS_KEY @"urls"
#define YOZIO_CONFIG_KEY @"experiment_configs"
#define YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY @"experiment_variation_sids"


#define YOZIO_DATA_QUEUE_FILE [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]

// The number of items in the queue before forcing a flush.
#define YOZIO_FLUSH_DATA_COUNT 1

// The number of items to flush at a time
#define YOZIO_FLUSH_DATA_SIZE 20

// Actions
#define YOZIO_VIEWED_LINK_ACTION @"11"
#define YOZIO_SHARED_LINK_ACTION @"12"
#define YOZIO_OPENED_APP_ACTION @"5"
#define YOZIO_LOGIN_ACTION @"6"

// XX_DATA_LIMIT describes the required number of items in the queue before that instrumentation
// event type starts being dropped.
#define YOZIO_ACTION_DATA_LIMIT 200

// Device constants
#define YOZIO_DEVICE_TYPE_IOS @"2"

@interface Yozio()
{
  // User set instrumentation variables.
  NSString *_appKey;
  NSString *_secretKey;
  NSString *_userName;

  // Automatically determined instrumentation variables.
  NSString *deviceId;
  NSString *hardware;
  NSString *osVersion;
  NSString *countryCode;
  NSString *languageCode;
  
  // Internal variables.
  NSInteger dataCount;
  NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSMutableDictionary *experimentConfig;
  NSMutableDictionary *experimentVariationSids;
  NSDateFormatter *dateFormatter;
}

// User set instrumentation variables.
@property(nonatomic, retain) NSString *_appKey;
@property(nonatomic, retain) NSString *_secretKey;
@property(nonatomic, retain) NSString *_userName;

// Automatically determined instrumentation variables.
@property(nonatomic, retain) NSString *deviceId;
@property(nonatomic, retain) NSString *hardware;
@property(nonatomic, retain) NSString *osVersion;
@property(nonatomic, retain) NSString *countryCode;
@property(nonatomic, retain) NSString *languageCode;

// Internal variables.
@property(nonatomic, assign) NSInteger dataCount;
@property(nonatomic, retain) NSMutableArray *dataQueue;
@property(nonatomic, retain) NSArray *dataToSend;
@property(nonatomic, retain) NSMutableDictionary *experimentConfig;
@property(nonatomic, retain) NSMutableDictionary *experimentVariationSids;
@property(nonatomic, retain) NSDateFormatter *dateFormatter;

+ (Yozio *)getInstance;
+ (Yozio *)setInstance:(Yozio *)newInstance;
+ (void)log:(NSString *)format, ...;
+ (void)openedApp;

// Notification observer methods.
- (void)onApplicationWillTerminate:(NSNotification *)notification;

// Data collection helper methods.
+ (void)addIfNotNil:(NSMutableDictionary*)dict
                key:(NSString *)key
                obj:(NSObject *)obj;
- (BOOL)validateConfiguration;
- (void)doCollect:(NSString *)name
    viralLoopName:(NSString *)viralLoopName
          channel:(NSString *)channel
     eventOptions:(NSDictionary *)eventOptions
         maxQueue:(NSInteger)maxQueue
       properties:(NSDictionary *)properties;
- (void)checkDataQueueSize;
- (void)doFlush;
- (NSString *)buildPayload;

+ (void)initializeExperimentsHelper:(NSInteger)timeOut callback:(void(^)(void))callback;

- (NSString *)getYozioLinkRequest:(NSDictionary *)urlParams
                          destUrl:(NSString *)destUrl
                          timeOut:(NSInteger)timeOut
                         callback:(void(^)(NSString *))callback;
// Instrumentation data helper methods.
- (NSString *)timeStampString;
- (NSString *)eventID;
// File system helper methods.
- (void)saveUnsentData;
- (void)loadUnsentData;

@end

#endif /* ! __YOZIO_PRIVATE__ */
