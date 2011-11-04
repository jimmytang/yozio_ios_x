//
//  Copyright 2011 Yozio. All rights reserved.
//

#import "Yozio.h"
#import "Timer.h"
#import "JSONKit.h"
#import "SFHFKeychainUtils.h"
#import <UIKit/UIKit.h>

#define FLUSH_DATA_COUNT 5
#define TIMER_DATA_COUNT 10
#define COLLECT_DATA_COUNT 15
#define ACTION_DATA_COUNT 20
#define FUNNEL_DATA_COUNT 25
#define REVENUE_DATA_COUNT 30
#define ERROR_DATA_COUNT 40
#define MAX_DATA_COUNT 50
#define TIMER_LENGTH 30
#define FILE_PATH [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]
#define UUID_KEYCHAIN_USERNAME @"UUID"
#define KEYCHAIN_SERVICE @"yozio"
// Orientations.
#define ORIENT_PORTRAIT @"portrait"
#define ORIENT_PORTRAIT_UPSIDE_DOWN @"flippedPortrait"
#define ORIENT_LANDSCAPE_LEFT @"landscapeLeft"
#define ORIENT_LANDSCAPE_RIGHT @"landscapeRight"
#define ORIENT_FACE_UP @"faceUp"
#define ORIENT_FACE_DOWN @"faceDown"
#define ORIENT_UNKNOWN @"unknown"


// Private method declarations.
@interface Yozio()
{
  NSString *_appId;
  NSString *_userId;
  NSString *_env;
  NSString *_appVersion;
  
  NSString *serverUrl;
  NSString *digest;
  NSString *deviceId;
  NSString *hardware;
  NSString *os;
  NSString *sessionId;
  NSString *schemaVersion;
  NSString *bucket;
  
  NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSInteger dataCount;
  NSMutableDictionary *timers;
  NSMutableData *receivedData;
  NSURLConnection *connection;
}

// User variables that need to be set by user.
@property(nonatomic, retain) NSString* _appId;
@property(nonatomic, retain) NSString* _userId;
@property(nonatomic, retain) NSString* _env;
@property(nonatomic, retain) NSString* _appVersion;
// User variables that can be figured out.
@property(nonatomic, retain) NSString* serverUrl;
@property(nonatomic, retain) NSString* digest;
@property(nonatomic, retain) NSString* deviceId;
@property(nonatomic, retain) NSString* hardware;
@property(nonatomic, retain) NSString* os;
@property(nonatomic, retain) NSString* sessionId;
@property(nonatomic, retain) NSString* schemaVersion;
@property(nonatomic, retain) NSString* bucket;
// Internal variables.
@property(nonatomic, retain) NSMutableArray* dataQueue;
@property(nonatomic, retain) NSArray* dataToSend;
@property(nonatomic, assign) NSInteger dataCount;
@property(nonatomic, retain) NSMutableDictionary* timers;
@property(nonatomic, retain) NSMutableData *receivedData;
@property(nonatomic, retain) NSURLConnection *connection;

// Notification observer methods.
- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification;
- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification;
- (void)applicationWillTerminate:(NSNotificationCenter *)notification;
// NSURLConnection delegate methods.
- (void)connection:(NSURLConnection *) didReceiveResponse:(NSHTTPURLResponse *) response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
// Helper methods.
- (void)collect:(NSString *)type
            key:(NSString *)key
          value:(NSString *)value
       category:(NSString *)category
       maxQueue:(NSInteger)maxQueue;
- (void)checkDataQueueSize;
- (void)doFlush;
- (NSString *)buildPayload;
- (NSString *)timeStampString;
- (void)saveUnsentData;
- (void)loadUnsentData;
- (void)connectionComplete;
- (NSString *)loadOrCreateDeviceId;
- (BOOL) storeDeviceId:(NSString *)uuid;
- (NSString *)makeUUID;
- (NSString *)deviceOrientation;
- (NSString *)uiOrientation;
@end


@implementation Yozio
@synthesize _appId;
@synthesize _userId;
@synthesize _env;
@synthesize _appVersion;
@synthesize serverUrl;
@synthesize digest;
@synthesize deviceId;
@synthesize hardware;
@synthesize os;
@synthesize sessionId;
@synthesize schemaVersion;
@synthesize bucket;
@synthesize dataQueue;
@synthesize dataToSend;
@synthesize dataCount;
@synthesize timers;
@synthesize receivedData;
@synthesize connection;


static Yozio *instance = nil; 

+ (void)initialize
{
  if (instance == nil)
  {
    instance = [[self alloc] init];
  }
}

- (id)init
{
  // TODO(jt): add timer to auto flush.
  
  self = [super init];
  UIDevice* device = [UIDevice currentDevice];
  self.serverUrl = @"http://localhost:3000/listener/listener/p.gif?";
  // TODO(jt): get real digest
  self.digest = @"";
  self.hardware = device.model;
  self.os = [device systemVersion];
  self.sessionId = [self makeUUID];
  self.schemaVersion = @"";
  self.bucket = @"";
  
  self.dataQueue = [NSMutableArray array];
  self.dataCount = 0;
  self.timers = [NSMutableDictionary dictionary];
  
  NSLog(@"%@", device);
  return self;
}


/*******************************************
 * Pulbic API.
 *******************************************/

+ (void)configure:(NSString *)appId
           userId:(NSString *)userId
              env:(NSString *)env
       appVersion:(NSString *)appVersion
{
  instance._appId = appId;
  instance._userId = userId;
  instance._env = env;
  instance._appVersion = appVersion;
}

+ (void)startTimer:(NSString *)timerName
{
  Timer* timer = [[Timer alloc] init];
  [timer start];
  [instance.timers setValue:timer forKey:timerName];
}

+ (void)endTimer:(NSString *)timerName category:(NSString *)category
{
  Timer* timer = [instance.timers valueForKey:timerName];
  if (timer == nil) {
    // We don't want developers to get away with bad instrumentation code, so raise an
    // exception and force them to deal with it.
    [NSException raise:@"Invalid timerName" format:@"timerName %@ is invalid", timerName];
  } else {
    [timer stop];
    float elapsedTime = [timer timeElapsed];
    [timer release];
    NSString *elapsedTimeStr = [NSString stringWithFormat:@"%.2f", elapsedTime];
    [instance collect:@"timer"
                  key:timerName
                value:elapsedTimeStr
             category:category
             maxQueue:TIMER_DATA_COUNT];
  }
}

+ (void)collect:(NSString *)key value:(NSString *)value category:(NSString *)category
{
  
  [instance collect:@"misc"
                key:key
              value:value
           category:category
           maxQueue:COLLECT_DATA_COUNT];
}

+ (void)funnel:(NSString *)funnelName value:(NSString *)value category:(NSString *)category
{
  [instance collect:@"funnel"
                key:funnelName
              value:value
           category:category
           maxQueue:FUNNEL_DATA_COUNT];
}

+ (void)revenue:(NSString *)itemName cost:(double)cost category:(NSString *)category
{
  NSString *stringCost = [NSString stringWithFormat:@"%d", cost];
  [instance collect:@"revenue"
                key:itemName
              value:stringCost
           category:category
           maxQueue:REVENUE_DATA_COUNT];
}

+ (void)action:(NSString *)actionName context:(NSString *)context category:(NSString *)category
{
  [instance collect:@"action"
                key:context
              value:actionName
           category:category
           maxQueue:ACTION_DATA_COUNT];
}

+ (void)error:(NSString *)errorName message:(NSString *)message category:(NSString *)category
{
  [instance collect:@"error"
                key:errorName
              value:message
           category:category
           maxQueue:ERROR_DATA_COUNT];
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
  NSLog(@"didReceiveResponse");
  NSInteger statusCode = [response statusCode];
  if (statusCode == 200) {
    NSLog(@"200: OK");
    self.receivedData = [NSMutableData data];
  } else {
    NSLog(@"%@", [NSString stringWithFormat:@"Bad response %d", statusCode]);
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  NSLog(@"didReceiveData");
  NSLog(@"%@", data);
  [self.receivedData appendData:data];
  NSLog(@"%@", self.receivedData);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  NSLog(@"didFailWithError");
  [self connectionComplete];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  NSLog(@"connectionDidFinishLoading");
  NSLog(@"receivedData:%@", self.receivedData);
  NSLog(@"Before remove:%@", self.dataQueue);
  [self.dataQueue removeObjectsInArray:self.dataToSend];
  NSLog(@"After remove:%@", self.dataQueue);
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
  NSLog(@"checkDataQueueSize");
  NSLog(@"%i",[self.dataQueue count]);
  if ([self.dataQueue count] > 0 && [self.dataQueue count] % FLUSH_DATA_COUNT == 0) 
  {
    NSLog(@"flushing");
    [self doFlush]; 
  }
}

- (void)doFlush
{
  if ([self.dataQueue count] == 0 || self.connection != nil) {
    // No events or already pushing data.
    NSLog(@"%@", self.connection);
    return;
  } else if ([self.dataQueue count] > FLUSH_DATA_COUNT) {
    self.dataToSend = [self.dataQueue subarrayWithRange:NSMakeRange(0, FLUSH_DATA_COUNT)];
  } else {
    self.dataToSend = [NSArray arrayWithArray:self.dataQueue];
  }
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NSString *dataStr = [self buildPayload];
  NSString *postBody = [NSString stringWithFormat:@"data=%@", dataStr];
  NSString *escapedUrlString =
  [postBody stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
  NSMutableString *urlString = [[NSMutableString alloc] initWithString:self.serverUrl];
  [urlString appendString:escapedUrlString];
  NSLog(@"%@", urlString);
  NSURL *url = [NSURL URLWithString:urlString];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"GET"];
  
	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[self.connection start];
}

- (NSString *)buildPayload
{
  NSMutableDictionary* payload = [[NSMutableDictionary alloc] init];
  NSLocale *locale = [NSLocale currentLocale];
  NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
  NSString *countryName = [locale displayNameForKey:NSLocaleCountryCode value:countryCode];
  [NSTimeZone resetSystemTimeZone];
  NSInteger timezoneOffset = [[NSTimeZone systemTimeZone] secondsFromGMT]/3600;
  NSString *timezone = [NSString stringWithFormat:@"%d", timezoneOffset];
  
  [payload setValue:self._appId forKey:@"appId"];
  [payload setValue:self._userId forKey:@"userId"];
  [payload setValue:self._env forKey:@"env"];
  [payload setValue:self._appVersion forKey:@"appVersion"];
  [payload setValue:self.digest forKey:@"digest"];
  [payload setValue:[self loadOrCreateDeviceId] forKey:@"deviceId"];
  [payload setValue:self.hardware forKey:@"hardware"];
  [payload setValue:self.os forKey:@"os"];
  [payload setValue:self.sessionId forKey:@"sessionId"];
  [payload setValue:self.schemaVersion forKey:@"schemaVersion"];
  [payload setValue:self.bucket forKey:@"bucket"];
  [payload setValue:[NSNumber numberWithInteger:[self.dataToSend count]] forKey:@"count"];
  [payload setValue:[self deviceOrientation] forKey:@"orientation"];
  [payload setValue:[self uiOrientation] forKey:@"uiOrientation"];
  [payload setValue:countryName forKey:@"country"];
  [payload setValue:[[NSLocale preferredLanguages] objectAtIndex:0] forKey:@"language"];
  [payload setValue:timezone forKey:@"timezone"];
  // TODO(jt): network interface (wifi, 3g)
  [payload setValue:self.dataToSend forKey:@"payload"];
  
  NSLog(@"self.dataQueue: %@", self.dataQueue);
  NSLog(@"dataToSend: %@", self.dataToSend);
  NSLog(@"payload: %@", payload);
  
  [payload autorelease];
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
  NSLog(@"saveUnsentData");
  if (![NSKeyedArchiver archiveRootObject:self.dataQueue toFile:FILE_PATH]) 
  {
    NSLog(@"Unable to archive data!!!");
  }
}

- (void)loadUnsentData
{
  NSLog(@"loadUnsentData");
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
    NSLog(@"Error loading UUID from keychain.");
    NSLog(@"%@", [loadError localizedDescription]);
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
    NSLog(@"Error storing UUID to keychain.");
    NSLog(@"%@", [storeError localizedDescription]);
    return NO;
  }
  return YES;
}

// Code taken from http://www.tuaw.com/2011/08/21/dev-juice-help-me-generate-unique-identifiers/
- (NSString *)makeUUID
{
  CFUUIDRef theUUID = CFUUIDCreate(NULL);
  NSString *uuidString = (__bridge_transfer NSString *) CFUUIDCreateString(NULL, theUUID);
  CFRelease(theUUID);
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

- (NSString *)uiOrientation {
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
  
@end
