//
//  Yozio_Private.h
//

// Private method declarations.

#if !defined(__YOZIO_PRIVATE__)
#define __YOZIO_PRIVATE__ 1

#import "Yozio.h"

#define YOZIO_BEACON_SCHEMA_VERSION @"1"
#define YOZIO_TRACKING_SERVER_URL @"ec2-50-18-34-219.us-west-1.compute.amazonaws.com:8080"
#define YOZIO_CONFIGURATION_SERVER_URL @"c.yozio.com"

// Set to true to show log messages.
#define YOZIO_LOG true

// Payload keys.
#define YOZIO_P_SCHEMA_VERSION @"sv"
#define YOZIO_P_DIGEST @"di"
#define YOZIO_P_APP_KEY @"ak"
#define YOZIO_P_ENVIRONMENT @"env"
#define YOZIO_P_DEVICE_ID @"did"
#define YOZIO_P_HARDWARE @"hw"
#define YOZIO_P_OPERATING_SYSTEM @"os"
#define YOZIO_P_COUNTRY @"ctry"
#define YOZIO_P_LANGUAGE @"lg"
#define YOZIO_P_TIMEZONE @"tz"
// TODO: UDID
// TODO: MAC
#define YOZIO_P_PAYLOAD_COUNT @"plc"
#define YOZIO_P_PAYLOAD @"pl"

// Payload data entry keys.
#define YOZIO_D_TYPE @"tp"
#define YOZIO_D_NAME @"en"
#define YOZIO_D_REVENUE @"rev"
#define YOZIO_D_REVENUE_CURRENCY @"revc"
#define YOZIO_D_TIME_INTERVAL @"ti"
#define YOZIO_D_DEVICE_ORIENTATION @"dot"
#define YOZIO_D_UI_ORIENTATION @"uot"
#define YOZIO_D_APP_VERSION @"av"
#define YOZIO_D_USER_ID @"uid"
#define YOZIO_D_SESSION_ID @"sid"
#define YOZIO_D_EXPERIMENTS @"exp"
#define YOZIO_D_TIMESTAMP @"ts"
#define YOZIO_D_DATA_COUNT @"dc"

// Instrumentation entry types.
#define YOZIO_T_TIMER @"t"
#define YOZIO_T_REVENUE @"r"
#define YOZIO_T_ACTION @"a"
#define YOZIO_T_ERROR @"e"

// Orientations strings.
#define YOZIO_ORIENT_PORTRAIT @"p"
#define YOZIO_ORIENT_PORTRAIT_UPSIDE_DOWN @"pu"
#define YOZIO_ORIENT_LANDSCAPE_LEFT @"ll"
#define YOZIO_ORIENT_LANDSCAPE_RIGHT @"lr"
#define YOZIO_ORIENT_FACE_UP @"fu"
#define YOZIO_ORIENT_FACE_DOWN @"fd"
#define YOZIO_ORIENT_UNKNOWN @"u"

// The number of seconds of inactivity before a new session is started.
#define YOZIO_SESSION_INACTIVITY_THRESHOLD 1800

// The number of items in the queue before forcing a flush.
#define YOZIO_FLUSH_DATA_COUNT 15
// Time interval before automatically flushing the data queue.
#define YOZIO_FLUSH_INTERVAL_SEC 15

// XX_DATA_LIMIT describes the required number of items in the queue before that instrumentation
// event type starts being dropped.
#define YOZIO_TIMER_DATA_LIMIT 5000
#define YOZIO_ACTION_DATA_LIMIT 5000
#define YOZIO_REVENUE_DATA_LIMIT 100000
#define YOZIO_ERROR_DATA_LIMIT 5000

// Mobile configuration data keys.
#define YOZIO_CONFIG_KEY @"config"
#define YOZIO_CONFIG_EXPERIMENTS_KEY @"experiments"

#define YOZIO_DATA_QUEUE_FILE [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]
#define YOZIO_SESSION_FILE [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SessionData.plist"]
#define YOZIO_UUID_KEYCHAIN_USERNAME @"yozioUuid"
#define YOZIO_KEYCHAIN_SERVICE @"yozioKeychain"

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
  NSDate *lastActiveTime;
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
@property(nonatomic, retain) NSDate *lastActiveTime;
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
- (NSString *)notNil:(NSString *)str;

// Instrumentation data helper methods.
- (NSString *)timeStampString;
- (NSString *)deviceOrientation;
- (NSString *)uiOrientation;
- (void)updateSessionId;
- (void)updateCountryName;
- (void)updateLanguage;
- (void)updateTimezone;

// File system helper methods.
- (void)saveUnsentData;
- (void)loadUnsentData;
- (void)saveSessionData;
- (void)loadSessionData;

// UUID helper methods.
- (NSString *)loadOrCreateDeviceId;
- (BOOL)storeDeviceId:(NSString *)uuid;
- (NSString *)makeUUID;

// Configuration related helper methods.
- (void)updateConfig;

@end

#endif /* ! __YOZIO_PRIVATE__ */
