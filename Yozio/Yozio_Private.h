//
//  Yozio_Private.h
//  Yozio
//
//  Created by Jimmy Tang on 11/6/11.
//  Copyright (c) 2011 University of California at Berkeley. All rights reserved.
//

// Private method declarations.

#import "Yozio.h"
#import "Reachability.h"

@interface Yozio()
{
  NSString *_serverUrl;
  NSString *_userId;
  NSString *_env;
  NSString *_appVersion;
  SEL _customExceptionHandler;
  
  NSString *digest;
  NSString *deviceId;
  NSString *hardware;
  NSString *os;
  NSString *sessionId;
  NSString *schemaVersion;
  NSString *experiments;
  
  NSTimer *flushTimer;
  NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSInteger dataCount;
  NSMutableDictionary *timers;
  NSMutableData *receivedData;
  NSURLConnection *connection;
  Reachability *reachability;
}

// User variables that need to be set by user.
@property(nonatomic, retain) NSString *_serverUrl;
@property(nonatomic, retain) NSString *_userId;
@property(nonatomic, retain) NSString *_env;
@property(nonatomic, retain) NSString *_appVersion;
@property(nonatomic, assign) SEL _customExceptionHandler;
// User variables that can be figured out.
@property(nonatomic, retain) NSString *digest;
@property(nonatomic, retain) NSString *deviceId;
@property(nonatomic, retain) NSString *hardware;
@property(nonatomic, retain) NSString *os;
@property(nonatomic, retain) NSString *sessionId;
@property(nonatomic, retain) NSString *schemaVersion;
@property(nonatomic, retain) NSString *experiments;
// Internal variables.
@property(nonatomic, retain) NSTimer *flushTimer;
@property(nonatomic, retain) NSMutableArray *dataQueue;
@property(nonatomic, retain) NSArray *dataToSend;
@property(nonatomic, assign) NSInteger dataCount;
@property(nonatomic, retain) NSMutableDictionary *timers;
@property(nonatomic, retain) NSMutableData *receivedData;
@property(nonatomic, retain) NSURLConnection *connection;
@property(nonatomic, retain) Reachability *reachability;

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
- (BOOL)storeDeviceId:(NSString *)uuid;
- (NSString *)makeUUID;
- (NSString *)deviceOrientation;
- (NSString *)uiOrientation;
- (NSString *)networkInterface;
+ (void)log:(NSString *)format, ...;
+ (Yozio *)getInstance; // Used for testing.
@end
