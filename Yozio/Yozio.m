//
//  YozioApi.m
//  GrenadeGame
//
//  Copyright 2011 Yozio. All rights reserved.
//

#import "Yozio.h"
#import "Timer.h"
#import "JSONKit.h"
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
#define SERVER_URL @"http://localhost:3000/listener/listener/p.gif?"
#define FILE_PATH [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]


// Private method declarations.
@interface Yozio()
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
- (NSString *)writePayload;
- (NSString *)timeStampString;
- (void)saveUnsentData;
- (void)loadUnsentData;
- (void)connectionComplete;
@end


@implementation Yozio
@synthesize dataQueue;
@synthesize dataToSend;
@synthesize timers;
@synthesize receivedData;
@synthesize connection;
@synthesize dataCount;
@synthesize appId;
@synthesize digest;
@synthesize deviceId;
@synthesize hardware;
@synthesize os;
@synthesize userId;
@synthesize sessionId;
@synthesize bucket;
@synthesize env;
@synthesize appVersion;
@synthesize schemaVersion;


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
  if (instance == nil) {
    self = [super init];
    // TODO(jimmytang): look into autorelease
    self.dataQueue = [[NSMutableArray alloc] init];
    self.appId = @"temp appId";
    self.digest = @"temp digest";
    self.deviceId = [UIDevice currentDevice].uniqueIdentifier;
    self.hardware = [UIDevice currentDevice].model;
    self.os = [[UIDevice currentDevice] systemVersion];
    
    UIDevice* device = [UIDevice currentDevice];
    NSLog(@"%@",device);

    self.userId = @"temp userId";
    self.sessionId = @"temp sessionId";
    self.bucket = @"temp bucket";
    self.env = @"PRODUCTION";
    self.appVersion = @"temp appVersion";
    self.schemaVersion = @"temp schemaVersion";
    
    self.receivedData = [[NSMutableData alloc] init];
    dataCount = 0;
  }
  return self;
}


/*******************************************
 * Pulbic API.
 *******************************************/

// TODO(jimmytang): add call to check if flushing is required in the different collect methods.

+ (id)sharedAPI
{
  return instance;
}

- (void)startTimer:(NSString *)timerName
{
  // TODO(jimmytang): memory management for timer.
  Timer* timer = [[Timer alloc] init];
  [timer startTimer];
  [timers setValue:timer forKey:timerName];
}

- (void)endTimer:(NSString *)timerName
{
  Timer* timer = [timers valueForKey:timerName];
  [timer stopTimer];
  float elapsedTime = [timer timeElapsedInMilliseconds];
  NSString *elapsedTimeStr = [NSString stringWithFormat:@"%.2f", elapsedTime];
  NSMutableDictionary* d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"timer", @"type", timerName, @"key", elapsedTimeStr, @"value", @"", @"category", [self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil];
  
  [self checkDataQueueSize];
  if ([self.dataQueue count] < TIMER_DATA_COUNT)
  {  
    [self.dataQueue addObject:d];
  }
}

- (void)collect:(NSString *)key value:(NSString *)value category:(NSString *)category
{
  [self collect:@"misc" key:key value:value category:category maxQueue:COLLECT_DATA_COUNT];
}

- (void)funnel:(NSString *)funnelName funnelValue:(NSString *)funnelValue category:(NSString *)category
{
  [self collect:@"funnel" key:funnelName value:funnelValue category:category maxQueue:FUNNEL_DATA_COUNT];
}

- (void)revenue:(NSString *)itemName itemCost:(double)itemCost category:(NSString *)category
{
  NSString *stringCost = [NSString stringWithFormat:@"%d", itemCost];
  [self collect:@"revenue" key:itemName value:stringCost category:category maxQueue:REVENUE_DATA_COUNT];
}

- (void)action:(NSString *)actionName actionValue:(NSString *)actionValue category:(NSString *)category
{
  [self collect:@"action" key:actionName value:actionValue category:category maxQueue:ACTION_DATA_COUNT];
}

- (void)error:(NSString *)errorName errorMessage:(NSString *)errorMessage category:(NSString *)category
{
  [self collect:@"error" key:errorName value:errorMessage category:category maxQueue:ERROR_DATA_COUNT];
}

- (void)flush
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
  
  //  TODO(jt): Get data to send (but don't remove from queue, only remove after succesfully sent).
  NSString *dataStr = [self writePayload];
  NSString *postBody = [NSString stringWithFormat:@"data=%@", dataStr];
  NSString* escapedUrlString =
  // TODO(jt): Do we ever send postBody?
  [postBody stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
  NSMutableString *urlString = [[NSMutableString alloc] initWithString:SERVER_URL];
  [urlString appendString:escapedUrlString];
  
  //  TODO(jt): Fill in real server URLac
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSLog(@"%@", urlString);
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPMethod:@"GET"];

	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[self.connection start];
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
  //  TODO(jt): implement me
  [self loadUnsentData];
  [self flush];
}

- (void)applicationWillTerminate:(NSNotificationCenter *)notification
{
  //  TODO(jt): implement me
  [self saveUnsentData];
}


/*******************************************
 * NSURLConnection delegate methods.
 *******************************************/

- (void)connection:(NSURLConnection *) didReceiveResponse:(NSHTTPURLResponse *) response
{
  NSLog(@"didReceiveResponse");
  if ([response statusCode] == 200) {
    NSLog(@"200: OK");
    self.receivedData = [NSMutableData data];
  } else {
    //  TODO(jt): log unsuccessful request
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
  //  TODO(jt): log failure
  self.dataToSend = nil;
  self.connection = nil;
  [self connectionComplete];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  NSLog(@"connectionDidFinishLoading");
  NSLog(@"receivedData:%@", self.receivedData);
  NSLog(@"Before remove:%@", self.dataQueue);
  [self.dataQueue removeObjectsInArray:self.dataToSend];
  NSLog(@"After remove:%@", self.dataQueue);
  self.dataToSend = nil;
  self.receivedData = nil;
  self.connection = nil;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  [self connectionComplete];
}


/*******************************************
 * Helper methods.
 *******************************************/

- (void)collect:(NSString *)type key:(NSString *)key value:(NSString *)value category:(NSString *)category maxQueue:(NSInteger)maxQueue
{
  dataCount++;
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:type, @"type", key, @"key", value, @"value", category, @"category", [self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil]; 
  
  [self checkDataQueueSize];
  if ([self.dataQueue count] < maxQueue)
  {  
    [self.dataQueue addObject:d];
  }
}

- (void)checkDataQueueSize
{
  NSLog(@"checkDataQueueSize");
  NSLog(@"%i",[self.dataQueue count]);
  if ([self.dataQueue count] > 0 && [self.dataQueue count] % FLUSH_DATA_COUNT == 0) 
  {
    NSLog(@"flushing");
    [self flush]; 
  }
}

// TODO(js): change this to take in dataToSend as an arg instead of using the instance var.
// TODO(js): rename to buildPayload
- (NSString *)writePayload
{
  NSMutableDictionary* payload = [[NSMutableDictionary alloc] init];
  [payload setValue:self.appId forKey:@"appId"];
  [payload setValue:self.digest forKey:@"digest"];
  [payload setValue:self.deviceId forKey:@"deviceId"];
  [payload setValue:self.hardware forKey:@"hardware"];
  [payload setValue:self.os forKey:@"os"];
  [payload setValue:self.userId forKey:@"userId"];
  [payload setValue:self.sessionId forKey:@"sessionId"];
  [payload setValue:self.bucket forKey:@"bucket"];
  [payload setValue:self.env forKey:@"env"];
  [payload setValue:self.appVersion forKey:@"appVersion"];
  [payload setValue:self.schemaVersion forKey:@"schemaVersion"];
  [payload setValue:[NSNumber numberWithInteger:[dataToSend count]] forKey:@"count"];
  [payload setValue:dataToSend forKey:@"payload"];
  
  NSLog(@"self.dataQueue: %@", self.dataQueue);
  NSLog(@"dataToSend: %@", dataToSend);
  NSLog(@"payload: %@", payload);
  
  return [payload JSONString];
  
  // TODO(jt): why release after return?
  [payload release];
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
  //  TODO(jt): implement me
  NSLog(@"saveUnsentData");
  if (![NSKeyedArchiver archiveRootObject:self.dataQueue toFile:FILE_PATH]) 
  {
    NSLog(@"Unable to archive data!!!");
  }
}

- (void)loadUnsentData
{
  //  TODO(jt): implement me
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
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  //  TODO(jt): stop background task if running in background
}
  
@end








