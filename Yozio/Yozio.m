//
//  Copyright 2011 Yozio. All rights reserved.
//

#import "UIKit/UIKit.h"
#import "CommonCrypto/CommonCryptor.h"
#import "NSString+MD5.h"
#import "YJSONKit.h"
#import "YSeriously.h"
#import "YOpenUDID.h"

#import "Yozio.h"
#import "Yozio_Private.h"


@implementation Yozio

// User set instrumentation variables.
@synthesize _appKey;
@synthesize _secretKey;

// Automatically determined instrumentation variables.
@synthesize deviceId;

// Internal variables.
@synthesize dataQueue;
@synthesize dataToSend;
@synthesize dataCount;
@synthesize dateFormatter;
@synthesize config;
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
  
  // Initialize constant intrumentation variables.
  self.deviceId = [YOpenUDID value];
  
  // Initialize  mutable instrumentation variables.
  
  self.dataCount = 0;
  self.dataQueue = [NSMutableArray array];
  self.dataToSend = nil;
  self.config = nil;
  
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
  [instance updateConfig];
  
  // Load any previous data.
  // Perform this here instead of on applicationDidFinishLoading because instrumentation calls
  // could be made before an application is finished loading.
  [instance loadUnsentData];
  [Yozio openedApp];
  [instance doFlush];
}

+ (NSString *)getUrl:(NSString *)linkName destinationUrl:(NSString *)destinationUrl
{
  if (instance.config == nil) {
    instance.config = [NSMutableDictionary dictionary];
  }
  NSString *val = [instance.config objectForKey:destinationUrl];
  if (val != nil) {
    return val;
  }
  else {
    NSString *urlParams = 
    [NSString stringWithFormat:@"%@=%@&%@=%@&%@=%@&%@=%@&%@=%@", 
     YOZIO_GET_URL_P_APP_KEY, instance._appKey, YOZIO_GET_URL_P_YOZIO_UDID, instance.deviceId, YOZIO_GET_URL_P_DEVICE_TYPE, YOZIO_DEVICE_TYPE_IOS, YOZIO_GET_URL_P_LINK_NAME, linkName, YOZIO_GET_URL_P_DEST_URL, destinationUrl];
    NSString *urlString =
    [NSString stringWithFormat:@"%@%@?%@", YOZIO_DEFAULT_BASE_URL, YOZIO_GET_URL_ROUTE, urlParams];
    NSString* escapedUrlString =  [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    [Yozio log:@"Final getUrl Request: %@", escapedUrlString];
    
    instance.stopBlocking = false;
    // Blocking
    [NSTimer scheduledTimerWithTimeInterval:5 target:instance selector:@selector(stopBlockingApp) userInfo:nil repeats:NO];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    //  add some timing check before and on response
    [YSeriously get:escapedUrlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
      if (error) {
        instance.stopBlocking = true;
        [Yozio log:@"getUrl error %@", error];
      } else {
        if ([response statusCode] == 200) {
          NSString *shortenedUrl = [body objectForKey:@"url"];
          [instance.config setObject:shortenedUrl forKey:destinationUrl];
        }
        instance.stopBlocking = true;
      }
      [Yozio log:@"getUrl request complete"];
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
    
    // Blocking
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
    while (!instance.stopBlocking && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil]) {
      loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.5];
    }
    
    // return the short url. Return destinationUrl if it can't the destinationUrl's short url.
    if (instance.config == nil) {
      return destinationUrl;
    }
    NSString *val = [instance.config objectForKey:destinationUrl];
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
  BOOL validSecretKey = self._secretKey != nil;
  if (!validAppKey || !validSecretKey) {
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    NSLog(@"Please call [Yozio configure] before instrumenting.");
    NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
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
    NSMutableDictionary *d =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     [self notNil:type], YOZIO_D_TYPE,
     [self notNil:linkName], YOZIO_D_LINK_NAME,
     [self notNil:[self timeStampString]], YOZIO_D_TIMESTAMP,
     nil];
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

  NSString *dataStr = [self buildPayload];
  
  NSString *urlParams = [NSString stringWithFormat:@"%@=%@", YOZIO_BATCH_EVENTS_P_DATA, dataStr];
  NSString *escapedUrlParams =
  [[urlParams stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@"%2B"];
  NSString *urlString =
  [NSString stringWithFormat:@"%@%@?%@", YOZIO_DEFAULT_BASE_URL, YOZIO_BATCH_EVENTS_ROUTE, escapedUrlParams];
  
  [Yozio log:@"Final get request url: %@", urlString];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  [YSeriously get:urlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
    if (error) {
      [Yozio log:@"Flush error %@", error];
      self.dataToSend = nil;
    } else {
      if ([response statusCode] == 200) {
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
  [payload setObject:[self notNil:self.deviceId] forKey:YOZIO_P_UDID];
  [payload setObject:YOZIO_DEVICE_TYPE_IOS forKey:YOZIO_P_DEVICE_TYPE];
  [payload setObject:self.dataToSend forKey:YOZIO_P_PAYLOAD];
  [Yozio log:@"payload: %@", payload];
  
  //  JSONify
  NSString *jsonPayload = [payload JSONString];
  
  return jsonPayload;
}


- (NSString *)notNil:(NSString *)str
{
  if (str == nil) {
    return @"Unknown";
  } else {
    return str;
  }
}

- (NSDictionary *)dictNotNil:(NSDictionary *)dict
{
  if (dict == nil) {
    return [NSDictionary dictionary];
  } else {
    return dict;
  }
}

/*******************************************
 * Instrumentation data helper methods.
 *******************************************/

- (NSString *)timeStampString
{
  NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
  NSDateFormatter *tmpDateFormatter = [[NSDateFormatter alloc] init];
  self.dateFormatter = tmpDateFormatter;
  [self.dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss SSS"];
  [tmpDateFormatter release];
  [self.dateFormatter setTimeZone:gmt];
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

/**
 * Update self.configs with data from server.
 */

- (void)updateConfig
{
  if (self._appKey == nil) {
    [Yozio log:@"updateConfig nil appKey"];
    return;
  }
  if (self.deviceId == nil) {
    [Yozio log:@"updateConfig nil deviceId"];
    return;
  }
  
  NSMutableDictionary* payload = [NSMutableDictionary dictionary];
  [payload setObject:self._appKey forKey:YOZIO_P_APP_KEY];
  [payload setObject:[self notNil:self.deviceId] forKey:YOZIO_P_UDID];
  [payload setObject:YOZIO_DEVICE_TYPE_IOS forKey:YOZIO_P_DEVICE_TYPE];
  
  
  NSString *urlParams = [NSString stringWithFormat:@"data=%@", [payload JSONString]];
  NSString *urlString =
  [NSString stringWithFormat:@"%@%@?%@", YOZIO_DEFAULT_BASE_URL, YOZIO_GET_CONFIG_ROUTE, urlParams];
  NSString* escapedUrlString =  [urlString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
  [Yozio log:@"Final configuration request url: %@", escapedUrlString];
  
  // Blocking
  [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(stopBlockingApp) userInfo:nil repeats:NO];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  //  add some timing check before and on response
  [YSeriously get:escapedUrlString handler:^(id body, NSHTTPURLResponse *response, NSError *error) {
    if (error) {
      self.stopBlocking = true;
      [Yozio log:@"updateConfig error %@", error];
    } else {
      if ([response statusCode] == 200) {
        [Yozio log:@"config before update: %@", self.config];
        self.config = [body objectForKey:YOZIO_URLS_KEY];
        self.stopBlocking = true;
        [Yozio log:@"urls after update: %@", self.config];
      }
    }
    [Yozio log:@"configuration request complete"];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
  
  // Blocking
  NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:1];
  while (!self.stopBlocking && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:loopUntil]) {
    loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.5];
  }
}

- (void)stopBlockingApp {
  self.stopBlocking = true;
}

- (void)dealloc
{
  [_appKey release], _appKey = nil;
  [_secretKey release], _secretKey = nil;
  [deviceId release], deviceId = nil;
  [dateFormatter release], dateFormatter = nil;
  [dataQueue release], dataQueue = nil;
  [super dealloc];
}

@end
