//
//  Yozio_Private.h
//

// Private method declarations.

#if !defined(__YOZIO_PRIVATE__)
#define __YOZIO_PRIVATE__ 1

#import "Yozio.h"
#import "Reachability.h"

#define UNCAUGHT_EXCEPTION_CATEGORY @"uncaught"

// Set to true to show log messages.
#define YOZIO_LOG true

// Payload keys.
#define P_USER_ID @"userId"
#define P_ENVIRONMENT @"env"
#define P_APP_VERSION @"appVersion"
#define P_DIGEST @"digest"
#define P_DEVICE_ID @"deviceId"
#define P_HARDWARE @"hardware"
#define P_OPERATING_SYSTEM @"os"
#define P_SESSION_ID @"sessionId"
#define P_SCHEMA_VERSION @"schemaVersion"
#define P_EXPERIMENTS @"experiments"
#define P_DEVICE_ORIENTATION @"orientation"
#define P_UI_ORIENTATION @"uiOrientation"
#define P_NETWORK_INTERFACE @"network"
#define P_COUNTRY @"country"
#define P_LANGUAGE @"language"
#define P_TIMEZONE @"timezone"
#define P_COUNT @"count"
#define P_PAYLOAD @"payload"

// Instrumentation entry types.
#define E_TIMER @"timer"
#define E_FUNNEL @"funnel"
#define E_REVENUE @"revenue"
#define E_ACTION @"action"
#define E_ERROR @"error"
#define E_COLLECT @"misc"

// Orientations strings.
#define ORIENT_PORTRAIT @"portrait"
#define ORIENT_PORTRAIT_UPSIDE_DOWN @"flippedPortrait"
#define ORIENT_LANDSCAPE_LEFT @"landscapeLeft"
#define ORIENT_LANDSCAPE_RIGHT @"landscapeRight"
#define ORIENT_FACE_UP @"faceUp"
#define ORIENT_FACE_DOWN @"faceDown"
#define ORIENT_UNKNOWN @"unknown"
// Reachibility strings.
#define REACHABILITY_WWAN @"wwan"
#define REACHABILITY_WIFI @"wifi"
#define REACHABILITY_UNKNOWN @"unknown"

// TODO(jt): fine tune these numbers
// TODO(jt): make these numbers configurable instead of macros

// The number of items in the queue before forcing a flush.
#define FLUSH_DATA_COUNT 15
// XX_DATA_LIMIT describes the required number of items in the queue before that instrumentation
// event type starts being dropped.
#define TIMER_DATA_LIMIT 30
#define COLLECT_DATA_LIMIT 30
#define ACTION_DATA_LIMIT 30
#define FUNNEL_DATA_LIMIT 60
#define REVENUE_DATA_LIMIT 120
#define ERROR_DATA_LIMIT 30
// Time interval before automatically flushing the data queue.
#define FLUSH_INTERVAL_SEC 30

#define FILE_PATH [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]
#define UUID_KEYCHAIN_USERNAME @"UUID"
#define KEYCHAIN_SERVICE @"yozio"

@interface Yozio()
{
  NSString *_serverUrl;
  NSString *_userId;
  NSString *_env;
  NSString *_appVersion;
  
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

#endif /* ! __YOZIO_PRIVATE__ */
