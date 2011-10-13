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
  NSInteger dataCount;
}

@property (retain) NSMutableArray* dataQueue;
@property (retain) NSArray* dataToSend;
@property (retain) NSMutableDictionary* timers;
@property(nonatomic, retain) NSMutableData *receivedData;
@property(nonatomic,retain) NSURLConnection *connection;
@property (retain) NSString* deviceID;
@property (nonatomic, assign) NSInteger dataCount;

+ (id)sharedAPI;
- (void)startTimer:(NSString *)timerName;
- (void)endTimer:(NSString *)timerName;
- (void)collect:(NSString *)key value:(NSString *)value;
- (void)funnel:(NSString *)funnelName step:(NSInteger *)step;
- (void)revenueShown:(NSString *)item cost:(NSString *)cost category:(NSString *)category;
- (void)revenueBought:(NSString *)item cost:(NSString *)cost category:(NSString *)category;
- (void)action:(NSString *)actionName actionObject:(NSString *)actionObject;
- (void)error:(NSString *)errorName message:(NSString *)message;
- (void)flush;

@end
