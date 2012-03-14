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

@synthesize _appKey;
@synthesize _userId;
@synthesize _env;
@synthesize _appVersion;
@synthesize _campaignSource;
@synthesize _campaignMedium;
@synthesize _campaignTerm;
@synthesize _campaignContent;
@synthesize _campaignName;
@synthesize deviceId;
@synthesize hardware;
@synthesize os;
@synthesize sessionId;
@synthesize schemaVersion;
@synthesize countryName;
@synthesize language;
@synthesize timezone;
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
  
  UIDevice* device = [UIDevice currentDevice];
  instance.hardware = device.model;
  instance.os = [device systemVersion];
  // TODO(jt): schemaVersion
  instance.schemaVersion = @"";
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
  
  // Add notification observers.
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self
                         selector:@selector(onApplicationWillTerminate:)
                             name:UIApplicationWillTerminateNotification
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
    userId:(NSString *)userId
    env:(NSString *)env
    appVersion:(NSString *)appVersion
    campaignSource :(NSString *)campaignSource
    campaignMedium :(NSString *)campaignMedium
    campaignTerm :(NSString *)campaignTerm
    campaignContent :(NSString *)campaignContent
    campaignName :(NSString *)campaignName
    exceptionHandler:(NSUncaughtExceptionHandler *)exceptionHandler
{
  if (appKey == NULL) {
    [NSException raise:NSInvalidArgumentException format:@"appKey cannot be NULL."];
  }
  instance._appKey = appKey;
  instance._userId = userId;
  instance._env = env;
  instance._appVersion = appVersion;
  instance._campaignSource = campaignSource;
  instance._campaignMedium = campaignMedium;
  instance._campaignTerm = campaignTerm;
  instance._campaignContent = campaignContent;
  instance._campaignName = campaignName;
  InstallUncaughtExceptionHandler(exceptionHandler);
  
  [instance updateCountryName];
  [instance updateLanguage];
  [instance updateTimezone];
  [instance updateConfig];
  
  if (instance.flushTimer == NULL) {
    instance.flushTimer = [NSTimer scheduledTimerWithTimeInterval:FLUSH_INTERVAL_SEC
                                                           target:instance
                                                         selector:@selector(doFlush)
                                                         userInfo:nil
                                                          repeats:YES];
  }
  
  // Load any previous data and try to flush it.
  // Perform this here instead of on applicationDidFinishLoading because instrumentation calls
  // could be made before an applciation is finished loading.
  [instance loadUnsentData];
  [instance doFlush];
}

+ (void)newSession
{
  instance.sessionId = [instance makeUUID];
}

+ (void)startTimer:(NSString *)timerName
{
  [instance.timers setValue:[NSDate date] forKey:timerName];
}

+ (void)endTimer:(NSString *)timerName category:(NSString *)category
{
  NSDate *startTime = [instance.timers valueForKey:timerName];
  if (startTime != NULL) {
    [instance.timers removeObjectForKey:timerName];
    float elapsedTime = [[NSDate date] timeIntervalSinceDate:startTime];
    NSString *elapsedTimeStr = [NSString stringWithFormat:@"%.2f", elapsedTime];
    [instance doCollect:T_TIMER
                    name:timerName
                  amount:elapsedTimeStr
               category:category
               maxQueue:TIMER_DATA_LIMIT];
  }
}

+ (void)funnel:(NSString *)funnelName category:(NSString *)category
{
  [instance doCollect:T_FUNNEL
                  name:funnelName
                amount:NULL
             category:category
             maxQueue:FUNNEL_DATA_LIMIT];
}

+ (void)revenue:(NSString *)itemName cost:(double)cost category:(NSString *)category
{
  NSString *stringCost = [NSString stringWithFormat:@"%d", cost];
  [instance doCollect:T_REVENUE
                  name:itemName
                amount:stringCost
             category:category
             maxQueue:REVENUE_DATA_LIMIT];
}

+ (void)action:(NSString *)actionName category:(NSString *)category
{
  [instance doCollect:T_ACTION
                  name:actionName
                amount:NULL
             category:category
             maxQueue:ACTION_DATA_LIMIT];
}

+ (void)error:(NSString *)errorName category:(NSString *)category
{
  [instance doCollect:T_ERROR
                  name:errorName
                amount:NULL
             category:category
             maxQueue:ERROR_DATA_LIMIT];
}

+ (void)exception:(NSException *)exception category:(NSString *)category
{
  [Yozio error:[exception name]
      category:category];
}

+ (void)collect:(NSString *)name amount:(NSString *)amount category:(NSString *)category
{
  [instance doCollect:T_COLLECT
                  name:name
                amount:amount
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
  [self saveUnsentData];
}

- (void)onApplicationWillResignActive:(NSNotification *)notification
{
  // Clear all current timers to prevent skewed timings due to the app being inactive.
  [self.timers removeAllObjects];
}

- (void)onApplicationWillEnterForeground:(NSNotification *)notification
{
  [instance updateCountryName];
  [instance updateLanguage];
  [instance updateTimezone];
  [instance updateConfig];
}

- (void)onApplicationDidEnterBackground:(NSNotification *)notification
{
  // TODO(jt): flush data in background task
}

// TODO(jt): listen to memory warnings and significant time change?
// http://developer.apple.com/library/ios/#documentation/uikit/reference/UIApplicationDelegate_Protocol/Reference/Reference.html


/*******************************************
 * Data collection helper methods.
 *******************************************/

- (BOOL)validateConfiguration
{
  BOOL validAppKey = self._appKey != NULL;
  BOOL validSession = self.sessionId != NULL;
  if (!validAppKey) {
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    NSLog(@"Please call [Yozio configure] before instrumenting.");
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  }
  if (!validSession) {
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    NSLog(@"Please call [Yozio newSession] before instrumenting.");
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
  }
  return validAppKey && validSession;
}

- (void)doCollect:(NSString *)type
              name:(NSString *)name
            amount:(NSString *)amount
         category:(NSString *)category
         maxQueue:(NSInteger)maxQueue
{
  if (![self validateConfiguration]) {
    return;
  }
  // Increment dataCount even if we don't add to data queue so we know how much data we missed.
  dataCount++;
  if ([self.dataQueue count] < maxQueue) {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  type, D_TYPE,
                                  name, D_NAME,
                                  @"", D_REVENUE_CURRENCY,
                                  category, D_CATEGORY,
                                  [self deviceOrientation], D_DEVICE_ORIENTATION,
                                  [self uiOrientation], D_UI_ORIENTATION,
                                  self._userId, D_USER_ID,
                                  self._appVersion, D_APP_VERSION,
                                  [self timeStampString], D_TIMESTAMP,
                                  [NSNumber numberWithInteger:dataCount], D_ID,
                                  nil];
// these values are often NULL but NSDictionaries cannot take in NULL values. Make it pass in empty string.
    if (amount) {
      [d setValue:amount forKey:D_REVENUE]; 
    }
    if (self.experimentsStr) {
      [d setValue:self.experimentsStr forKey:D_EXPERIMENTS]; 
    }
    if(self.sessionId) {
      [d setValue:self.sessionId forKey:D_SESSION_ID]; 
    }
    
    [self.dataQueue addObject:d];
    [Yozio log:@"doCollect: %@", d];
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
  }
  if (self.dataToSend != NULL) {
    [Yozio log:@"Already flushing"];
    return;
  }
  self.dataToSend = [self.dataQueue objectAtIndex:0];
  [Yozio log:@"Flushing..."];
  NSString *dataStr = [self buildPayload];
  NSString *urlParams = [NSString stringWithFormat:@"data=%@", dataStr];
  // TODO(jt): try to avoid having to escape urlParams if possible
  NSString *escapedUrlParams =
      [urlParams stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
 
  NSString *urlString =
      [NSString stringWithFormat:@"http://%@/p.gif?%@", TRACKING_SERVER_URL, escapedUrlParams];
  
  
  [Yozio log:@"Final get request url: %@", urlString];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [Seriously get:urlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
    if (error) {
      [Yozio log:@"Flush error %@", error];
    } else {
      
      if ([response statusCode] == 200) {
        [Yozio log:@"Before remove: %@", self.dataQueue];

        [self.dataQueue removeObject:self.dataToSend];
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
  NSMutableDictionary* payload = [NSMutableDictionary dictionary];
  [payload setValue:digest forKey:P_DIGEST];
  [payload setValue:self._appKey forKey:P_APP_KEY];
  [payload setValue:self._env forKey:P_ENVIRONMENT];
  [payload setValue:[self loadOrCreateDeviceId] forKey:P_DEVICE_ID];
  [payload setValue:self.hardware forKey:P_HARDWARE];
  [payload setValue:self.os forKey:P_OPERATING_SYSTEM];
  [payload setValue:self.schemaVersion forKey:P_SCHEMA_VERSION];
  [payload setValue:self.countryName forKey:P_COUNTRY];
  [payload setValue:self.language forKey:P_LANGUAGE];
  [payload setValue:self.timezone forKey:P_TIMEZONE];
  [payload setValue:@"" forKey:P_TIME_PERIOD];

  [payload setValue:self._campaignSource forKey:P_CAMPAIGN_SOURCE];
  [payload setValue:self._campaignMedium forKey:P_CAMPAIGN_MEDIUM];
  [payload setValue:self._campaignTerm forKey:P_CAMPAIGN_TERM];
  [payload setValue:self._campaignContent forKey:P_CAMPAIGN_CONTENT];
  [payload setValue:self._campaignName forKey:P_CAMPAIGN_NAME];
  [payload addEntriesFromDictionary:self.dataToSend];

  [Yozio log:@"payload: %@", payload];
  return [payload JSONString];
}

- (NSString *)timeStampString
{
  NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  NSDateFormatter *tmpDateFormatter = [[NSDateFormatter alloc] init];
  instance.dateFormatter = tmpDateFormatter;
  [instance.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss SSS"];
  [instance.dateFormatter setTimeZone:gmt];
  NSString *timeStamp = [instance.dateFormatter stringFromDate:[NSDate date]];
  return timeStamp;
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

- (void)updateCountryName
{
  NSLocale *locale = [NSLocale currentLocale];
  NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
  instance.countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
}

- (void)updateLanguage
{
  instance.language = [[NSLocale preferredLanguages] objectAtIndex:0];
}

- (void)updateTimezone
{
  [NSTimeZone resetSystemTimeZone];
  NSInteger timezoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMT]/3600;
  instance.timezone = [NSNumber numberWithInteger:timezoneOffset];
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


/*******************************************
 * UUID related helper methods.
 *******************************************/

/**
 * Loads the deviceId from keychain. If one doesn't exist, create a new deviceId, store it in the
 * keychain, and return the new deviceId.
 *
 * @return The deviceId or nil if any error occurred while loading/creating/storing the UUID.
 */
- (NSString *)loadOrCreateDeviceId
{
  if (self.deviceId != nil) {
    [Yozio log:@"deviceId: %@", self.deviceId];
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


/*******************************************
 * Configuration related helper methods.
 *******************************************/

/**
 * Update self.config and self.experimentsStr with data from server.
 */
- (void)updateConfig
{
  if (self._appKey == NULL) {
    [Yozio log:@"updateConfig NULL appKey"];
    return;
  }
  if (self.deviceId == NULL) {
    [Yozio log:@"updateConfig NULL deviceId"];
    return;
  }
  NSString *urlParams = [NSString stringWithFormat:@"deviceId=%@", self.deviceId];

  NSString *urlString =
      [NSString stringWithFormat:@"http://%@/configuration.json?%@", CONFIGURATION_SERVER_URL, urlParams];

  
  
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
