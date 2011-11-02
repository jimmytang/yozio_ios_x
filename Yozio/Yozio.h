//
//  Yozio.h
//  GrenadeGame
//
//  Copyright 2011 Yozio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Timer.h"

@interface Yozio : NSObject
{
  NSString *serverUrl;
	NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSMutableDictionary *timers;
  NSMutableData *receivedData;
  NSURLConnection *connection;
  NSInteger dataCount;
  NSString *appId;
  NSString *digest;
  NSString *deviceId;
  NSString *hardware;
  NSString *os;
  NSString *userId;
  NSString *sessionId;
  NSString *bucket;
  NSString *env;
  NSString *appVersion;
  NSString *schemaVersion;
}

@property (retain) NSString* serverUrl;
@property (retain) NSMutableArray* dataQueue;
@property (retain) NSArray* dataToSend;
@property (retain) NSMutableDictionary* timers;
@property(nonatomic, retain) NSMutableData *receivedData;
@property(nonatomic,retain) NSURLConnection *connection;
@property (nonatomic, assign) NSInteger dataCount;
@property (retain) NSString* appId;
@property (retain) NSString* digest;
@property (retain) NSString* deviceId;
@property (retain) NSString* hardware;
@property (retain) NSString* os;
@property (retain) NSString* userId;
@property (retain) NSString* sessionId;
@property (retain) NSString* bucket;
@property (retain) NSString* env;
@property (retain) NSString* appVersion;
@property (retain) NSString* schemaVersion;

+ (id)sharedAPI;

- (void)startTimer:(NSString *)timerName;

- (void)endTimer:(NSString *)timerName;

- (void)collect:(NSString *)key value:(NSString *)value category:(NSString *)category;

- (void)funnel:(NSString *)funnelName funnelValue:(NSString *)funnelValue category:(NSString *)category;

- (void)revenue:(NSString *)itemName itemCost:(double)itemCost category:(NSString *)category;

- (void)action:(NSString *)actionName actionValue:(NSString *)actionValue category:(NSString *)category;

- (void)error:(NSString *)errorName errorMessage:(NSString *)errorMessage category:(NSString *)category;

- (void)flush;

@end
