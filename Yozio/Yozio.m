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
#import "NSString+MD5.h"
#import "YJSONKit.h"
#import "YSeriously.h"
#import "YOpenUDID.h"
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
@synthesize urlConfig;
@synthesize experimentConfig;
@synthesize eventSuperProperties;
@synthesize linkSuperProperties;
@synthesize stopBlocking;

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
  self.urlConfig = [NSMutableDictionary dictionary];
  self.experimentConfig = [NSMutableDictionary dictionary];
  self.eventSuperProperties = [NSMutableDictionary dictionary];
  self.linkSuperProperties = [NSMutableDictionary dictionary];

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
  if (appKey == nil) {
    [NSException raise:NSInvalidArgumentException format:@"appKey cannot be nil."];
  }
  if (secretKey == nil) {
    [NSException raise:NSInvalidArgumentException format:@"secretKey cannot be nil."];
  }
  instance._appKey = appKey;
  instance._secretKey = secretKey;
  if (![instance validateConfiguration]) {
    return;
  }

  // Load any previous data.
  // Perform this here instead of on applicationDidFinishLoading because instrumentation calls
  // could be made before an application is finished loading.
  [instance loadUnsentData];
  [Yozio openedApp];
  [instance doFlush];
}

+ (void)userLoggedIn:(NSString *)userName
{
  [instance updateUserName:userName];
  [instance doCollect:YOZIO_LOGIN_ACTION
             linkName:@""
             maxQueue:YOZIO_ACTION_DATA_LIMIT];
}

+ (void)initializeExperiments
{
  if (![instance validateConfiguration]) {
    return;
  }
  NSMutableString *urlParams =
  [NSMutableString stringWithFormat:@"%@=%@&%@=%@&%@=%@",
   YOZIO_GET_CONFIGURATION_P_APP_KEY, [Yozio encodeToPercentEscapeString:instance._appKey],
   YOZIO_GET_CONFIGURATION_P_YOZIO_UDID, [Yozio encodeToPercentEscapeString:instance.deviceId],
   YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE, [Yozio encodeToPercentEscapeString:YOZIO_DEVICE_TYPE_IOS]];

  NSString *urlString =
  [NSString stringWithFormat:@"%@%@?%@", YOZIO_DEFAULT_BASE_URL, YOZIO_GET_CONFIGURATIONS_ROUTE, urlParams];

  [Yozio log:@"Final configuration request url: %@", urlString];

  // Use this device identifier to force a variation in the UI to a specific device.
  NSLog(@"Yozio Device Identifier: %@", instance.deviceId);

  // Blocking
  instance.stopBlocking = false;
  [NSTimer scheduledTimerWithTimeInterval:5 target:instance selector:@selector(stopBlockingApp) userInfo:nil repeats:NO];
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [YSeriously get:urlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
    if (error) {
      [Yozio log:@"initializeExperiments error %@", error];
    } else {
      if ([response statusCode] == 200) {
        [Yozio log:@"config before update: %@", instance.experimentConfig];

        instance.experimentConfig = [body objectForKey:YOZIO_CONFIG_KEY];
        NSDictionary *experimentDetails = [body objectForKey:YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY];
        if([experimentDetails count] > 0) {
          [Yozio log:@"event super properties before update: %@", instance.eventSuperProperties];
          [Yozio log:@"link super properties before update: %@", instance.linkSuperProperties];
          [instance.eventSuperProperties setObject:experimentDetails forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS];
          [instance.linkSuperProperties setObject:experimentDetails forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS];
          [Yozio log:@"event super properties after update: %@", instance.eventSuperProperties];
          [Yozio log:@"link super properties after update: %@", instance.linkSuperProperties];
        }
        [Yozio log:@"config after update: %@", instance.experimentConfig];
      }
    }
    [instance stopBlockingApp];
    [Yozio log:@"configuration request complete"];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    // TODO(jt): stop background task if running in background
  }];

  NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
  while (!instance.stopBlocking && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil]) {
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.5];
  }
}

+ (NSString*)stringForKey:(NSString *)key defaultValue:(NSString *) defaultValue;
{
  if (instance.experimentConfig == nil) {
    return defaultValue;
  }
  NSString *val = [instance.experimentConfig objectForKey:key];
  return val != nil ? val : defaultValue;
}

+ (NSInteger)intForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
{
  if (instance.experimentConfig == nil) {
    return defaultValue;
  }
  NSString *val = [instance.experimentConfig objectForKey:key];
  if(val == nil) {
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

+ (NSString *)getUrl:(NSString *)linkName destinationUrl:(NSString *)destinationUrl
{
  if (instance.urlConfig == nil) {
    instance.urlConfig = [NSMutableDictionary dictionary];
  }
  NSString *urlKey = [NSString stringWithFormat:@"%@-%@",
                      destinationUrl,
                      [instance.linkSuperProperties JSONString]];
  NSString *val = [instance.urlConfig objectForKey:urlKey];
  if (val != nil) {
    return val;
  }
  else {
    NSMutableString *urlParams =
    [NSMutableString stringWithFormat:@"%@=%@&%@=%@&%@=%@&%@=%@&%@=%@",
     YOZIO_GET_CONFIGURATION_P_APP_KEY, [Yozio encodeToPercentEscapeString:instance._appKey],
     YOZIO_GET_CONFIGURATION_P_YOZIO_UDID, [Yozio encodeToPercentEscapeString:instance.deviceId],
     YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE, [Yozio encodeToPercentEscapeString:YOZIO_DEVICE_TYPE_IOS],
     YOZIO_GET_URL_P_LINK_NAME, [Yozio encodeToPercentEscapeString:linkName],
     YOZIO_GET_URL_P_DEST_URL, [Yozio encodeToPercentEscapeString:destinationUrl]];
    if ([instance.linkSuperProperties objectForKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS]) {
      [self appendParamIfNotNil:urlParams
                       paramKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS
                     paramValue:[[instance.linkSuperProperties objectForKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] JSONString]];
    }

    NSString *urlString =
    [NSString stringWithFormat:@"%@%@?%@", YOZIO_DEFAULT_BASE_URL, YOZIO_GET_URL_ROUTE, urlParams];
    [Yozio log:@"Final getUrl Request: %@", urlString];

    // Blocking
    instance.stopBlocking = false;
    [NSTimer scheduledTimerWithTimeInterval:5 target:instance selector:@selector(stopBlockingApp) userInfo:nil repeats:NO];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [YSeriously get:urlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
      if (error) {
        [Yozio log:@"getUrl error %@", error];
      } else {
        if ([response statusCode] == 200) {
          NSString *shortenedUrl = [body objectForKey:@"url"];
          [instance.urlConfig setObject:shortenedUrl forKey:urlKey];
        }
      }
      [instance stopBlockingApp];
      [Yozio log:@"getUrl request complete"];
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
    while (!instance.stopBlocking && [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:loopUntil]) {
      loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.5];
    }

    // return the short url. Return destinationUrl if it can't find the destinationUrl's short url.
    if (instance.urlConfig == nil) {
      return destinationUrl;
    }
    NSString *val = [instance.urlConfig objectForKey:urlKey];
    return val != nil ? val : destinationUrl;
  }
}

+ (void)viewedLink:(NSString *)linkName
{
  [instance doCollect:YOZIO_VIEWED_LINK_ACTION
             linkName:linkName
             maxQueue:YOZIO_ACTION_DATA_LIMIT];
}

+ (void)sharedLink:(NSString *)linkName
{
  [instance doCollect:YOZIO_SHARED_LINK_ACTION
             linkName:linkName
             maxQueue:YOZIO_ACTION_DATA_LIMIT];
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
         linkName:(NSString *)linkName
         maxQueue:(NSInteger)maxQueue
{
  if (![self validateConfiguration]) {
    return;
  }
  dataCount++;
  if ([self.dataQueue count] < maxQueue) {
    NSMutableDictionary* d = [NSMutableDictionary dictionary];
    [Yozio addIfNotNil:d key:YOZIO_D_EVENT_TYPE obj:type];
    [Yozio addIfNotNil:d key:YOZIO_D_LINK_NAME obj:linkName];
    [Yozio addIfNotNil:d key:YOZIO_D_TIMESTAMP obj:[self timeStampString]];
    [Yozio addIfNotNil:d key:YOZIO_D_EVENT_IDENTIFIER obj:[self eventID]];

    [self.dataQueue addObject:d];
    [Yozio log:@"doCollect: %@", d];
  }
  [self checkDataQueueSize];
}

+ (void)openedApp
{
  [instance doCollect:YOZIO_OPENED_APP_ACTION
             linkName:@""
             maxQueue:YOZIO_ACTION_DATA_LIMIT];
}

+ (void)addIfNotNil:(NSMutableDictionary*)dict key:(NSString *)key obj:(NSObject *)obj
{
  if (obj == nil) {
    return;
  } else {
    [dict setObject:obj forKey:key];
  }
}

// Appends "&[paramKey]=[paramValue]" to the paramString.
// The '&' is required for experiment_variation_sids when making the 'get_url' request
+ (void)appendParamIfNotNil:(NSMutableString*)paramString paramKey:(NSString*)paramKey paramValue:(NSString*)paramValue
{
  if (paramValue) {
    NSString *stringToAppend = [NSString stringWithFormat:@"&%@=%@", paramKey, [Yozio encodeToPercentEscapeString:paramValue]];
    [paramString appendString:stringToAppend];
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
  [Yozio log:@"Flushing..."];

  NSString *payloadStr = [self buildPayload];
  NSString *urlParams = [NSString stringWithFormat:@"%@=%@", YOZIO_BATCH_EVENTS_P_DATA, [Yozio encodeToPercentEscapeString:payloadStr]];
  NSString *urlString =
  [NSString stringWithFormat:@"%@%@?%@", YOZIO_DEFAULT_BASE_URL, YOZIO_BATCH_EVENTS_ROUTE, urlParams];

  [Yozio log:@"Final get request url: %@", urlString];

  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [YSeriously get:urlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
    if (error) {
      [Yozio log:@"Flush error %@", error];
      self.dataToSend = nil;
    } else {
      if ([response statusCode] == 200 || [response statusCode] == 400) {
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
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
}

- (NSString *)buildPayload
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
                 obj:[eventSuperProperties objectForKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS]];

  [payload setObject:self.dataToSend forKey:YOZIO_P_PAYLOAD];
  [Yozio log:@"payload: %@", payload];

  //  JSONify
  NSString *jsonPayload = [payload JSONString];

  return jsonPayload;
}

/*******************************************
 * Instrumentation data helper methods.
 *******************************************/

+ (NSString*)encodeToPercentEscapeString:(NSString*)string
{
  return (NSString *) CFURLCreateStringByAddingPercentEscapes(NULL,
                                                              (CFStringRef) string,
                                                              NULL,
                                                              (CFStringRef) @"!*'();:@&=+$,/?%#[]",
                                                              kCFStringEncodingUTF8);
}

- (NSString*)eventID
{
  CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
  NSString *uuidStr = [(NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuidObject) autorelease];
  CFRelease(uuidObject);
  return uuidStr;
}

- (void)updateUserName:(NSString *)userName
{
  self._userName = userName;
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
      //NSLog(@"isjailbroken: %s", jailbreak_apps[i]);
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
    NSLog(@"Error: if_nametoindex error\n");
    return NULL;
  }

  if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0)
  {
    NSLog(@"Error: sysctl, take 1\n");
    return NULL;
  }

  if ((buf = malloc(len)) == NULL)
  {
    NSLog(@"Could not allocate memory. error!\n");
    free(buf);
    return NULL;
  }

  if (sysctl(mib, 6, buf, &len, NULL, 0) < 0)
  {
    NSLog(@"Error: sysctl, take 2");
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

- (void)stopBlockingApp {
  self.stopBlocking = true;
}

- (void)dealloc
{
  [_appKey release], _appKey = nil;
  [_secretKey release], _secretKey = nil;
  [_userName release], _userName = nil;
  [deviceId release], deviceId = nil;
  [dateFormatter release], dateFormatter = nil;
  [dataQueue release], dataQueue = nil;
  [super dealloc];
}

@end
