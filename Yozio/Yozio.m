//
//  YozioApi.m
//  GrenadeGame
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

// Private method declarations.
@interface Yozio()
{
  NSString *_appId;
  NSString *_userId;
  NSString *_bucket;
  NSString *_env;
  NSString *_appVersion;
  
  NSString *serverUrl;
  NSString *digest;
  NSString *deviceId;
  NSString *hardware;
  NSString *os;
  NSString *sessionId;
  NSString *schemaVersion;
  
  NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSInteger dataCount;
  NSMutableDictionary *timers;
  NSMutableData *receivedData;
  NSURLConnection *connection;
}

// User variables that need to be set by user.
@property (retain) NSString* _appId;
@property (retain) NSString* _userId;
@property (retain) NSString* _bucket;
@property (retain) NSString* _env;
@property (retain) NSString* _appVersion;
// User variables that can be figured out.
@property (retain) NSString* serverUrl;
@property (retain) NSString* digest;
@property (retain) NSString* deviceId;
@property (retain) NSString* hardware;
@property (retain) NSString* os;
@property (retain) NSString* sessionId;
@property (retain) NSString* schemaVersion;
// Internal variables.
@property (retain) NSMutableArray* dataQueue;
@property (retain) NSArray* dataToSend;
@property (nonatomic, assign) NSInteger dataCount;
@property (retain) NSMutableDictionary* timers;
@property(nonatomic, retain) NSMutableData *receivedData;
@property(nonatomic,retain) NSURLConnection *connection;

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
- (void)collect:(NSString *)type key:(NSString *)key value:(NSString *)value  category:(NSString *)category maxQueue:(NSInteger)maxQueue;
- (void)checkDataQueueSize;
- (void)doFlush;
- (NSString *)buildPayload;
- (NSString *)timeStampString;
- (void)saveUnsentData;
- (void)loadUnsentData;
- (void)connectionComplete;
- (void) updateDeviceId;
- (NSString *)getUUID;
- (NSString *)makeUUID;
- (BOOL) storeUUID:(NSString *)uuid;
@end


@implementation Yozio
@synthesize _appId;
@synthesize _userId;
@synthesize _bucket;
@synthesize _env;
@synthesize _appVersion;
@synthesize serverUrl;
@synthesize digest;
@synthesize deviceId;
@synthesize hardware;
@synthesize os;
@synthesize sessionId;
@synthesize schemaVersion;
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
  self = [super init];
  UIDevice* device = [UIDevice currentDevice];
  self.serverUrl = @"http://localhost:3000/listener/listener/p.gif?";
  self.digest = @"temp digest";
  // TODO(jt): use a hashed MAC address from en0 (not active interface)
  self.deviceId = [self getUUID];
  self.hardware = device.model;
  self.os = [device systemVersion];
  self.sessionId = @"temp sessionId";
  self.schemaVersion = @"temp schemaVersion";
  
  self.dataQueue = [NSMutableArray array];
  self.dataCount = 0;
  // TODO(jt): initialize timers?
  
  NSLog(@"%@", device);
  return self;
}


/*******************************************
 * Pulbic API.
 *******************************************/

// TODO(jt): make the public API methods thread safe?

+ (void)configure:(NSString *)appId
           userId:(NSString *)userId
           bucket:(NSString *)bucket
              env:(NSString *)env
       appVersion:(NSString *)appVersion
{
  instance._appId = appId;
  instance._userId = userId;
  instance._bucket = bucket;
  instance._env = env;
  instance._appVersion = appVersion;
}

+ (void)startTimer:(NSString *)timerName
{
  Timer* timer = [[Timer alloc] init];
  [timer startTimer];
  [instance.timers setValue:timer forKey:timerName];
}

+ (void)endTimer:(NSString *)timerName category:(NSString *)category
{
  Timer* timer = [instance.timers valueForKey:timerName];
  [timer stopTimer];
  float elapsedTime = [timer timeElapsedInMilliseconds];
  [timer release];
  NSString *elapsedTimeStr = [NSString stringWithFormat:@"%.2f", elapsedTime];
  [instance collect:@"timer" key:timerName value:elapsedTimeStr category:category maxQueue:TIMER_DATA_COUNT];
}

+ (void)collect:(NSString *)key value:(NSString *)value category:(NSString *)category
{
  
  [instance collect:@"misc" key:key value:value category:category maxQueue:COLLECT_DATA_COUNT];
}

+ (void)funnel:(NSString *)funnelName funnelValue:(NSString *)funnelValue category:(NSString *)category
{
  [instance collect:@"funnel" key:funnelName value:funnelValue category:category maxQueue:FUNNEL_DATA_COUNT];
}

+ (void)revenue:(NSString *)itemName itemCost:(double)itemCost category:(NSString *)category
{
  NSString *stringCost = [NSString stringWithFormat:@"%d", itemCost];
  [instance collect:@"revenue" key:itemName value:stringCost category:category maxQueue:REVENUE_DATA_COUNT];
}

+ (void)action:(NSString *)actionName actionValue:(NSString *)actionValue category:(NSString *)category
{
  [instance collect:@"action" key:actionName value:actionValue category:category maxQueue:ACTION_DATA_COUNT];
}

+ (void)error:(NSString *)errorName errorMessage:(NSString *)errorMessage category:(NSString *)category
{
  [instance collect:@"error" key:errorName value:errorMessage category:category maxQueue:ERROR_DATA_COUNT];
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

- (void)collect:(NSString *)type key:(NSString *)key value:(NSString *)value category:(NSString *)category maxQueue:(NSInteger)maxQueue
{
  // Increment dataCount even if we don't add to data queue so we know how much data we missed.
  dataCount++;
  if ([self.dataQueue count] < maxQueue)
  {
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:type, @"type", key, @"key", value, @"value", category, @"category", [self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil];
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
  [self updateDeviceId];
  
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

// TODO(js): change this to take in dataToSend as an arg instead of using the instance var.
- (NSString *)buildPayload
{
  NSMutableDictionary* payload = [[NSMutableDictionary alloc] init];
  [payload setValue:self._appId forKey:@"appId"];
  [payload setValue:self._userId forKey:@"userId"];
  [payload setValue:self._bucket forKey:@"bucket"];
  [payload setValue:self._env forKey:@"env"];
  [payload setValue:self._appVersion forKey:@"appVersion"];
  [payload setValue:self.digest forKey:@"digest"];
  [payload setValue:self.deviceId forKey:@"deviceId"];
  [payload setValue:self.hardware forKey:@"hardware"];
  [payload setValue:self.os forKey:@"os"];
  [payload setValue:self.sessionId forKey:@"sessionId"];
  [payload setValue:self.schemaVersion forKey:@"schemaVersion"];
  [payload setValue:[NSNumber numberWithInteger:[self.dataToSend count]] forKey:@"count"];
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
 * Tries to set deviceId to the UUID if it is nil. The deviceId can still potentially be
 * nil after calling this method.
 */
- (void) updateDeviceId
{
  if (self.deviceId == nil) {
    self.deviceId = [self getUUID];
  }
}

/**
 * @returns The string UUID or nil if an error occurred while creating/loading the UUID.
 */
- (NSString *)getUUID
{
  NSError *loadError = nil;
  NSString *uuid = [SFHFKeychainUtils getPasswordForUsername:UUID_KEYCHAIN_USERNAME
                                              andServiceName:KEYCHAIN_SERVICE
                                                       error:&loadError];
  NSInteger loadErrorCode = [loadError code];
  if (loadErrorCode == errSecItemNotFound) {
    // No UUID stored in keychain yet.
    uuid = [self makeUUID];
    if (![self storeUUID:uuid]) {
      return nil;
    }
  } else if (loadErrorCode != errSecSuccess) {
    NSLog(@"Error loading UUID from keychain.");
    NSLog(@"%@", [loadError localizedDescription]);
    return nil;
  }
  return uuid;
}

// Code taken from http://www.tuaw.com/2011/08/21/dev-juice-help-me-generate-unique-identifiers/
- (NSString *)makeUUID
{
  CFUUIDRef theUUID = CFUUIDCreate(NULL);
  NSString *uuidString = (__bridge_transfer NSString *) CFUUIDCreateString(NULL, theUUID);
  CFRelease(theUUID);
  return uuidString;
}

- (BOOL) storeUUID:(NSString *)uuid
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
  
@end
