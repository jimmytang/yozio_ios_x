//
//  Yozio_Private.h
//

// Private method declarations.

#if !defined(__YOZIO_PRIVATE__)
#define __YOZIO_PRIVATE__ 1

#import "Yozio.h"

#define UNCAUGHT_EXCEPTION_CATEGORY @"uncaught"

// Set to true to show log messages.
#define YOZIO_LOG true

// Payload keys.
#define P_ENVIRONMENT @"e"
#define P_DIGEST @"di"
#define P_DEVICE_ID @"de"
#define P_HARDWARE @"h"
#define P_OPERATING_SYSTEM @"os"
#define P_SCHEMA_VERSION @"s"
#define P_COUNTRY @"c"
#define P_LANGUAGE @"l"
#define P_TIMEZONE @"t"
#define P_COUNT @"ct"
#define P_PAYLOAD @"p"

// Payload data entry keys.
#define D_TYPE @"t"
#define D_KEY @"k"
#define D_VALUE @"v"
#define D_CATEGORY @"c"
#define D_DEVICE_ORIENTATION @"o"
#define D_UI_ORIENTATION @"uo"
#define D_USER_ID @"u"
#define D_APP_VERSION @"a"
#define D_SESSION_ID @"s"
#define D_EXPERIMENTS @"e"
#define D_TIMESTAMP @"ts"
#define D_ID @"id"

// Instrumentation entry types.
#define T_TIMER @"t"
#define T_FUNNEL @"f"
#define T_REVENUE @"r"
#define T_ACTION @"a"
#define T_ERROR @"e"
#define T_COLLECT @"m"

// Orientations strings.
#define ORIENT_PORTRAIT @"p"
#define ORIENT_PORTRAIT_UPSIDE_DOWN @"pu"
#define ORIENT_LANDSCAPE_LEFT @"ll"
#define ORIENT_LANDSCAPE_RIGHT @"lr"
#define ORIENT_FACE_UP @"fu"
#define ORIENT_FACE_DOWN @"fd"
#define ORIENT_UNKNOWN @"u"

// TODO(jt): make these numbers configurable instead of macros
// The number of items in the queue before forcing a flush.
#define FLUSH_DATA_COUNT 15
// XX_DATA_LIMIT describes the required number of items in the queue before that instrumentation
// event type starts being dropped.
#define TIMER_DATA_LIMIT 5000
#define ACTION_DATA_LIMIT 5000
#define FUNNEL_DATA_LIMIT 7000
#define REVENUE_DATA_LIMIT 100000
#define ERROR_DATA_LIMIT 5000
#define COLLECT_DATA_LIMIT 5000
// Time interval before automatically flushing the data queue.
#define FLUSH_INTERVAL_SEC 15

// Mobile configuration data keys.
#define CONFIG_CONFIG @"config"
#define CONFIG_EXPERIMENTS @"experiments"

#define DATA_QUEUE_FILE [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]
#define UUID_KEYCHAIN_USERNAME @"UUID"
#define KEYCHAIN_SERVICE @"yozio"

@interface Yozio()
{
  NSString *_serverUrl;
  NSString *_userId;
  NSString *_env;
  NSString *_appVersion;
  
  NSString *deviceId;
  NSString *hardware;
  NSString *os;
  NSString *sessionId;
  NSString *schemaVersion;
  NSString *experimentsStr;
  
  NSTimer *flushTimer;
  NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSInteger dataCount;
  NSMutableDictionary *timers;
  NSMutableDictionary *config;
  
  // Cached variables.
  NSDateFormatter *dateFormatter;
}

// User variables that need to be set by user.
@property(nonatomic, retain) NSString *_serverUrl;
@property(nonatomic, retain) NSString *_userId;
@property(nonatomic, retain) NSString *_env;
@property(nonatomic, retain) NSString *_appVersion;
// User variables that can be figured out.
@property(nonatomic, retain) NSString *deviceId;
@property(nonatomic, retain) NSString *hardware;
@property(nonatomic, retain) NSString *os;
@property(nonatomic, retain) NSString *sessionId;
@property(nonatomic, retain) NSString *schemaVersion;
@property(nonatomic, retain) NSString *experimentsStr;
// Internal variables.
@property(nonatomic, retain) NSTimer *flushTimer;
@property(nonatomic, retain) NSMutableArray *dataQueue;
@property(nonatomic, retain) NSArray *dataToSend;
@property(nonatomic, assign) NSInteger dataCount;
@property(nonatomic, retain) NSMutableDictionary *timers;
@property(nonatomic, retain) NSMutableDictionary *config;
// Cached variables.
@property(nonatomic, retain) NSDateFormatter *dateFormatter;

+ (Yozio *)getInstance; // Used for testing.
+ (void)log:(NSString *)format, ...;
// Notification observer methods.
- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification;
- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification;
- (void)applicationWillTerminate:(NSNotificationCenter *)notification;
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
- (NSString *)loadOrCreateDeviceId;
- (BOOL)storeDeviceId:(NSString *)uuid;
- (NSString *)makeUUID;
- (NSString *)deviceOrientation;
- (NSString *)uiOrientation;
- (void)updateConfig;

@end

#endif /* ! __YOZIO_PRIVATE__ */
