/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */

#import "UIKit/UIKit.h"
#import "CommonCrypto/CommonCryptor.h"
#import "YJSONKit.h"
#import "YSeriously.h"
#import "YOpenUDID.h"
#import "YozioRequestManager.h"
#import <CommonCrypto/CommonHMAC.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

#import "Yozio.h"
#import "Yozio_Private.h"


@implementation Yozio

// User set instrumentation variables.
@synthesize _appKey;
@synthesize _secretKey;
@synthesize _userName;

// Automatically determined instrumentation variables.
@synthesize deviceId;
@synthesize hardware;
@synthesize osVersion;
@synthesize countryCode;
@synthesize languageCode;

// Internal variables.
@synthesize dataQueue;
@synthesize dataToSend;
@synthesize dataCount;
@synthesize dateFormatter;
@synthesize experimentConfig;
@synthesize experimentVariationSids;

/*******************************************
 * Initialization.
 *******************************************/

static Yozio *instance = nil;

+ (void)initialize
{
  if (instance == nil) {
    instance = [[self alloc] init];
  }
}

- (id)init
{
  self = [super init];
  
  // User set instrumentation variables.
  self._appKey = nil;
  self._secretKey = nil;
  self._userName = nil;
  
  // Initialize constant intrumentation variables.
  UIDevice* device = [UIDevice currentDevice];
  self.deviceId = [YOpenUDID value];
  self.hardware = [device model];
  self.osVersion = [device systemVersion];
  
  // Initialize  mutable instrumentation variables.  
  self.dataCount = 0;
  self.dataQueue = [NSMutableArray array];
  self.dataToSend = nil;
  self.experimentConfig = [NSMutableDictionary dictionary];
  
  // Initialize dateFormatter.
  NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  NSDateFormatter *tmpDateFormatter = [[NSDateFormatter alloc] init];
  self.dateFormatter = tmpDateFormatter;
  [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss SSS"];
  [self.dateFormatter setTimeZone:gmt];
  [tmpDateFormatter release];
  
  // Add notification observers.
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self
                         selector:@selector(onApplicationWillTerminate:)
                             name:UIApplicationWillTerminateNotification
                           object:nil];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
  if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
    [notificationCenter addObserver:self
                           selector:@selector(onApplicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
  }
#endif
  
  return self;
}

// Used for testing.
+ (Yozio *)getInstance
{
  return instance;
}

+ (Yozio *)setInstance:(Yozio *)newInstance
{
  instance = newInstance;
  return instance;
}

+ (void)log:(NSString *)format, ...
{
  if (YOZIO_LOG) {
    va_list argList;
    va_start(argList, format);
    NSString *formatStr = [[NSString alloc] initWithFormat:format arguments:argList];
    va_end(argList);
    NSLog(@"%@", formatStr);
    [formatStr release];
  }
}


/*******************************************
 * Public API.
 *******************************************/

+ (void)configure:(NSString *)appKey
        secretKey:(NSString *)secretKey
{
  [Yozio configure:appKey
         secretKey:secretKey
          callback:NULL];
}

+ (void)configure:(NSString *)appKey
        secretKey:(NSString *)secretKey
         callback:(void(^)(NSDictionary *))callback
{
  if (appKey == nil) {
    [NSException raise:NSInvalidArgumentException format:@"appKey cannot be nil."];
  }
  if (secretKey == nil) {
    [NSException raise:NSInvalidArgumentException format:@"secretKey cannot be nil."];
  }
  instance._appKey = appKey;
  instance._secretKey = secretKey;
  instance._configureCallback = callback;
  if (![instance validateConfiguration]) {
    return;
  }
  
  // Load any previous data.
  // Perform this here instead of on applicationDidFinishLoading because instrumentation calls
  // could be made before an application is finished loading.
  [instance loadUnsentData];
  [instance doFlush];
  [Yozio openedApp];
}

+ (void)userLoggedIn:(NSString *)userName
{
  [self userLoggedIn:(NSString *)userName properties:nil];
}

+ (void)userLoggedIn:(NSString *)userName properties:(NSDictionary *)properties
{
  instance._userName = userName;
  [instance doCollect:YOZIO_LOGIN_ACTION
        viralLoopName:@""
              channel:@""
         eventOptions:[NSDictionary dictionary]
             maxQueue:YOZIO_ACTION_DATA_LIMIT
           properties:properties];
}


+ (void)initializeExperiments
{
  [self initializeExperimentsHelper:5 callback:nil];
}

+ (void)initializeExperimentsAsync:(void(^)(void))callback
{
  [self initializeExperimentsHelper:0 callback:callback];
}

+ (NSString*)stringForKey:(NSString *)key defaultValue:(NSString *) defaultValue;
{
  @try {
    if (instance.experimentConfig == nil) {
      return defaultValue;
    }
    NSString *val = [instance.experimentConfig objectForKey:key];
    if([val isKindOfClass:[NSString class]]) {
      return val;
    } else {
      return defaultValue;
    }
  }
  @catch (NSException * e) {
    return defaultValue;
  }
}

+ (NSInteger)intForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
{
  @try {
    if (instance.experimentConfig == nil) {
      return defaultValue;
    }
    NSString *val = [instance.experimentConfig objectForKey:key];
    if(val == nil || ![val isKindOfClass:[NSString class]]) {
      return defaultValue;
    } else {
      NSInteger intVal = [val integerValue];
      NSString *verifierVal = [NSString stringWithFormat:@"%d", intVal];
      // verify the value is an integer
      if(![verifierVal isEqual:val]) {
        NSLog(@"intForKey '%@' is returning '%d' from '%@', which don't match", key, intVal, val);
        return defaultValue;
      }
      return intVal;
    }
  }
  @catch (NSException * e) {
    return defaultValue;
  }
}

+ (NSString *)getYozioLink:(NSString *)viralLoopName
                   channel:(NSString *)channel
            destinationUrl:(NSString *)destinationUrl
{
  return [Yozio getYozioLinkHelper:viralLoopName
                           channel:channel
                    destinationUrl:destinationUrl
                        properties:nil
                           timeOut:5
                          callback:nil];
}

+ (NSString *)getYozioLink:(NSString *)viralLoopName
                   channel:(NSString *)channel
            destinationUrl:(NSString *)destinationUrl
                properties:(NSDictionary *)properties
{
  return [Yozio getYozioLinkHelper:viralLoopName
                           channel:channel
                    destinationUrl:destinationUrl
                        properties:properties
                           timeOut:5
                          callback:nil];
}

+ (void)getYozioLinkAsync:(NSString *)viralLoopName
                  channel:(NSString *)channel
           destinationUrl:(NSString *)destinationUrl
                 callback:(void(^)(NSString *))callback
{
  [Yozio getYozioLinkHelper:viralLoopName
                    channel:channel
             destinationUrl:destinationUrl
                 properties:nil
                    timeOut:0
                   callback:callback];
}

+ (void)getYozioLinkAsync:(NSString *)viralLoopName
                  channel:(NSString *)channel
           destinationUrl:(NSString *)destinationUrl
               properties:(NSDictionary *)properties
                 callback:(void(^)(NSString *))callback
{
  [Yozio getYozioLinkHelper:viralLoopName
                    channel:channel
             destinationUrl:destinationUrl
                 properties:properties
                    timeOut:0
                   callback:callback];
}

+     (NSString *)getYozioLink:(NSString *)viralLoopName
                       channel:(NSString *)channel
             iosDestinationUrl:(NSString *)iosDestinationUrl
         androidDestinationUrl:(NSString *)androidDestinationUrl
       nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
{
  return [Yozio getYozioLinkHelper:viralLoopName
                           channel:channel
                 iosDestinationUrl:iosDestinationUrl
             androidDestinationUrl:androidDestinationUrl
           nonMobileDestinationUrl:nonMobileDestinationUrl
                        properties:nil
                           timeOut:5
                          callback:nil];
}

+     (NSString *)getYozioLink:(NSString *)viralLoopName
                       channel:(NSString *)channel
             iosDestinationUrl:(NSString *)iosDestinationUrl
         androidDestinationUrl:(NSString *)androidDestinationUrl
       nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                    properties:(NSDictionary *)properties
{
  return [Yozio getYozioLinkHelper:viralLoopName
                           channel:channel
                 iosDestinationUrl:iosDestinationUrl
             androidDestinationUrl:androidDestinationUrl
           nonMobileDestinationUrl:nonMobileDestinationUrl
                        properties:properties
                           timeOut:5
                          callback:nil];
}

+      (void)getYozioLinkAsync:(NSString *)viralLoopName
                       channel:(NSString *)channel
             iosDestinationUrl:(NSString *)iosDestinationUrl
         androidDestinationUrl:(NSString *)androidDestinationUrl
       nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                      callback:(void (^)(NSString *))callback
{
    [Yozio getYozioLinkHelper:viralLoopName
                      channel:channel
            iosDestinationUrl:iosDestinationUrl
        androidDestinationUrl:androidDestinationUrl
      nonMobileDestinationUrl:nonMobileDestinationUrl
                   properties:nil
                      timeOut:0
                     callback:callback];
}

+     (void)getYozioLinkAsync:(NSString *)viralLoopName
                      channel:(NSString *)channel
            iosDestinationUrl:(NSString *)iosDestinationUrl
        androidDestinationUrl:(NSString *)androidDestinationUrl
      nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                   properties:(NSDictionary *)properties
                     callback:(void (^)(NSString *))callback
{
    [Yozio getYozioLinkHelper:viralLoopName
                      channel:channel
            iosDestinationUrl:iosDestinationUrl
        androidDestinationUrl:androidDestinationUrl
      nonMobileDestinationUrl:nonMobileDestinationUrl
                   properties:properties
                      timeOut:0
                     callback:callback];
}

+ (void)enteredViralLoop:(NSString *)viralLoopName channel:(NSString *)channel
{
  [self enteredViralLoop:viralLoopName channel:channel properties:nil];
}

+ (void)enteredViralLoop:(NSString *)viralLoopName channel:(NSString *)channel properties:(NSDictionary *)properties
{
  [instance doCollect:YOZIO_VIEWED_LINK_ACTION
        viralLoopName:viralLoopName
              channel:channel
         eventOptions:[NSDictionary dictionary]
             maxQueue:YOZIO_ACTION_DATA_LIMIT
           properties:properties];
}

+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel
{
  [self sharedYozioLink:viralLoopName channel:channel count:1 properties:nil];
}

+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel count:(NSInteger)count
{
  [self sharedYozioLink:viralLoopName channel:channel count:count properties:nil];
}

+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel properties:(NSDictionary *)properties
{
  [self sharedYozioLink:viralLoopName channel:channel count:1 properties:properties];
}

+ (void)sharedYozioLink:(NSString *)viralLoopName channel:(NSString *)channel count:(NSInteger)count properties:(NSDictionary *)properties
{
  [instance doCollect:YOZIO_SHARED_LINK_ACTION
        viralLoopName:viralLoopName
              channel:channel
         eventOptions:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%d", count] forKey:YOZIO_D_COUNT]
             maxQueue:YOZIO_ACTION_DATA_LIMIT
           properties:properties];
}

/*******************************************
 * Notification observer methods.
 *******************************************/

- (void)onApplicationWillTerminate:(NSNotification *)notification
{
  [self saveUnsentData];
}

- (void)onApplicationDidEnterBackground:(NSNotification *)notification
{
  [self saveUnsentData];
}

/*******************************************
 * Data collection helper methods.
 *******************************************/

- (BOOL)validateConfiguration
{
  BOOL validAppKey = self._appKey != nil;
  if (!validAppKey) {
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    NSLog(@"Yozio: appKey is nil. Please call [Yozio configure] with a valid appKey.");
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  }
  BOOL validSecretKey = self._secretKey != nil;
  if (!validSecretKey) {
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    NSLog(@"Yozio: secretKey is nil. Please call [Yozio configure] with a valid secretKey.");
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  }
  return validAppKey && validSecretKey;
}

- (void)doCollect:(NSString *)type
    viralLoopName:(NSString *)viralLoopName
          channel:(NSString *)channel
     eventOptions:(NSDictionary *)eventOptions
         maxQueue:(NSInteger)maxQueue
       properties:(NSDictionary *)properties
{
  if (![self validateConfiguration]) {
    return;
  }
  dataCount++;
  if ([self.dataQueue count] < maxQueue) {
    NSDictionary* d = [Yozio createQueueItem:type
                               viralLoopName:viralLoopName
                                     channel:channel
                                eventOptions:eventOptions
                                  properties:properties];
    [self.dataQueue addObject:d];
    [Yozio log:@"doCollect: %@", d];
  }
  [self checkDataQueueSize];
}


+ (NSDictionary *) createQueueItem:(NSString *)type
                     viralLoopName:(NSString *)viralLoopName
                           channel:(NSString *)channel
                      eventOptions:(NSDictionary *)eventOptions
                        properties:(NSDictionary *)properties {
  NSMutableDictionary* d = [NSMutableDictionary dictionaryWithDictionary:eventOptions];
  [Yozio addIfNotNil:d key:YOZIO_D_EVENT_TYPE obj:type];
  [Yozio addIfNotNil:d key:YOZIO_D_LINK_NAME obj:viralLoopName];
  [Yozio addIfNotNil:d key:YOZIO_D_CHANNEL obj:channel];
  [Yozio addIfNotNil:d key:YOZIO_D_TIMESTAMP obj:[instance timeStampString]];
  [Yozio addIfNotNil:d key:YOZIO_D_EVENT_IDENTIFIER obj:[instance eventID]];
  [Yozio addIfNotNil:d key:YOZIO_P_EXTERNAL_PROPERTIES obj:[properties JSONString]]; // [nil JSONString] == nil
  return d;
}


+ (void)openedApp
{
  NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString *plistPath = [rootPath stringByAppendingPathComponent:@"yozio_first_open_tracker.plist"];
  NSData *plistData = [NSData data];

  NSFileManager *fileManager = [NSFileManager defaultManager];
  NSMutableDictionary* eventOptions = [NSMutableDictionary dictionary];
  if ([fileManager fileExistsAtPath:plistPath]){
    [eventOptions setObject:[NSNumber numberWithBool:NO] forKey:YOZIO_D_FIRST_OPEN];
  } else {
    [plistData writeToFile:plistPath atomically:YES];
    [eventOptions setObject:[NSNumber numberWithBool:YES] forKey:YOZIO_D_FIRST_OPEN];
  }
  
  NSDictionary* d = [Yozio createQueueItem:YOZIO_OPENED_APP_ACTION
                             viralLoopName:@""
                                   channel:@""
                              eventOptions:eventOptions
                                properties:nil
                     ];
  
  NSString* payload = [[instance buildPayload:[NSArray arrayWithObject:d]] JSONString];
  
  __block NSDictionary *urlParams = [NSDictionary dictionaryWithObject:payload
                                                                forKey:YOZIO_BATCH_EVENTS_P_DATA];
  NSString *urlString = [NSString stringWithFormat:@"%@%@", YOZIO_DEFAULT_BASE_URL, YOZIO_OPENED_APP_ROUTE];

  [Yozio log:@"Final get request url: %@", urlString];
  [[YozioRequestManager sharedInstance] urlRequest:urlString
                                              body:urlParams
                                           timeOut:0
                                           handler:^(id body, NSHTTPURLResponse *response, NSError *error)
   {
     if (error) {
       [Yozio log:@"Opened App error %@", error];
     } else if ([body isKindOfClass:[NSDictionary class]]){
       NSDictionary *yozioProperties = [body objectForKey:YOZIO_PROPERTIES];
       if ([yozioProperties objectForKey:YOZIO_FLASH_BROWSER] == [NSNumber numberWithBool:YES]) {
         [Yozio doCookieTracking:urlParams];
       }
       NSDictionary *referrerLinkTags = [yozioProperties objectForKey:YOZIO_REFERRER_LINK_TAGS];
       
       if (instance._configureCallback && referrerLinkTags) {
         instance._configureCallback(referrerLinkTags);
       }
     }
     [Yozio log:@"Opened App complete"];
   }];
}

+ (void)doCookieTracking:(NSDictionary *)urlParams
{
  NSString *urlString = [NSString stringWithFormat:@"%@%@", YOZIO_DEFAULT_BASE_URL, YOZIO_LAUNCH_APP];
  
  NSURL *url = [NSURL URLWithString:urlString];
  url = [YSeriously url:url params:urlParams];
  if (![[UIApplication sharedApplication] openURL:url])
  {
    NSLog(@"%@%@",@"Failed to open url:",[url description]);
  }
}

+ (void)addIfNotNil:(NSMutableDictionary*)dict key:(NSString *)key obj:(NSObject *)obj
{
  if (obj == nil) {
    return;
  } else {
    @synchronized(self) {
      [dict setObject:obj forKey:key];
    }
  }
}

+ (void)initializeExperimentsHelper:(NSInteger)timeOut callback:(void(^)(void))callback
{
  if (![instance validateConfiguration]) {
    return;
  }
  NSDictionary *urlParams =
  [NSDictionary dictionaryWithObjectsAndKeys:
   instance._appKey, YOZIO_GET_CONFIGURATION_P_APP_KEY,
   instance.deviceId, YOZIO_GET_CONFIGURATION_P_YOZIO_UDID,
   YOZIO_DEVICE_TYPE_IOS, YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE, nil];
  
  NSString *urlString =
  [NSString stringWithFormat:@"%@%@", YOZIO_DEFAULT_BASE_URL, YOZIO_GET_CONFIGURATIONS_ROUTE];
  
  [Yozio log:@"Final configuration request url: %@", urlString];
  
  // Use this device identifier to force a variation in the UI to a specific device.
  NSLog(@"Yozio Device Identifier: %@", instance.deviceId);
  
  [[YozioRequestManager sharedInstance] urlRequest:urlString
                                              body:urlParams
                                           timeOut:timeOut
                                           handler:^(id body, NSHTTPURLResponse *response, NSError *error)
  {
    if (error) {
     [Yozio log:@"initializeExperiments error %@", error];
    } else {
     if ([response statusCode] == 200 && [body isKindOfClass:[NSDictionary class]]) {
       [Yozio log:@"config before update: %@", instance.experimentConfig];
       NSMutableDictionary *experimentConfig = [body objectForKey:YOZIO_CONFIG_KEY];
       NSMutableDictionary *experimentDetails = [body objectForKey:YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY];
       if (experimentConfig && [experimentConfig isKindOfClass:[NSDictionary class]] &&
           experimentDetails && [experimentDetails isKindOfClass:[NSDictionary class]]) {
         instance.experimentConfig = experimentConfig;
         instance.experimentVariationSids = experimentDetails;
       }
       [Yozio log:@"config after update: %@", instance.experimentConfig];
     }
    }
    if (callback){
      callback();
    }
  }];
}

+ (NSString *)getYozioLinkHelper:(NSString *)viralLoopName
                         channel:(NSString *)channel
                  destinationUrl:(NSString *)destinationUrl
                      properties:(NSDictionary *)properties
                         timeOut:(NSInteger)timeOut
                        callback:(void(^)(NSString *))callback
{
  @try {
    if (!destinationUrl) {
      return nil;
    }
    if (!viralLoopName) {
      return destinationUrl;
    }

    NSMutableDictionary *urlParams =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
        instance._appKey, YOZIO_GET_CONFIGURATION_P_APP_KEY,
        instance.deviceId, YOZIO_GET_CONFIGURATION_P_YOZIO_UDID,
        YOZIO_DEVICE_TYPE_IOS, YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE,
        viralLoopName, YOZIO_GET_URL_P_LINK_NAME,
        destinationUrl, YOZIO_GET_URL_P_DEST_URL, nil];

    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (instance.experimentVariationSids && [instance.experimentVariationSids count] > 0) {
      [d setObject:instance.experimentVariationSids forKey:YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY];
    }
    if (channel) {
      [d setObject:channel forKey:YOZIO_GET_URL_P_CHANNEL];
    }
    [self addIfNotNil:urlParams
                  key:YOZIO_GET_URL_P_YOZIO_PROPERTIES
                  obj:[d JSONString]];

    if (properties && [properties count] > 0) {
      [self addIfNotNil:urlParams
                    key:YOZIO_P_EXTERNAL_PROPERTIES
                    obj:[properties JSONString]];
    }
    
    return [instance getYozioLinkRequest:urlParams destUrl:destinationUrl timeOut:timeOut callback:callback];
  }
  @catch (NSException * e) {
    return destinationUrl;
  }
}

+ (NSString *)getYozioLinkHelper:(NSString *)viralLoopName
                         channel:(NSString *)channel
               iosDestinationUrl:(NSString *)iosDestinationUrl
           androidDestinationUrl:(NSString *)androidDestinationUrl
         nonMobileDestinationUrl:(NSString *)nonMobileDestinationUrl
                      properties:(NSDictionary *)properties
                         timeOut:(NSInteger)timeOut
                        callback:(void (^)(NSString *))callback
{
  @try {
    if (!nonMobileDestinationUrl) {
      return nil;
    }
    if (!viralLoopName) {
      return nonMobileDestinationUrl;
    }
    
    NSMutableDictionary *urlParams =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
       instance._appKey, YOZIO_GET_CONFIGURATION_P_APP_KEY,
       instance.deviceId, YOZIO_GET_CONFIGURATION_P_YOZIO_UDID,
       YOZIO_DEVICE_TYPE_IOS, YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE,
       viralLoopName, YOZIO_GET_URL_P_LINK_NAME,
       iosDestinationUrl, YOZIO_GET_URL_P_IOS_DEST_URL,
       androidDestinationUrl, YOZIO_GET_URL_P_ANDROID_DEST_URL,
       nonMobileDestinationUrl, YOZIO_GET_URL_P_NON_MOBILE_DEST_URL, nil];

    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (instance.experimentVariationSids && [instance.experimentVariationSids count] > 0) {
      [d setObject:instance.experimentVariationSids forKey:YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY];
    }
    if (channel) {
      [d setObject:channel forKey:YOZIO_GET_URL_P_CHANNEL];
    }
    [self addIfNotNil:urlParams
                  key:YOZIO_GET_URL_P_YOZIO_PROPERTIES
                  obj:[d JSONString]];

    if (properties && [properties count] > 0) {
      [self addIfNotNil:urlParams
                    key:YOZIO_P_EXTERNAL_PROPERTIES
                    obj:[properties JSONString]];
    }
    return [instance getYozioLinkRequest:urlParams destUrl:nonMobileDestinationUrl timeOut:timeOut callback:callback];
  }
  @catch (NSException * e) {
    return nonMobileDestinationUrl;
  }
}


- (NSString *)getYozioLinkRequest:(NSDictionary *)urlParams
                          destUrl:(NSString *)destUrl
                          timeOut:(NSInteger)timeOut
                         callback:(void(^)(NSString *))callback
{
  NSString *urlString = [NSString stringWithFormat:@"%@%@", YOZIO_DEFAULT_BASE_URL, YOZIO_GET_URL_ROUTE];
  [Yozio log:@"Final getUrl Request URL: %@", urlString];
  [Yozio log:@"Final getUrl Request Params: %@", urlParams];
  
  __block NSMutableString *yozioUrl = [NSMutableString string];
  [destUrl retain];
  [yozioUrl retain];
  [[YozioRequestManager sharedInstance] urlRequest:urlString body:urlParams timeOut:timeOut handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
    if (error) {
      [Yozio log:@"getYozioLink error %@", error];
    } else {
      if ([response statusCode] == 200 && [body isKindOfClass:[NSDictionary class]]) {
        if ([body objectForKey:@"url"]) {
          [yozioUrl setString:[body objectForKey:@"url"]];
        }
      }
    }
    if (callback) {
      if ([yozioUrl length] == 0) {
        callback(destUrl);
      } else {
        callback(yozioUrl);
      }
    }
    [destUrl autorelease];
    [yozioUrl autorelease];
  }];
  
  if ([yozioUrl length] == 0) {
    return destUrl;
  } else {
    return yozioUrl;
  }
}

- (void)checkDataQueueSize
{
  [Yozio log:@"data queue size: %i",[self.dataQueue count]];
  // Only try to flush when the dataCount is a multiple of YOZIO_FLUSH_DATA_COUNT.
  // Use self.dataCount instead of dataQueue length because the dataQueue length can be capped.
  if (self.dataCount > 0 && self.dataCount % YOZIO_FLUSH_DATA_COUNT == 0) {
    [self doFlush];
  }
}
- (void)doFlush
{
  if ([self.dataQueue count] == 0) {
    [Yozio log:@"No data to flush."];
    return;
  }
  if (self.dataToSend != nil) {
    [Yozio log:@"Already flushing"];
    return;
  }
  if ([self.dataQueue count] > YOZIO_FLUSH_DATA_SIZE) {
    self.dataToSend = [self.dataQueue subarrayWithRange:NSMakeRange(0, YOZIO_FLUSH_DATA_SIZE)];
  } else {
    self.dataToSend = [NSArray arrayWithArray:self.dataQueue];
  }
  NSString *payloadStr = [[self buildPayload:self.dataToSend] JSONString];
  NSDictionary *urlParams = [NSDictionary dictionaryWithObject:payloadStr
                                                        forKey:YOZIO_BATCH_EVENTS_P_DATA];
  NSString *urlString = [NSString stringWithFormat:@"%@%@", YOZIO_DEFAULT_BASE_URL, YOZIO_BATCH_EVENTS_ROUTE];
  [Yozio log:@"Final get request url: %@", urlString];
  [[YozioRequestManager sharedInstance] urlRequest:urlString
                                              body:urlParams
                                           timeOut:0
                                           handler:^(id body, NSHTTPURLResponse *response, NSError *error)
   {
     if (error) {
       [Yozio log:@"Flush error %@", error];
       self.dataToSend = nil;
     } else {
       if (([response statusCode] == 200 || [response statusCode] == 400) && [body isKindOfClass:[NSDictionary class]]) {
         [Yozio log:@"dataQueue before remove: %@", self.dataQueue];
         [self.dataQueue removeObjectsInArray:self.dataToSend];
         [Yozio log:@"dataQueue after remove: %@", self.dataQueue];
         [Yozio log:@"flush successful. flushing any additional data"];
         self.dataToSend = nil;
         [self checkDataQueueSize];
       }
       else {
         self.dataToSend = nil;
       }
     }
     [Yozio log:@"flush request complete"];
   }];
}

- (NSDictionary *)buildPayload:(NSArray *)dataPayload
{
  NSMutableDictionary* payload = [NSMutableDictionary dictionary];
  [payload setObject:self._appKey forKey:YOZIO_P_APP_KEY];
  [Yozio addIfNotNil:payload key:YOZIO_P_USER_NAME obj:self._userName];
  [Yozio addIfNotNil:payload key:YOZIO_P_YOZIO_UDID obj:self.deviceId];
  [Yozio addIfNotNil:payload key:YOZIO_P_DEVICE_TYPE obj:YOZIO_DEVICE_TYPE_IOS];
  [Yozio addIfNotNil:payload key:YOZIO_P_MAC_ADDRESS obj:[Yozio getMACAddress]];
  [Yozio addIfNotNil:payload key:YOZIO_P_OPEN_UDID obj:[YOpenUDID value]];
  [Yozio addIfNotNil:payload
                 key:YOZIO_P_OPEN_UDID_COUNT
                 obj:[NSString stringWithFormat:@"%d", [YOpenUDID getOpenUDIDSlotCount]]];
  [Yozio addIfNotNil:payload key:YOZIO_P_OS_VERSION obj:self.osVersion];
  [Yozio addIfNotNil:payload key:YOZIO_P_COUNTRY_CODE obj:self.countryCode];
  [Yozio addIfNotNil:payload key:YOZIO_P_LANGUAGE_CODE obj:self.languageCode];
  [Yozio addIfNotNil:payload key:YOZIO_P_IS_JAILBROKEN obj:[self isJailBrokenStr]];
  [Yozio addIfNotNil:payload key:YOZIO_P_DISPLAY_MULTIPLIER obj:[NSString stringWithFormat:@"%f", 1.0f]];
  [Yozio addIfNotNil:payload key:YOZIO_P_HARDWARE obj:self.hardware];
  [Yozio addIfNotNil:payload key:YOZIO_P_APP_VERSION obj:[Yozio bundleVersion]];
  [Yozio addIfNotNil:payload
                 key:YOZIO_P_EXPERIMENT_VARIATION_SIDS
                 obj:instance.experimentVariationSids];
  
  [payload setObject:dataPayload forKey:YOZIO_P_PAYLOAD];
  return payload;
}

/*******************************************
 * Instrumentation data helper methods.
 *******************************************/

- (NSString*)eventID
{
  CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
  NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
  CFRelease(uuidObject);
  return uuidStr;
}

- (void)updateCountryName
{
  NSLocale *locale = [NSLocale currentLocale];
  self.countryCode = [locale displayNameForKey:NSLocaleCountryCode value:[locale objectForKey: NSLocaleCountryCode]];
}

- (void)updateLanguage
{
  self.languageCode = [[NSLocale preferredLanguages] objectAtIndex:0];
}

static const char* jailbreak_apps[] =
{
  "/bin/bash",
  "/Applications/Cydia.app",
  "/Applications/limera1n.app",
  "/Applications/greenpois0n.app",
  "/Applications/blackra1n.app",
  "/Applications/blacksn0w.app",
  "/Applications/redsn0w.app",
  NULL,
};

- (BOOL)isJailBroken
{
#if TARGET_IPHONE_SIMULATOR
  return NO;
#endif
  
  // Check for known jailbreak apps. If we encounter one, the device is jailbroken.
  for (int i = 0; jailbreak_apps[i] != NULL; ++i)
  {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithUTF8String:jailbreak_apps[i]]])
    {
      return YES;
    }
  }
  
  return NO;
}

- (NSString*)isJailBrokenStr
{
  if ([self isJailBroken])
  {
    return @"1";
  }
  
  return @"0";
}

+ (NSString*)bundleVersion
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

+ (NSString*)getMACAddress
{
  int                 mib[6];
  size_t              len;
  char                *buf;
  unsigned char       *ptr;
  struct if_msghdr    *ifm;
  struct sockaddr_dl  *sdl;
  
  mib[0] = CTL_NET;
  mib[1] = AF_ROUTE;
  mib[2] = 0;
  mib[3] = AF_LINK;
  mib[4] = NET_RT_IFLIST;
  
  if ((mib[5] = if_nametoindex("en0")) == 0)
  {
    return NULL;
  }
  
  if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
  {
    return NULL;
  }
  
  if ((buf = malloc(len)) == NULL)
  {
    free(buf);
    return NULL;
  }
  
  if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
  {
    free(buf);
    return NULL;
  }
  
  ifm = (struct if_msghdr *)buf;
  sdl = (struct sockaddr_dl *)(ifm + 1);
  ptr = (unsigned char *)LLADDR(sdl);
  NSString *macAddress = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X",
                          *ptr, *(ptr+1), *(ptr+2), *(ptr+3), *(ptr+4), *(ptr+5)];
  macAddress = [macAddress lowercaseString];
  free(buf);
  
  return macAddress;
}

- (NSString *)timeStampString
{
  NSTimeZone *utc = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
  NSDateFormatter *tmpDateFormatter = [[NSDateFormatter alloc] init];
  self.dateFormatter = tmpDateFormatter;
  [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
  [tmpDateFormatter release];
  [self.dateFormatter setTimeZone:utc];
  NSString *timeStamp = [self.dateFormatter stringFromDate:[NSDate date]];
  return timeStamp;
}

/*******************************************
 * File system helper methods.
 *******************************************/

- (void)saveUnsentData
{
  [Yozio log:@"saveUnsentData: %@", self.dataQueue];
  if (![NSKeyedArchiver archiveRootObject:self.dataQueue toFile:YOZIO_DATA_QUEUE_FILE]) {
    [Yozio log:@"Unable to archive dataQueue!"];
  }
}

- (void)loadUnsentData
{
  if ([[NSFileManager defaultManager] fileExistsAtPath: YOZIO_DATA_QUEUE_FILE]) {
    self.dataQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:YOZIO_DATA_QUEUE_FILE];
    if (self.dataQueue == nil)  {
      self.dataQueue = [NSMutableArray array];
    }
  }
  [Yozio log:@"loadUnsentData: %@", self.dataQueue];
}


/*******************************************
 * Configuration helper methods.
 *******************************************/

- (void)dealloc
{
  [_appKey release], _appKey = nil;
  [_secretKey release], _secretKey = nil;
  [self._configureCallback release], self._configureCallback = nil;
  [_userName release], _userName = nil;
  [deviceId release], deviceId = nil;
  [dateFormatter release], dateFormatter = nil;
  [dataQueue release], dataQueue = nil;
  [super dealloc];
}

@end
