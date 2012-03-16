//
//  Yozio_Private.h
//

// Private method declarations.

#if !defined(__YOZIO_PRIVATE__)
#define __YOZIO_PRIVATE__ 1

#import "Yozio.h"

#define YOZIO_BEACON_SCHEMA_VERSION @"1"
#define TRACKING_SERVER_URL @"ec2-50-18-34-219.us-west-1.compute.amazonaws.com:8080"
#define CONFIGURATION_SERVER_URL @"c.yozio.com"

// Set to true to show log messages.
#define YOZIO_LOG true

// Payload keys.
#define P_SCHEMA_VERSION @"sv"
#define P_DIGEST @"di"
#define P_APP_KEY @"ak"
#define P_ENVIRONMENT @"env"
#define P_DEVICE_ID @"de"
#define P_HARDWARE @"h"
#define P_OPERATING_SYSTEM @"os"
#define P_COUNTRY @"c"
#define P_LANGUAGE @"l"
#define P_TIMEZONE @"tz"
#define P_PAYLOAD_COUNT @"pldc"
#define P_PAYLOAD @"pld"

// Payload data entry keys.
#define D_TYPE @"t"
#define D_NAME @"n"
#define D_REVENUE @"r"
#define D_REVENUE_CURRENCY @"rc"
#define D_TIME_INTERVAL @"ti"
#define D_DEVICE_ORIENTATION @"o"
#define D_UI_ORIENTATION @"uo"
#define D_APP_VERSION @"v"
#define D_USER_ID @"u"
#define D_SESSION_ID @"s"
#define D_EXPERIMENTS @"e"
#define D_TIMESTAMP @"ts"
#define D_DATA_COUNT @"dc"

// Instrumentation entry types.
#define T_TIMER @"t"
#define T_REVENUE @"r"
#define T_ACTION @"a"
#define T_ERROR @"e"

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
#define REVENUE_DATA_LIMIT 100000
#define ERROR_DATA_LIMIT 5000
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
  // User set instrumentation variables.
  NSString *_appKey;
  NSString *_secretKey;
  NSString *_userId;
  NSString *_appVersion;

  // Automatically determined instrumentation variables.
  NSString *deviceId;
  NSString *hardware;
  NSString *os;
  NSString *sessionId;
  NSString *countryName;
  NSString *language;
  NSNumber *timezone;
  NSString *experimentsStr;
  NSString *environment;
  
  // Internal variables.
  NSTimer *flushTimer;
  NSInteger dataCount;
  NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSMutableDictionary *timers;
  NSMutableDictionary *config;
  NSDateFormatter *dateFormatter;
}

// User set instrumentation variables.
@property(nonatomic, retain) NSString *_appKey;
@property(nonatomic, retain) NSString *_secretKey;
@property(nonatomic, retain) NSString *_userId;
@property(nonatomic, retain) NSString *_appVersion;

// Automatically determined instrumentation variables.
@property(nonatomic, retain) NSString *deviceId;
@property(nonatomic, retain) NSString *hardware;
@property(nonatomic, retain) NSString *os;
@property(nonatomic, retain) NSString *sessionId;
@property(nonatomic, retain) NSString *countryName;
@property(nonatomic, retain) NSString *language;
@property(nonatomic, retain) NSNumber *timezone;
@property(nonatomic, retain) NSString *experimentsStr;
@property(nonatomic, retain) NSString *environment;

// Internal variables.
@property(nonatomic, retain) NSTimer *flushTimer;
@property(nonatomic, assign) NSInteger dataCount;
@property(nonatomic, retain) NSMutableArray *dataQueue;
@property(nonatomic, retain) NSArray *dataToSend;
@property(nonatomic, retain) NSMutableDictionary *timers;
@property(nonatomic, retain) NSMutableDictionary *config;
@property(nonatomic, retain) NSDateFormatter *dateFormatter;

+ (Yozio *)getInstance; 
+ (void)log:(NSString *)format, ...;

// Notification observer methods.
- (void)onApplicationWillTerminate:(NSNotification *)notification;
- (void)onApplicationWillResignActive:(NSNotification *)notification;
- (void)onApplicationWillEnterForeground:(NSNotification *)notification;
- (void)onApplicationDidEnterBackground:(NSNotification *)notification;

// Data collection helper methods.
- (BOOL)validateConfiguration;
- (void)doCollect:(NSString *)type
             name:(NSString *)name
           amount:(NSString *)amount
     timeInterval:(NSString *)timeInterval
         maxQueue:(NSInteger)maxQueue;
- (void)checkDataQueueSize;
- (void)doFlush;
- (NSString *)buildPayload;

// Instrumentation data helper methods.
- (NSString *)timeStampString;
- (NSString *)deviceOrientation;
- (NSString *)uiOrientation;
- (void)updateCountryName;
- (void)updateLanguage;
- (void)updateTimezone;

// File system helper methods.
- (void)saveUnsentData;
- (void)loadUnsentData;

// UUID helper methods.
- (NSString *)loadOrCreateDeviceId;
- (BOOL)storeDeviceId:(NSString *)uuid;
- (NSString *)makeUUID;

// Configuration related helper methods.
- (void)updateConfig;

@end

#endif /* ! __YOZIO_PRIVATE__ */
