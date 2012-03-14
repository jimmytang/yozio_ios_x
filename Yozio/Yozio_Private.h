//
//  Yozio_Private.h
//

// Private method declarations.

#if !defined(__YOZIO_PRIVATE__)
#define __YOZIO_PRIVATE__ 1

#import "Yozio.h"

#define TRACKING_SERVER_URL @"ec2-50-18-34-219.us-west-1.compute.amazonaws.com:8080"
#define CONFIGURATION_SERVER_URL @"c.yozio.com"





#define UNCAUGHT_EXCEPTION_CATEGORY @"uncaught"

// Set to true to show log messages.
#define YOZIO_LOG true

// Payload keys.
#define P_APP_KEY @"ak"
#define P_ENVIRONMENT @"env"
#define P_DIGEST @"di"
#define P_DEVICE_ID @"de"
#define P_HARDWARE @"h"
#define P_OPERATING_SYSTEM @"os"
#define P_SCHEMA_VERSION @"sv"
#define P_COUNTRY @"c"
#define P_LANGUAGE @"l"
#define P_TIMEZONE @"tz"
#define P_TIME_PERIOD @"tp"
#define P_CARRIER @"car"
#define P_CAMPAIGN_SOURCE @"cs"
#define P_CAMPAIGN_MEDIUM @"cm"
#define P_CAMPAIGN_TERM @"ct"
#define P_CAMPAIGN_CONTENT @"cc"
#define P_CAMPAIGN_NAME @"cn"

// Payload data entry keys.
#define D_TYPE @"t"
#define D_NAME @"n"
#define D_REVENUE @"r"
#define D_REVENUE_CURRENCY @"rc"
#define D_CATEGORY @"c"
#define D_DEVICE_ORIENTATION @"o"
#define D_UI_ORIENTATION @"uo"
#define D_USER_ID @"u"
#define D_APP_VERSION @"v"
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
#define FLUSH_DATA_COUNT 1
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
  NSString *_appKey;
  NSString *_userId;
  NSString *_env;
  NSString *_appVersion;
  NSString *_campaignSource;
  NSString *_campaignMedium;
  NSString *_campaignTerm;
  NSString *_campaignContent;
  NSString *_campaignName;

  NSString *deviceId;
  NSString *hardware;
  NSString *os;
  NSString *sessionId;
  NSString *schemaVersion;
  NSString *countryName;
  NSString *language;
  NSNumber *timezone;
  NSString *experimentsStr;
  
  NSTimer *flushTimer;
  NSMutableArray *dataQueue;
  NSMutableDictionary *dataToSend;
  NSInteger dataCount;
  NSMutableDictionary *timers;
  NSMutableDictionary *config;
  
  // Cached variables.
  NSDateFormatter *dateFormatter;
}

// User variables that need to be set by user.
@property(nonatomic, retain) NSString *_appKey;
@property(nonatomic, retain) NSString *_userId;
@property(nonatomic, retain) NSString *_env;
@property(nonatomic, retain) NSString *_appVersion;
@property(nonatomic, retain) NSString *_campaignSource;
@property(nonatomic, retain) NSString *_campaignMedium;
@property(nonatomic, retain) NSString *_campaignTerm;
@property(nonatomic, retain) NSString *_campaignContent;
@property(nonatomic, retain) NSString *_campaignName;
// User variables that can be figured out.
@property(nonatomic, retain) NSString *deviceId;
@property(nonatomic, retain) NSString *hardware;
@property(nonatomic, retain) NSString *os;
@property(nonatomic, retain) NSString *sessionId;
@property(nonatomic, retain) NSString *schemaVersion;
@property(nonatomic, retain) NSString *countryName;
@property(nonatomic, retain) NSString *language;
@property(nonatomic, retain) NSNumber *timezone;
@property(nonatomic, retain) NSString *experimentsStr;
// Internal variables.
@property(nonatomic, retain) NSTimer *flushTimer;
@property(nonatomic, retain) NSMutableArray *dataQueue;
@property(nonatomic, retain) NSMutableDictionary *dataToSend;
@property(nonatomic, assign) NSInteger dataCount;
@property(nonatomic, retain) NSMutableDictionary *timers;
@property(nonatomic, retain) NSMutableDictionary *config;
// Cached variables.
@property(nonatomic, retain) NSDateFormatter *dateFormatter;

+ (Yozio *)getInstance; // Used for testing.
+ (void)log:(NSString *)format, ...;
// Notification observer methods.
- (void)onApplicationWillTerminate:(NSNotification *)notification;
- (void)onApplicationWillResignActive:(NSNotification *)notification;
- (void)onApplicationWillEnterForeground:(NSNotification *)notification;
- (void)onApplicationDidEnterBackground:(NSNotification *)notification;
// Helper methods.
- (BOOL)validateConfiguration;
- (void)doCollect:(NSString *)type
             name:(NSString *)name
            amount:(NSString *)amount
         category:(NSString *)category
         maxQueue:(NSInteger)maxQueue;
- (void)checkDataQueueSize;
- (void)doFlush;
- (NSString *)buildPayload;
- (NSString *)timeStampString;
- (NSString *)deviceOrientation;
- (NSString *)uiOrientation;
- (void)updateCountryName;
- (void)updateLanguage;
- (void)updateTimezone;
- (void)saveUnsentData;
- (void)loadUnsentData;
- (NSString *)loadOrCreateDeviceId;
- (BOOL)storeDeviceId:(NSString *)uuid;
- (NSString *)makeUUID;
- (void)updateConfig;

@end

#endif /* ! __YOZIO_PRIVATE__ */
