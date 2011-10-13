//
//  YozioApi.m
//  GrenadeGame
//
//  Created by Dounan Shi on 10/2/11.
//  Copyright 2011 Yozio. All rights reserved.
//

#import "YozioApi.h"
#import "Timer.h"
#import "JSONKit.h"
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


// Private method declarations.
@interface YozioApi()
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
- (void)checkDataQueueSize;
- (NSString *)writePayload;
- (NSString *)timeStampString;
- (void)saveUnsentData;
- (void)loadUnsentData;
- (void)connectionComplete;
@end


@implementation YozioApi
@synthesize dataQueue;
@synthesize dataToSend;
@synthesize timers;
@synthesize receivedData;
@synthesize deviceID;
@synthesize connection;
@synthesize dataCount;

static YozioApi *instance = nil; 

+ (void)initialize
{
  if (instance == nil)
    instance = [[self alloc] init];
}

- (id)init
{
  if (instance == nil) {
    self = [super init];
    // TODO(jimmytang): look into autorelease
    self.dataQueue = [[NSMutableArray alloc] init];
    //    self.schemaID = SCHEMA_ID;
    self.deviceID = [UIDevice currentDevice].uniqueIdentifier;
    //    self.gameVersion = @"gameVersion";
    //    self.sessionID = @"sessionID";
    //    self.bucketID = @"bucketID";
    //    self.userID = @"userID";
    //    self.environment = @"sandbox";
    //    self.currentLevelID = 1;
    //    self.events = [NSMutableArray array];
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
  [timer release];
  NSString *elapsedTimeStr = [NSString stringWithFormat:@"%.2f", elapsedTime];
  NSMutableDictionary* d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"timer", @"type", timerName, @"key", elapsedTimeStr, @"value", @"", @"category", [self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil];
  
  [self checkDataQueueSize];
  if ([self.dataQueue count] < TIMER_DATA_COUNT)
  {  
    [self.dataQueue addObject:d];
  }
}

- (void)collect:(NSString *)key value:(NSString *)value
{
  dataCount++;
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"misc", @"type", key, @"key", value, @"value", @"", @"category", [self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil]; 
  
  [self checkDataQueueSize];
  if ([self.dataQueue count] < COLLECT_DATA_COUNT)
  {  
    [self.dataQueue addObject:d];
  }
}


- (void)funnel:(NSString *)funnelName step:(NSInteger *)step
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"funnel", @"type", funnelName, @"key", step, @"value", @"", @"category",[self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil]; 
  
  [self checkDataQueueSize];
  if ([self.dataQueue count] < FUNNEL_DATA_COUNT)
  {  
    [self.dataQueue addObject:d];
  }
}

- (void)revenueShown:(NSString *)item cost:(NSString *)cost category:(NSString *)category
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"revenue_shown", @"type", item, @"key", cost, @"value", category, @"category",[self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil]; 

  [self checkDataQueueSize];
  if ([self.dataQueue count] < REVENUE_DATA_COUNT)
  {  
    [self.dataQueue addObject:d];
  }
}

- (void)revenueBought:(NSString *)item cost:(NSString *)cost category:(NSString *)category
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"revenue_bought", @"type", item, @"key", cost, @"value", category, @"category",[self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil]; 

  [self checkDataQueueSize];
  if ([self.dataQueue count] < REVENUE_DATA_COUNT)
  {  
    [self.dataQueue addObject:d];
  }
}

- (void)action:(NSString *)actionName actionObject:(NSString *)actionObject
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"action", @"type", actionName, @"key", actionObject, @"value", @"", @"category",[self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil]; 

  [self checkDataQueueSize];
  if ([self.dataQueue count] < ACTION_DATA_COUNT)
  {  
    [self.dataQueue addObject:d];
  }
}

- (void)error:(NSString *)errorName message:(NSString *)message 
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"error", @"type", errorName, @"key", message, @"value", @"", @"category",[self timeStampString], @"timestamp", [NSNumber numberWithInteger:dataCount], @"id", nil]; 
  [self checkDataQueueSize];
  if ([self.dataQueue count] < ERROR_DATA_COUNT)
  {  
    [self.dataQueue addObject:d];
  }
}

- (void)flush
{
  if ([self.dataQueue count] == 0 || self.connection != nil) { // No events or already pushing data.
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
  [postBody stringByAddingPercentEscapesUsingEncoding:
   NSASCIIStringEncoding];
  NSMutableString *urlString = [[NSMutableString alloc] initWithString:@"http://localhost:3000/listener/listener/p.gif?"];
  [urlString appendString:escapedUrlString];
  
  //  TODO(jt): Fill in real server URLac
  NSURL *url = [NSURL URLWithString:urlString];
  
  NSLog(@"%@", urlString);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	[request setHTTPMethod:@"GET"];

	self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[self.connection start];
  [request release];
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
    NSLog(@"FUCK YOU");
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
  NSString *response = [[NSString alloc] initWithData:self.receivedData
                                             encoding:NSUTF8StringEncoding];

  NSLog(@"receivedData:%@", self.receivedData);
  NSLog(@"response:%@", response);
  NSLog(@"Before remove:%@", self.dataQueue);
  [self.dataQueue removeObjectsInArray:self.dataToSend];
  NSLog(@"After remove:%@", self.dataQueue);
	self.dataToSend = nil;
	self.receivedData = nil;
  self.connection = nil;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  [response release];
  [self connectionComplete];
}


/*******************************************
 * Helper methods.
 *******************************************/

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

- (NSString *)writePayload
{
  NSMutableDictionary* payload = [[NSMutableDictionary alloc] init];
  [payload setValue:self.deviceID forKey:@"deviceID"];
  [payload setValue:[NSNumber numberWithInteger:[dataToSend count]] forKey:@"dataCount"];
  [payload setValue:dataToSend forKey:@"payload"];
  NSLog(@"self.dataQueue: %@", self.dataQueue);
  NSLog(@"dataToSend: %@", dataToSend);
  return [payload JSONString];
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








