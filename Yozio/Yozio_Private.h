//
//  Yozio_Private.h
//

#if !defined(__YOZIO_PRIVATE__)
#define __YOZIO_PRIVATE__ 1

#import "Yozio.h"

#define YOZIO_BEACON_SCHEMA_VERSION @"1"
#define YOZIO_TRACKING_SERVER_URL @"yoz.io"
#define YOZIO_CONFIGURATION_SERVER_URL @"yoz.io"

// Set to true to show log messages.
#define YOZIO_LOG true

// Payload keys.
#define YOZIO_P_SCHEMA_VERSION @"sv"
#define YOZIO_P_APP_KEY @"ak"
#define YOZIO_P_DEVICE_ID @"udid"
#define YOZIO_P_HARDWARE @"hw"
#define YOZIO_P_OPERATING_SYSTEM @"os"
#define YOZIO_P_COUNTRY @"ctry"
#define YOZIO_P_LANGUAGE @"lg"
#define YOZIO_P_TIMEZONE @"tz"
#define YOZIO_P_DEVICE_NAME @"dn"
#define YOZIO_P_PAYLOAD_COUNT @"plc"
#define YOZIO_P_PAYLOAD @"pl"

// Payload data entry keys.
#define YOZIO_D_TYPE @"tp"
#define YOZIO_D_LINK_NAME @"ln"
#define YOZIO_D_TIMESTAMP @"ts"
#define YOZIO_D_DATA_COUNT @"dc"

// Mobile configuration data keys.
#define YOZIO_URLS_KEY @"urls"

#define YOZIO_DATA_QUEUE_FILE [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]

// The number of items in the queue before forcing a flush.
#define YOZIO_FLUSH_DATA_COUNT 1

// Actions
#define YOZIO_VIEWED_LINK_ACTION @"11"
#define YOZIO_SHARED_LINK_ACTION @"12"
#define YOZIO_OPENED_APP_ACTION @"14"

// XX_DATA_LIMIT describes the required number of items in the queue before that instrumentation
// event type starts being dropped.
#define YOZIO_ACTION_DATA_LIMIT 5000


@interface Yozio()
{
  // User set instrumentation variables.
  NSString *_appKey;
  NSString *_secretKey;
  NSString *_userName;

  // Automatically determined instrumentation variables.
  NSString *deviceId;
  NSString *countryName;

  // Internal variables.
  NSInteger dataCount;
  NSMutableArray *dataQueue;
  NSArray *dataToSend;
  NSMutableDictionary *config;
  NSDateFormatter *dateFormatter;
  BOOL stopBlocking;
}

// User set instrumentation variables.
@property(nonatomic, retain) NSString *_appKey;
@property(nonatomic, retain) NSString *_secretKey;

// Automatically determined instrumentation variables.
@property(nonatomic, retain) NSString *deviceId;
@property(nonatomic, retain) NSString *hardware;
@property(nonatomic, retain) NSString *os;
@property(nonatomic, retain) NSString *countryName;
@property(nonatomic, retain) NSString *language;
@property(nonatomic, retain) NSNumber *timezone;
@property(nonatomic, retain) NSString *deviceName;

// Internal variables.
@property(nonatomic, assign) NSInteger dataCount;
@property(nonatomic, retain) NSMutableArray *dataQueue;
@property(nonatomic, retain) NSArray *dataToSend;
@property(nonatomic, retain) NSMutableDictionary *config;
@property(nonatomic, retain) NSDateFormatter *dateFormatter;
@property(nonatomic, assign) BOOL stopBlocking;

+ (Yozio *)getInstance; 
+ (void)log:(NSString *)format, ...;
+ (void)openedApp;

// Notification observer methods.
- (void)onApplicationWillTerminate:(NSNotification *)notification;

// Data collection helper methods.
- (BOOL)validateConfiguration;
- (void)doCollect:(NSString *)name
         linkName:(NSString *)linkName
         maxQueue:(NSInteger)maxQueue;
- (void)checkDataQueueSize;
- (void)doFlush;
- (NSString *)buildPayload:(NSData *)iv;
- (NSString *)notNil:(NSString *)str;
- (NSDictionary *)dictNotNil:(NSDictionary *)dict;

// Instrumentation data helper methods.
- (NSString *)timeStampString;
- (void)updateCountryName;
- (void)updateLanguage;
- (void)updateTimezone;

// File system helper methods.
- (void)saveUnsentData;
- (void)loadUnsentData;

// Configuration related helper methods.
- (void)updateConfig;

@end

#endif /* ! __YOZIO_PRIVATE__ */
