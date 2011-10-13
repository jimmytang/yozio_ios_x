//
//  YozioApi.h
//  GrenadeGame
//
//  Created by Dounan Shi on 10/2/11.
//  Copyright 2011 Yozio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Timer.h"

@interface YozioApi : NSObject
{
	NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSMutableDictionary *timers;
  NSMutableData *receivedData;
  NSURLConnection *connection;
  NSString *deviceID;
}

@property (retain) NSMutableArray* dataQueue;
@property (retain) NSArray* dataToSend;
@property (retain) NSMutableDictionary* timers;
@property(nonatomic, retain) NSMutableData *receivedData;
@property(nonatomic,retain) NSURLConnection *connection;
@property (retain) NSString* deviceID;

+ (id)sharedAPI;
- (void)startTimer:(NSString *)timerName;
- (void)endTimer:(NSString *)timerName;
- (void)collect:(NSString *)key value:(NSString *)value;
- (void)funnel:(NSString *)funnelName index:(NSInteger *)index;
- (void)sale:(NSMutableArray *)offered bought:(NSString *)bought;
- (void)action:(NSString *)actionName;
- (void)error:(NSString *)errorName message:(NSString *)message stacktrace:(NSString *)stacktrace;
- (void)flush;

@end
