/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */

#import "Yozio.h"
#import "Yozio_Private.h"
#import "YozioConfigureTests.h"
#import "YozioRequestManagerMock.h"
#import "YozioRequestManager.h"
#import <OCMock/OCMock.h>
#import <objc/runtime.h>
#import "Kiwi.h"
#import "KWIntercept.h"
#import "YOpenUDID.h"

@implementation YozioConfigureTests


static char mockDateKey;
static NSString *mockUUID = @"mock UUID";
static Method originalMethod = nil;
static Method swizzleMethod = nil;
id mock;


// setup
- (void)setUp
{
  NSString *sDate = @"Sun Jul 17 07:48:34 +0000 2011";
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"EEE MMM dd HH:mm:ss ZZZ yyyy"];
  NSDate *stubbedDate  = [dateFormatter dateFromString:sDate];

  originalMethod = class_getClassMethod([NSDate class], @selector(date));
  swizzleMethod = class_getInstanceMethod([self class], @selector(mockDateSwizzle));
  method_exchangeImplementations(originalMethod, swizzleMethod);
  [self setMockDate:stubbedDate];
  
  mock = [OCMockObject partialMockForObject:[Yozio getInstance]];
  [[[mock stub] andReturn:mockUUID] eventID];
}

- (void)tearDown
{
  NSFileManager *filemgr = [NSFileManager defaultManager];
  
  [filemgr removeItemAtPath:YOZIO_DATA_QUEUE_FILE error: NULL];
}

// tests

- (void)testConfigureWithNullAppKey
{
  STAssertThrowsSpecific([Yozio configure:nil secretKey:@"secret key"],
                         NSException,
                         @"Invalid app key"
                         );
}

- (void)testConfigureWithNullSecretKey
{
  STAssertThrowsSpecific([Yozio configure:@"app key" secretKey:nil],
                         NSException,
                         @"Invalid secret key"
                         );
  
}

- (void)testConfigureSetsAppKeyAndSecretKey
{
  Yozio *instance = [Yozio getInstance];
  [Yozio configure:@"app key" secretKey:@"secret key"];
  instance = [Yozio getInstance];
  STAssertEquals(instance._appKey, @"app key", @"app keys don't match");
  STAssertEquals(instance._secretKey, @"secret key", @"secret keys don't match");
}

- (void)testConfigureLoadsUnsentData
{
  NSMutableArray *expectedDataQueue = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
  [NSKeyedArchiver archiveRootObject:expectedDataQueue
                              toFile:YOZIO_DATA_QUEUE_FILE];
  [Yozio configure:@"app key" secretKey:@"secret key"];
  Yozio *instance = [Yozio getInstance];
  STAssertTrue([[instance.dataQueue objectAtIndex:0] isEqualToDictionary:[expectedDataQueue objectAtIndex:0]],
                 @"dataQueues don't match");
}


- (void)testConfigureCreatesAnOpenAppEventWithFirstOpenSetToFalse
{
  NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
  NSString *plistPath = [rootPath stringByAppendingPathComponent:@"yozio_first_open_tracker.plist"];
  NSData *plistData = [NSData data];
  [plistData writeToFile:plistPath atomically:YES];
  
  [Yozio stub:@selector(getMACAddress) andReturn:@"mac address"];
  [YOpenUDID stub:@selector(getOpenUDIDSlotCount) andReturn:theValue(1)];
  [YOpenUDID stub:@selector(value) andReturn:@"open udid value"];
  [Yozio stub:@selector(bundleVersion) andReturn:@"bundle version"];
  Yozio *instance = [Yozio getInstance];
  [instance stub:@selector(timeStampString) andReturn:@"time stamp string"];
  instance._appKey = @"app key";
  instance.dataToSend = [NSMutableArray arrayWithObjects:
                         [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil],
                         [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil], nil];
  instance.deviceId = @"device id";
  
  YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
  id yrmMock = [YozioRequestManager nullMock];
  [YozioRequestManager setInstance:yrmMock];
  KWCaptureSpy *urlSpy = [yrmMock captureArgument:@selector(urlRequest:body:timeOut:handler:) atIndex:0];
  KWCaptureSpy *urlParamsSpy = [yrmMock captureArgument:@selector(urlRequest:body:timeOut:handler:) atIndex:1];
  
  NSMutableDictionary *expectedOpenEvent =
  [NSMutableDictionary dictionaryWithObjectsAndKeys:
   @"mock UUID", @"event_identifier",
   @"5", @"event_type",
   [NSNumber numberWithBool:NO], @"first_open",
   @"", @"link_name",
   @"", @"channel",
   @"time stamp string", @"timestamp",
   nil];
  
  NSString *expectedJsonPayload = [Yozio toJSON:[NSDictionary dictionaryWithObjectsAndKeys:
                                    @"2", @"device_type",
                                    [NSArray arrayWithObject:expectedOpenEvent], @"payload",
                                    @"Unknown", @"hardware",
                                    @"open udid value", @"open_udid",
                                    @"5.0", @"os_version",
                                    @"device id", @"yozio_udid",
                                    @"1", @"open_udid_count",
                                    @"1.000000", @"display_multiplier",
                                    @"mac address", @"mac_address",
                                    @"app key", @"app_key",
                                    @"bundle version", @"app_version",
                                    @"0", @"is_jailbroken",
                                    nil]];
  
  [Yozio configure:@"app key" secretKey:@"secret key"];
  
  NSString *urlString = urlSpy.argument;
  NSString *expectedUrlString = [NSString stringWithFormat:@"http://yoz.io/api/sdk/v1/opened_app"];
  NSDictionary *urlParams = urlParamsSpy.argument;
  NSDictionary *expectedUrlParams = [NSDictionary dictionaryWithObject:expectedJsonPayload forKey:@"data"];
  
  STAssertTrue([urlString isEqualToString:expectedUrlString], @"path doesn't match");
  STAssertTrue([[Yozio toJSON:urlParams] isEqualToString:[Yozio toJSON:expectedUrlParams]], @"first_open flag doesn't match");
  [YozioRequestManager setInstance:yrmInstance];
}

- (void)testConfigureSetsConfigureCallbackAndReturnsReferrerLinkTags
{
  YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
  YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
  [YozioRequestManager setInstance:yrmMock];
  NSInteger statusCode = 200;
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                            statusCode:statusCode
                                                           HTTPVersion:@"HTTP/1.1"
                                                          headerFields:[NSDictionary dictionary]];
  
  NSDictionary *referrerLinkTags = [NSDictionary dictionaryWithObject:@"1" forKey:@"a"];
  yrmMock.body = [NSDictionary dictionaryWithObject:referrerLinkTags forKey:YOZIO_REFERRER_LINK_TAGS];
  yrmMock.response = response;

  __block NSDictionary *dict;
  Yozio *instance = [Yozio getInstance];
  instance.dataToSend = NULL;
  [instance.dataQueue addObject:@"1"];
  [Yozio configure:@"app key"
         secretKey:@"secret key"
          callback:^(NSDictionary * callbackDict){dict = callbackDict;}];
  [YozioRequestManager setInstance:yrmInstance];
  
  STAssertTrue([dict isEqualToDictionary:referrerLinkTags], @"dictionaries don't match");
}

- (void)testConfigureSetsConfigureCallbackAndReturnsEmptyDictionaryIfReferrerLinkTagsIsEmpty
{
  YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
  YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
  [YozioRequestManager setInstance:yrmMock];
  NSInteger statusCode = 200;
  NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                            statusCode:statusCode
                                                           HTTPVersion:@"HTTP/1.1"
                                                          headerFields:[NSDictionary dictionary]];
  
  yrmMock.body = [NSDictionary dictionary];
  yrmMock.response = response;
  
  __block NSDictionary *dict;
  Yozio *instance = [Yozio getInstance];
  instance.dataToSend = NULL;
  [instance.dataQueue addObject:@"1"];
  [Yozio configure:@"app key"
         secretKey:@"secret key"
          callback:^(NSDictionary * callbackDict){dict = callbackDict;}];
  [YozioRequestManager setInstance:yrmInstance];
  
  STAssertTrue([dict isEqualToDictionary:[NSDictionary dictionary]], @"dictionaries don't match");
}

- (void)testConfigureFlushesLoadedData
{
  [[mock expect] doFlush];
  [Yozio configure:@"app key" secretKey:@"secret key"];
  [mock verify];
}



// Test Helper Methods

// Mock Method, replaces [NSDate date]
- (NSDate *)mockDateSwizzle {
  return objc_getAssociatedObject([NSDate class], &mockDateKey);
}

// Convenience method so tests can set want they want [NSDate date] to return
- (void)setMockDate:(NSDate *)aMockDate {
  objc_setAssociatedObject([NSDate class], &mockDateKey, aMockDate, OBJC_ASSOCIATION_RETAIN);
}

- (void)setMockEventID:(NSString *)uuid {
  objc_setAssociatedObject([NSString class], &mockUUID, uuid, OBJC_ASSOCIATION_RETAIN);
}

@end
