//
//  Copyright 2011 Yozio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JSONKit.h"
#import "Seriously.h"
#import "SFHFKeychainUtils.h"
#import "UncaughtExceptionHandler.h"
#import "Yozio_Private.h"


@implementation Yozio

@synthesize _serverUrl;
@synthesize _userId;
@synthesize _env;
@synthesize _appVersion;
@synthesize deviceId;
@synthesize hardware;
@synthesize os;
@synthesize sessionId;
@synthesize schemaVersion;
@synthesize experimentsStr;
@synthesize flushTimer;
@synthesize dataQueue;
@synthesize dataToSend;
@synthesize dataCount;
@synthesize timers;
@synthesize config;
@synthesize dateFormatter;


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

+ (void)configure:(NSString *)serverUrl
    userId:(NSString *)userId
    env:(NSString *)env
    appVersion:(NSString *)appVersion
    exceptionHandler:(NSUncaughtExceptionHandler *)exceptionHandler
{
  instance._serverUrl = serverUrl;
  instance._userId = userId;
  instance._env = env;
  instance._appVersion = appVersion;
  
  UIDevice* device = [UIDevice currentDevice];
  instance.hardware = device.model;
  instance.os = [device systemVersion];
  instance.schemaVersion = @"";
  instance.flushTimer = [NSTimer scheduledTimerWithTimeInterval:FLUSH_INTERVAL_SEC
                                                         target:instance
                                                       selector:@selector(doFlush)
                                                       userInfo:nil
                                                        repeats:YES];
  instance.dataQueue = [NSMutableArray array];
  instance.dataCount = 0;
  instance.timers = [NSMutableDictionary dictionary];
  
  // Initialize dateFormatter.
  NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  NSDateFormatter *tmpDateFormatter = [[NSDateFormatter alloc] init];
  instance.dateFormatter = tmpDateFormatter;
  [instance.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss SSS"];
  [instance.dateFormatter setTimeZone:gmt];
  [tmpDateFormatter release];
  
  // Initialize device id.
  [instance loadOrCreateDeviceId];
  
  // Initialize config map. Must be called after loadOrCreateDeviceId.
  [instance updateConfig];
  
  // Load any previous data and try to flush it.
  // Perform this here instead of on applicationDidFinishLoading because instrumentation calls
  // could be made before an applciation is finished loading.
  [instance loadUnsentData];
  [instance doFlush];
  
  // Start new session.
  instance.sessionId = [instance makeUUID];
  
  // Instrument uncaught exceptions and signals.
  InstallUncaughtExceptionHandler(exceptionHandler);
  
  // Add notification observers.
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self
                         selector:@selector(onApplicationWillTerminate:)
                             name:UIApplicationWillTerminateNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(onApplicationDidBecomeActive:)
                             name:UIApplicationDidBecomeActiveNotification
                           object:nil];
  [notificationCenter addObserver:self
                         selector:@selector(onApplicationWillResignActive:)
                             name:UIApplicationWillResignActiveNotification
                           object:nil];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_4_0
  if ([[UIDevice currentDevice] respondsToSelector:@selector(isMultitaskingSupported)]) {
    [notificationCenter addObserver:self
                           selector:@selector(onApplicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(onApplicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
  }
#endif
}

+ (void)startTimer:(NSString *)timerName
{
  [instance.timers setValue:[NSDate date] forKey:timerName];
}

+ (void)endTimer:(NSString *)timerName category:(NSString *)category
{
  NSDate *startTime = [instance.timers valueForKey:timerName];
  if (startTime == NULL) {
    // We don't want developers to get away with bad instrumentation code, so raise an
    // exception and force them to deal with it.
    [NSException raise:@"Invalid timerName" format:@"timerName %@ is invalid", timerName];
  } else {
    [instance.timers removeObjectForKey:timerName];
    float elapsedTime = [[NSDate date] timeIntervalSinceDate:startTime];
    NSString *elapsedTimeStr = [NSString stringWithFormat:@"%.2f", elapsedTime];
    [instance collect:T_TIMER
                  key:timerName
                value:elapsedTimeStr
             category:category
             maxQueue:TIMER_DATA_LIMIT];
  }
}

+ (void)funnel:(NSString *)funnelName value:(NSString *)value category:(NSString *)category
{
  [instance collect:T_FUNNEL
                key:funnelName
              value:value
           category:category
           maxQueue:FUNNEL_DATA_LIMIT];
}

+ (void)revenue:(NSString *)itemName cost:(double)cost category:(NSString *)category
{
  NSString *stringCost = [NSString stringWithFormat:@"%d", cost];
  [instance collect:T_REVENUE
                key:itemName
              value:stringCost
           category:category
           maxQueue:REVENUE_DATA_LIMIT];
}

+ (void)action:(NSString *)actionName context:(NSString *)context category:(NSString *)category
{
  [instance collect:T_ACTION
                key:context
              value:actionName
           category:category
           maxQueue:ACTION_DATA_LIMIT];
}

+ (void)error:(NSString *)errorName message:(NSString *)message category:(NSString *)category
{
  [instance collect:T_ERROR
                key:errorName
              value:message
           category:category
           maxQueue:ERROR_DATA_LIMIT];
}

+ (void)exception:(NSException *)exception category:(NSString *)category
{
  [Yozio error:[exception name]
       message:[exception reason]
      category:category];
}

+ (void)collect:(NSString *)key value:(NSString *)value category:(NSString *)category
{
  [instance collect:T_COLLECT
                key:key
              value:value
           category:category
           maxQueue:COLLECT_DATA_LIMIT];
}

+ (void)flush
{
  [instance doFlush];
}

+ (NSString *)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
  NSString *val = [instance.config objectForKey:key];
  if (val == NULL) {
    return defaultValue;
  }
  return val;
}

+ (NSInteger)intForKey:(NSString *)key defaultValue:(NSInteger)defaultValue
{
  NSNumber *num = [instance.config objectForKey:key];
  if (num == NULL) {
    return defaultValue;
  }
  return [num integerValue];
}


/*******************************************
 * Notification observer methods.
 *******************************************/

- (void)onApplicationWillTerminate:(NSNotification *)notification
{
  [self saveState];
}

- (void)onApplicationDidBecomeActive:(NSNotification *)notification
{
}

- (void)onApplicationWillResignActive:(NSNotification *)notification
{
}

- (void)onApplicationWillEnterForeground:(NSNotification *)notification
{
  // TODO(jt): start new session here?
}

- (void)onApplicationDidEnterBackground:(NSNotification *)notification
{
  // TODO(jt): flush data in background task
}

// TODO(jt): listen to memory warnings and significant time change?
// http://developer.apple.com/library/ios/#documentation/uikit/reference/UIApplicationDelegate_Protocol/Reference/Reference.html


/*******************************************
 * Application state related helper methods.
 *******************************************/

- (void)saveState
{
  [self saveUnsentData];
}


/*******************************************
 * Data collection helper methods.
 *******************************************/

- (void)collect:(NSString *)type
            key:(NSString *)key
          value:(NSString *)value
       category:(NSString *)category
       maxQueue:(NSInteger)maxQueue
{
  // Increment dataCount even if we don't add to data queue so we know how much data we missed.
  dataCount++;
  if ([self.dataQueue count] < maxQueue) {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  type, D_TYPE,
                                  key, D_KEY,
                                  value, D_VALUE,
                                  category, D_CATEGORY,
                                  [self deviceOrientation], D_DEVICE_ORIENTATION,
                                  [self uiOrientation], D_UI_ORIENTATION,
                                  self._userId, D_USER_ID,
                                  self._appVersion, D_APP_VERSION,
                                  self.sessionId, D_SESSION_ID,
                                  self.experimentsStr, D_EXPERIMENTS,
                                  [self timeStampString], D_TIMESTAMP,
                                  [NSNumber numberWithInteger:dataCount], D_ID,
                                  nil];
    [self.dataQueue addObject:d];
    [Yozio log:@"collect: %@", d];
  }
  [self checkDataQueueSize];
}

- (void)checkDataQueueSize
{
  [Yozio log:@"data queue size: %i",[self.dataQueue count]];
  if ([self.dataQueue count] > 0 && [self.dataQueue count] % FLUSH_DATA_COUNT == 0) {
    [self doFlush]; 
  }
}

- (void)doFlush
{
  if ([self.dataQueue count] == 0) {
    [Yozio log:@"No data to flush."];
    return;
  } else if (self.dataToSend != NULL) {
    [Yozio log:@"Already flushing"];
    return;
  }
  if ([self.dataQueue count] > FLUSH_DATA_COUNT) {
    self.dataToSend = [self.dataQueue subarrayWithRange:NSMakeRange(0, FLUSH_DATA_COUNT)];
  } else {
    self.dataToSend = [NSArray arrayWithArray:self.dataQueue];
  }
  [Yozio log:@"Flushing..."];
  NSString *dataStr = [self buildPayload];
  NSString *urlParams = [NSString stringWithFormat:@"data=%@", dataStr];
  NSString *escapedUrlParams =
      [urlParams stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
  // TODO(jt): should make a request to a resource, instead of root url.
  NSString *urlString = [NSString stringWithFormat:@"%@/%@", self._serverUrl, escapedUrlParams];
  [Yozio log:@"Final get request url: %@", urlString];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [Seriously get:urlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
    if (error) {
      [Yozio log:@"Flush error %@", error];
    } else {
      if ([response statusCode] == 200) {
        [Yozio log:@"Before remove: %@", self.dataQueue];
        [self.dataQueue removeObjectsInArray:self.dataToSend];
        [Yozio log:@"After remove: %@", self.dataQueue];
        // TODO(jt): stop background task if running in background
      }
    }
    [Yozio log:@"flush request complete"];
    self.dataToSend = NULL;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
}

- (NSString *)buildPayload
{
  // TODO(jt): compute real digest from shared key
  NSString *digest = @"";
  NSLocale *locale = [NSLocale currentLocale];
  NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
  NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
  // TODO(jt): cache timezone calculation (assume users will be in same time zone for each session)
  [NSTimeZone resetSystemTimeZone];
  NSInteger timezoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMT]/3600;
  NSNumber *timezone = [NSNumber numberWithInteger:timezoneOffset];
  
  NSMutableDictionary* payload = [NSMutableDictionary dictionary];
  [payload setValue:digest forKey:P_DIGEST];
  [payload setValue:self._env forKey:P_ENVIRONMENT];
  [payload setValue:[self loadOrCreateDeviceId] forKey:P_DEVICE_ID];
  [payload setValue:self.hardware forKey:P_HARDWARE];
  [payload setValue:self.os forKey:P_OPERATING_SYSTEM];
  [payload setValue:self.schemaVersion forKey:P_SCHEMA_VERSION];
  [payload setValue:countryName forKey:P_COUNTRY];
  // TODO(jt): cache language
  [payload setValue:[[NSLocale preferredLanguages] objectAtIndex:0] forKey:P_LANGUAGE];
  [payload setValue:timezone forKey:P_TIMEZONE];
  [payload setValue:[NSNumber numberWithInteger:[self.dataToSend count]] forKey:P_COUNT];
  [payload setValue:self.dataToSend forKey:P_PAYLOAD];
  
  [Yozio log:@"payload: %@", payload];
  return [payload JSONString];
}

- (NSString *)timeStampString
{
  NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
  return timeStamp;
}

- (void)saveUnsentData
{
  [Yozio log:@"saveUnsentData: %@", self.dataQueue];
  if (![NSKeyedArchiver archiveRootObject:self.dataQueue toFile:DATA_QUEUE_FILE]) {
    [Yozio log:@"Unable to archive data!"];
  }
}

- (void)loadUnsentData
{
  self.dataQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:DATA_QUEUE_FILE];
  if (!self.dataQueue)  {
    self.dataQueue = [NSMutableArray array];    
  }
  [Yozio log:@"loadUnsentData: %@", self.dataQueue];
}

/**
 * Loads the deviceId from keychain. If one doesn't exist, create a new deviceId, store it in the
 * keychain, and return the new deviceId.
 *
 * @return The deviceId or nil if any error occurred while loading/creating/storing the UUID.
 */
- (NSString *)loadOrCreateDeviceId
{
  if (self.deviceId != nil) {
    return self.deviceId;
  }
  
  NSError *loadError = nil;
  NSString *uuid = [SFHFKeychainUtils getPasswordForUsername:UUID_KEYCHAIN_USERNAME
                                              andServiceName:KEYCHAIN_SERVICE
                                                       error:&loadError];
  NSInteger loadErrorCode = [loadError code];
  if (loadErrorCode == errSecItemNotFound || uuid == nil) {
    // No deviceId stored in keychain yet.
    uuid = [self makeUUID];
    [Yozio log:@"Generated device id: %@", uuid];
    if (![self storeDeviceId:uuid]) {
      return nil;
    }
  } else if (loadErrorCode != errSecSuccess) {
    [Yozio log:@"Error loading UUID from keychain."];
    [Yozio log:@"%@", [loadError localizedDescription]];
    return nil;
  }
  self.deviceId = uuid;
  return self.deviceId;
}

- (BOOL)storeDeviceId:(NSString *)uuid
{
  NSError *storeError = nil;
  [SFHFKeychainUtils storeUsername:UUID_KEYCHAIN_USERNAME
                       andPassword:uuid
                    forServiceName:KEYCHAIN_SERVICE
                    updateExisting:true
                             error:&storeError];
  if ([storeError code] != errSecSuccess) {
    [Yozio log:@"Error storing UUID to keychain."];
    [Yozio log:@"%@", [storeError localizedDescription]];
    return NO;
  }
  return YES;
}

// Code taken from http://www.jayfuerstenberg.com/blog/overcoming-udid-deprecation-by-using-guids
- (NSString *)makeUUID
{
  CFUUIDRef theUUID = CFUUIDCreate(NULL);
  NSString *uuidString = (NSString *) CFUUIDCreateString(NULL, theUUID);
  CFRelease(theUUID);
  [uuidString autorelease];
  return uuidString;
}

- (NSString*)deviceOrientation {
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  switch(orientation) {
    case UIDeviceOrientationPortrait:
      return ORIENT_PORTRAIT;
    case UIDeviceOrientationPortraitUpsideDown:
      return ORIENT_PORTRAIT_UPSIDE_DOWN;
    case UIDeviceOrientationLandscapeLeft:
      return ORIENT_LANDSCAPE_LEFT;
    case UIDeviceOrientationLandscapeRight:
      return ORIENT_LANDSCAPE_RIGHT;
    case UIDeviceOrientationFaceUp:
      return ORIENT_FACE_UP;
    case UIDeviceOrientationFaceDown:
      return ORIENT_FACE_DOWN;
    default:
      return ORIENT_UNKNOWN;
  }
}

- (NSString *)uiOrientation
{
  UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
  switch (orientation) {
    case UIInterfaceOrientationPortrait:
      return ORIENT_PORTRAIT;
    case UIInterfaceOrientationPortraitUpsideDown:
      return ORIENT_PORTRAIT_UPSIDE_DOWN;
    case UIInterfaceOrientationLandscapeLeft:
      return ORIENT_LANDSCAPE_LEFT;
    case UIInterfaceOrientationLandscapeRight:
      return ORIENT_LANDSCAPE_RIGHT;
    default:
      return ORIENT_UNKNOWN;
  }
}


/*******************************************
 * Configuration related helper methods.
 *******************************************/

/**
 * Update self.config and self.experimentsStr with data from server.
 */
- (void)updateConfig
{
  if (self.deviceId == NULL) {
    [Yozio log:@"updateConfig NULL deviceId"];
    return;
  }
  NSString *urlParams = [NSString stringWithFormat:@"deviceId=%@", self.deviceId];
  NSString *urlString =
      [NSString stringWithFormat:@"%@/%@?%@", self._serverUrl, @"configuration", urlParams];
  [Yozio log:@"Final configuration request url: %@", urlString];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [Seriously get:urlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
    if (error) {
      [Yozio log:@"updateConfig error %@", error];
    } else {
      if ([response statusCode] == 200) {
        [Yozio log:@"config before update: %@", self.config];
        self.config = [body objectForKey:CONFIG_CONFIG];
        self.experimentsStr = [body objectForKey:CONFIG_EXPERIMENTS];
        [Yozio log:@"config after update: %@", self.config];
      }
    }
    [Yozio log:@"configuration request complete"];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    // TODO(jt): stop background task if running in background
  }];
}

@end
