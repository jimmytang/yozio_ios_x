//
//  Copyright 2011 Yozio. All rights reserved.
//

#import "Yozio_Private.h"
#import "JSONKit.h"
#import "Reachability.h"
#import "UncaughtExceptionHandler.h"
#import "SFHFKeychainUtils.h"
#import <UIKit/UIKit.h>

// Set to true to show log messages.
#define YOZIO_LOG true

// Payload keys.
#define P_USER_ID @"userId"
#define P_ENVIRONMENT @"env"
#define P_APP_VERSION @"appVersion"
#define P_DIGEST @"digest"
#define P_DEVICE_ID @"deviceId"
#define P_HARDWARE @"hardware"
#define P_OPERATING_SYSTEM @"os"
#define P_SESSION_ID @"sessionId"
#define P_SCHEMA_VERSION @"schemaVersion"
#define P_EXPERIMENTS @"experiments"
#define P_DEVICE_ORIENTATION @"orientation"
#define P_UI_ORIENTATION @"uiOrientation"
#define P_NETWORK_INTERFACE @"network"
#define P_COUNTRY @"country"
#define P_LANGUAGE @"language"
#define P_TIMEZONE @"timezone"
#define P_COUNT @"count"
#define P_PAYLOAD @"payload"

// Instrumentation entry types.
#define E_TIMER @"timer"
#define E_FUNNEL @"funnel"
#define E_REVENUE @"revenue"
#define E_ACTION @"action"
#define E_ERROR @"error"
#define E_COLLECT @"misc"

// Orientations strings.
#define ORIENT_PORTRAIT @"portrait"
#define ORIENT_PORTRAIT_UPSIDE_DOWN @"flippedPortrait"
#define ORIENT_LANDSCAPE_LEFT @"landscapeLeft"
#define ORIENT_LANDSCAPE_RIGHT @"landscapeRight"
#define ORIENT_FACE_UP @"faceUp"
#define ORIENT_FACE_DOWN @"faceDown"
#define ORIENT_UNKNOWN @"unknown"
// Reachibility strings.
#define REACHABILITY_WWAN @"wwan"
#define REACHABILITY_WIFI @"wifi"
#define REACHABILITY_UNKNOWN @"unknown"

// TODO(jt): fine tune these numbers
// TODO(jt): make these numbers configurable instead of macros

// The number of items in the queue before forcing a flush.
#define FLUSH_DATA_COUNT 15
// XX_DATA_LIMIT describes the required number of items in the queue before that instrumentation
// event type starts being dropped.
#define TIMER_DATA_LIMIT 30
#define COLLECT_DATA_LIMIT 30
#define ACTION_DATA_LIMIT 30
#define FUNNEL_DATA_LIMIT 60
#define REVENUE_DATA_LIMIT 120
#define ERROR_DATA_LIMIT 30
// Time interval before automatically flushing the data queue.
#define FLUSH_INTERVAL_SEC 30

#define FILE_PATH [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]
#define UUID_KEYCHAIN_USERNAME @"UUID"
#define KEYCHAIN_SERVICE @"yozio"

// Private method declarations.

@implementation Yozio

@synthesize _serverUrl;
@synthesize _userId;
@synthesize _env;
@synthesize _appVersion;
@synthesize digest;
@synthesize deviceId;
@synthesize hardware;
@synthesize os;
@synthesize sessionId;
@synthesize schemaVersion;
@synthesize experiments;
@synthesize flushTimer;
@synthesize dataQueue;
@synthesize dataToSend;
@synthesize dataCount;
@synthesize timers;
@synthesize receivedData;
@synthesize connection;
@synthesize reachability;

static Yozio *instance = nil; 

+ (void)initialize {
  if (instance == nil) {
    instance = [[self alloc] init];
  }
}

- (id)init
{
  self = [super init];
  return self;
}

+ (Yozio *)getInstance
{
  return instance;
}

/*******************************************
 * Pulbic API.
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
  // TODO(jt): get real digest
  instance.digest = @"";
  instance.hardware = device.model;
  instance.os = [device systemVersion];
  instance.sessionId = [instance makeUUID];
  instance.schemaVersion = @"";
  instance.experiments = @"";
  
  instance.flushTimer = [NSTimer scheduledTimerWithTimeInterval:FLUSH_INTERVAL_SEC
                                                     target:instance
                                                   selector:@selector(doFlush)
                                                   userInfo:nil
                                                    repeats:YES];
  instance.dataQueue = [NSMutableArray array];
  instance.dataCount = 0;
  instance.timers = [NSMutableDictionary dictionary];
  instance.reachability = [Reachability reachabilityForInternetConnection];
  
  InstallUncaughtExceptionHandler(exceptionHandler);
}

+ (void)startTimer:(NSString *)timerName
{
  [instance.timers setValue:[NSDate date] forKey:timerName];
}

+ (void)endTimer:(NSString *)timerName category:(NSString *)category
{
  NSDate *startTime = [instance.timers valueForKey:timerName];
  if (startTime == nil) {
    // We don't want developers to get away with bad instrumentation code, so raise an
    // exception and force them to deal with it.
    [NSException raise:@"Invalid timerName" format:@"timerName %@ is invalid", timerName];
  } else {
    [instance.timers removeObjectForKey:timerName];
    float elapsedTime = [[NSDate date] timeIntervalSinceDate:startTime];
    NSString *elapsedTimeStr = [NSString stringWithFormat:@"%.2f", elapsedTime];
    [instance collect:E_TIMER
                  key:timerName
                value:elapsedTimeStr
             category:category
             maxQueue:TIMER_DATA_LIMIT];
  }
}

+ (void)funnel:(NSString *)funnelName value:(NSString *)value category:(NSString *)category
{
  [instance collect:E_FUNNEL
                key:funnelName
              value:value
           category:category
           maxQueue:FUNNEL_DATA_LIMIT];
}

+ (void)revenue:(NSString *)itemName cost:(double)cost category:(NSString *)category
{
  NSString *stringCost = [NSString stringWithFormat:@"%d", cost];
  [instance collect:E_REVENUE
                key:itemName
              value:stringCost
           category:category
           maxQueue:REVENUE_DATA_LIMIT];
}

+ (void)action:(NSString *)actionName context:(NSString *)context category:(NSString *)category
{
  [instance collect:E_ACTION
                key:context
              value:actionName
           category:category
           maxQueue:ACTION_DATA_LIMIT];
}

+ (void)error:(NSString *)errorName message:(NSString *)message category:(NSString *)category
{
  [instance collect:E_ERROR
                key:errorName
              value:message
           category:category
           maxQueue:ERROR_DATA_LIMIT];
}

+ (void)exception:(NSException *)exception category:(NSString *)category
{
  NSString *name = [exception name];
  NSString *reason = [exception reason];
  NSArray *stack = [[exception userInfo] valueForKey:UNCAUGHT_EXCEPTION_HANDLER_ADDRESSES_KEY];
  NSString *message = [NSString stringWithFormat:@"%@\n%@", reason, stack];
  [Yozio error:name message:message category:category];
}

+ (void)collect:(NSString *)key value:(NSString *)value category:(NSString *)category
{
  [instance collect:E_COLLECT
                key:key
              value:value
           category:category
           maxQueue:COLLECT_DATA_LIMIT];
}

+ (void)flush
{
  [instance doFlush];
}


/*******************************************
 * Notification observer methods.
 *******************************************/

- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification
{
  //  TODO(jt): implement me
  //  TODO(jt): need to cancel connection in beginBackgroundTaskWithExpirationHandler?
}

- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification
{
  // Start a new session.
  self.sessionId = [self makeUUID];
  [self loadUnsentData];
  [self doFlush];
}

- (void)applicationWillTerminate:(NSNotificationCenter *)notification
{
  [self saveUnsentData];
}


/*******************************************
 * NSURLConnection delegate methods.
 *******************************************/

- (void)connection:(NSURLConnection *) didReceiveResponse:(NSHTTPURLResponse *) response
{
  [Yozio log:@"didReceiveResponse"];
  NSInteger statusCode = [response statusCode];
  if (statusCode == 200) {
    [Yozio log:@"200: OK"];
    self.receivedData = [NSMutableData data];
  } else {
    [Yozio log:@"Bad response %d", statusCode];
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [Yozio log:@"didReceiveData"];
  [Yozio log:@"%@", data];
  [self.receivedData appendData:data];
  [Yozio log:@"%@", self.receivedData];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  [Yozio log:@"didFailWithError"];
  [self connectionComplete];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  [Yozio log:@"connectionDidFinishLoading"];
  [Yozio log:@"receivedData: %@", self.receivedData];
  [Yozio log:@"Before remove: %@", self.dataQueue];
  [self.dataQueue removeObjectsInArray:self.dataToSend];
  [Yozio log:@"After remove: %@", self.dataQueue];
  [self connectionComplete];
}


/*******************************************
 * Helper methods.
 *******************************************/

- (void)collect:(NSString *)type
            key:(NSString *)key
          value:(NSString *)value
       category:(NSString *)category
       maxQueue:(NSInteger)maxQueue
{
  // Increment dataCount even if we don't add to data queue so we know how much data we missed.
  dataCount++;
  if ([self.dataQueue count] < maxQueue)
  {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  type, @"type",
                                  key, @"key",
                                  value, @"value",
                                  category, @"category",
                                  [self timeStampString], @"timestamp",
                                  [NSNumber numberWithInteger:dataCount], @"id",
                                  nil];
    [self.dataQueue addObject:d];
  }
  [self checkDataQueueSize];
}

- (void)checkDataQueueSize
{
  [Yozio log:@"checkDataQueueSize"];
  [Yozio log:@"%i",[self.dataQueue count]];
  if ([self.dataQueue count] > 0 && [self.dataQueue count] % FLUSH_DATA_COUNT == 0) 
  {
    [Yozio log:@"flushing"];
    [self doFlush]; 
  }
}

- (void)doFlush
{
  if ([self.dataQueue count] == 0 || self.connection != nil) {
    // No events or already pushing data.
    [Yozio log:@"%@", self.connection];
    return;
  } else if ([self.dataQueue count] > FLUSH_DATA_COUNT) {
    self.dataToSend = [self.dataQueue subarrayWithRange:NSMakeRange(0, FLUSH_DATA_COUNT)];
  } else {
    self.dataToSend = [NSArray arrayWithArray:self.dataQueue];
  }
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NSString *dataStr = [self buildPayload];
  NSString *urlParams = [NSString stringWithFormat:@"data=%@", dataStr];
  NSString *escapedUrlParams =
      [urlParams stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
  NSString *urlString = [NSString stringWithFormat:@"%@/%@", self._serverUrl, escapedUrlParams];
  NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"GET"];
  
  [Yozio log:@"%@", urlString];
  
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[self.connection start];
}

- (NSString *)buildPayload
{
  NSMutableDictionary* payload = [NSMutableDictionary dictionary];
  NSLocale *locale = [NSLocale currentLocale];
  NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
  NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
  [NSTimeZone resetSystemTimeZone];
  NSInteger timezoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMT]/3600;
  NSNumber *timezone = [NSNumber numberWithInteger:timezoneOffset];
  
  [payload setValue:self._userId forKey:P_USER_ID];
  [payload setValue:self._env forKey:P_ENVIRONMENT];
  [payload setValue:self._appVersion forKey:P_APP_VERSION];
  [payload setValue:self.digest forKey:P_DIGEST];
  [payload setValue:[self loadOrCreateDeviceId] forKey:P_DEVICE_ID];
  [payload setValue:self.hardware forKey:P_HARDWARE];
  [payload setValue:self.os forKey:P_OPERATING_SYSTEM];
  [payload setValue:self.sessionId forKey:P_SESSION_ID];
  [payload setValue:self.schemaVersion forKey:P_SCHEMA_VERSION];
  [payload setValue:self.experiments forKey:P_EXPERIMENTS];
  // TODO(jt): move orientation into event instead of here
  [payload setValue:[self deviceOrientation] forKey:P_DEVICE_ORIENTATION];
  [payload setValue:[self uiOrientation] forKey:P_UI_ORIENTATION];
  // TODO(jt): dont use NETWORK_INTERFACE for now.
  [payload setValue:[self networkInterface] forKey:P_NETWORK_INTERFACE];
  [payload setValue:countryName forKey:P_COUNTRY];
  [payload setValue:[[NSLocale preferredLanguages] objectAtIndex:0] forKey:P_LANGUAGE];
  [payload setValue:timezone forKey:P_TIMEZONE];
  [payload setValue:[NSNumber numberWithInteger:[self.dataToSend count]] forKey:P_COUNT];
  [payload setValue:self.dataToSend forKey:P_PAYLOAD];
  
  [Yozio log:@"self.dataQueue: %@", self.dataQueue];
  [Yozio log:@"dataToSend: %@", self.dataToSend];
  [Yozio log:@"payload: %@", payload];
  
  return [payload JSONString];
}

- (NSString *)timeStampString
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss SSS";
  
  NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  [dateFormatter setTimeZone:gmt];
  NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
  [dateFormatter release];
  return timeStamp;
}

- (void)saveUnsentData
{
  [Yozio log:@"saveUnsentData"];
  if (![NSKeyedArchiver archiveRootObject:self.dataQueue toFile:FILE_PATH]) 
  {
    [Yozio log:@"Unable to archive data!!!"];
  }
}

- (void)loadUnsentData
{
  [Yozio log:@"loadUnsentData"];
  self.dataQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:FILE_PATH];
  if (!self.dataQueue) 
  {
    self.dataQueue = [NSMutableArray array];    
  }
}

- (void)connectionComplete
{
  self.receivedData = nil;
  self.dataToSend = nil;
  self.connection = nil;
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  //  TODO(jt): stop background task if running in background
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
  if (loadErrorCode == errSecItemNotFound) {
    // No deviceId stored in keychain yet.
    uuid = [self makeUUID];
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

- (BOOL) storeDeviceId:(NSString *)uuid
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

- (NSString *)networkInterface
{
  NetworkStatus status = [reachability currentReachabilityStatus];
  switch (status) {
    case ReachableViaWWAN:
      return REACHABILITY_WWAN;
    case ReachableViaWiFi:
      return REACHABILITY_WIFI;
    default:
      return REACHABILITY_UNKNOWN;
  }
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

@end
