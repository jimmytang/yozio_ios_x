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
- (void)removeLowerPriority;
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
    dataQueue = [[NSMutableArray alloc] init];
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
  NSMutableDictionary* d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"timer", @"type", timerName, @"key", elapsedTimeStr, @"value", [self timeStampString], @"timestamp",nil];
  [self checkDataQueueSize];
  [dataQueue addObject:d];
}

- (void)collect:(NSString *)key value:(NSString *)value
{
  NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:@"collect", @"type", key, @"key", value, @"value", [self timeStampString], @"timestamp", nil]; 
  [self checkDataQueueSize];
  [dataQueue addObject:d];
}


- (void)funnel:(NSString *)funnelName index:(NSInteger *)index
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"funnel", @"type", funnelName, @"funnelName", index, @"index", [self timeStampString], @"timestamp", nil]; 
  [self checkDataQueueSize];
  [dataQueue addObject:d];
}

- (void)sale:(NSMutableArray *)offered bought:(NSString *)bought
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"sale", @"type", offered, @"offered", bought, @"bought", [self timeStampString], @"timestamp", nil]; 
  [self checkDataQueueSize];
  [dataQueue addObject:d];  
}

- (void)action:(NSString *)actionName
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"action", @"type", actionName, @"actionName", [self timeStampString], @"timestamp", nil]; 
  [self checkDataQueueSize];
  [dataQueue addObject:d];
}

- (void)error:(NSString *)errorName message:(NSString *)message stacktrace:(NSString *)stacktrace
{
  NSMutableDictionary *d = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"error", @"type", errorName, @"errorName", message, @"message", stacktrace, @"stacktrace", [self timeStampString], @"timestamp", nil]; 
  [self checkDataQueueSize];
  [dataQueue addObject:d];
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
  
  //  TODO(jt): Fill in real server URL
  NSURL *url = [NSURL URLWithString:@"http://localhost:3000/listener/listener/p.gif?asd=1"];
	
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
  //  TODO(jt): if response is OK, remove data from queue, else log failure.

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
  NSLog(@"%i",[dataQueue count]);
  if ([dataQueue count] > 0 && [dataQueue count] % FLUSH_DATA_COUNT == 0) 
  {
    NSLog(@"flushing");
    [self flush]; 
  }
  if ([dataQueue count] > MAX_DATA_COUNT)
  {
    [self removeLowerPriority]; 
  }
}

- (void)removeLowerPriority
{
//  todo: Jimmy Tang
}

- (NSString *)writePayload
{
  NSMutableDictionary* payload = [[NSMutableDictionary alloc] init];
  [payload setValue:self.deviceID forKey:@"deviceID"];
  [payload setValue:[NSNumber numberWithInteger:[dataToSend count]] forKey:@"dataCount"];
  [payload setValue:dataToSend forKey:@"payload"];
  NSLog(@"dataQueue: %@", dataQueue);
  NSLog(@"dataToSend: %@", dataToSend);
  return [payload JSONString];
  [payload release];
}

- (NSString *)timeStampString
{
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  dateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
  
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
  if (![NSKeyedArchiver archiveRootObject:dataQueue toFile:FILE_PATH]) {
		NSLog(@"Unable to archive data!!!");
	}
}

- (void)loadUnsentData
{
  //  TODO(jt): implement me
  NSLog(@"loadUnsentData");
  self.dataQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:FILE_PATH];
	if (!self.dataQueue) {
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