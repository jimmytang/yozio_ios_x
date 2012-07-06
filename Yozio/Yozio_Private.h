//
//  Yozio_Private.h
//

#if !defined(__YOZIO_PRIVATE__)
#define __YOZIO_PRIVATE__ 1

#import "Yozio.h"

#define YOZIO_BEACON_SCHEMA_VERSION @"1"
#define YOZIO_DEFAULT_BASE_URL @"http://yoz.io"
#define YOZIO_GET_CONFIG_ROUTE @"/api/viral/v1/get_config"
#define YOZIO_GET_URL_ROUTE @"/api/viral/v1/get_url"
#define YOZIO_BATCH_EVENTS_ROUTE @"/api/viral/v1/batch_events"

#define YOZIO_GET_URL_P_APP_KEY @"app_key"
#define YOZIO_GET_URL_P_YOZIO_UDID @"yozio_udid"
#define YOZIO_GET_URL_P_DEVICE_TYPE @"device_type"
#define YOZIO_GET_URL_P_LINK_NAME @"link_name"
#define YOZIO_GET_URL_P_DEST_URL @"dest_url"
#define YOZIO_BATCH_EVENTS_P_DATA @"data"


// Set to true to show log messages.
#define YOZIO_LOG false

// Payload keys.
#define YOZIO_P_APP_KEY @"ak"
#define YOZIO_P_UDID @"ud"
#define YOZIO_P_DEVICE_TYPE @"dt"
#define YOZIO_P_PAYLOAD @"pl"
#define YOZIO_P_MAC_ADDRESS @"ma"
#define YOZIO_P_OPEN_UDID @"ou"
#define YOZIO_P_OS_VERSION @"osv"
#define YOZIO_P_COUNTRY_CODE @"cc"
#define YOZIO_P_LANGUAGE_CODE @"lc"
#define YOZIO_P_IS_JAILBROKEN @"ijb"
#define YOZIO_P_OPEN_UDID_COUNT @"ouc"
#define YOZIO_P_DISPLAY_MULTIPLIER @"dm"
#define YOZIO_P_HARDWARE @"hw"
#define YOZIO_P_APP_VERSION @"av"

// Payload data entry keys.
#define YOZIO_D_TYPE @"tp"
#define YOZIO_D_LINK_NAME @"ln"
#define YOZIO_D_TIMESTAMP @"ts"

// Mobile configuration data keys.
#define YOZIO_URLS_KEY @"urls"

#define YOZIO_DATA_QUEUE_FILE [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"YozioLib_SavedData.plist"]

// The number of items in the queue before forcing a flush.
#define YOZIO_FLUSH_DATA_COUNT 1

// The number of items to flush at a time
#define YOZIO_FLUSH_DATA_SIZE 20

// Actions
#define YOZIO_VIEWED_LINK_ACTION @"11"
#define YOZIO_SHARED_LINK_ACTION @"12"
#define YOZIO_OPENED_APP_ACTION @"5"

// XX_DATA_LIMIT describes the required number of items in the queue before that instrumentation
// event type starts being dropped.
#define YOZIO_ACTION_DATA_LIMIT 200

#define YOZIO_DEVICE_TYPE_IOS @"2"

@interface Yozio()
{
  // User set instrumentation variables.
  NSString *_appKey;
  NSString *_secretKey;
  NSString *_userName;

  // Automatically determined instrumentation variables.
  NSString *deviceId;
  NSString *hardware;
  NSString *osVersion;
  NSString *countryCode;
  NSString *languageCode;
  
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
@property(nonatomic, retain) NSString *osVersion;
@property(nonatomic, retain) NSString *countryCode;
@property(nonatomic, retain) NSString *languageCode;

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
- (NSString *)buildPayload;
- (NSString *)notNil:(NSString *)str;
- (NSDictionary *)dictNotNil:(NSDictionary *)dict;

// Instrumentation data helper methods.
- (NSString *)timeStampString;

// File system helper methods.
- (void)saveUnsentData;
- (void)loadUnsentData;

@end

#endif /* ! __YOZIO_PRIVATE__ */
