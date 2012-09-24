//
//  YozioTests.m
//  YozioTests
//
//
#import "Yozio.h"
#import "Yozio_Private.h"
#import "YozioConfigureTests.h"
#import "OCMock.h"
#import <objc/runtime.h>

@implementation YozioConfigureTests


static char mockDateKey;
static NSString *mockUUID = @"mock UUID";
Method originalMethod = nil;
Method swizzleMethod = nil;
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
  
  if ([filemgr removeItemAtPath:YOZIO_DATA_QUEUE_FILE error: NULL]  == YES)
    NSLog (@"Remove successful");
  else
    NSLog (@"Remove failed");

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


- (void)testConfigureCreatesAnOpenAppEvent
{
  NSMutableDictionary *expectedOpenEvent =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
    @"mock UUID", @"event_identifier",
    @"5", @"event_type",
    @"", @"link_name",
    @"2011-07-17 07:48:34", @"timestamp",
    nil];
  [Yozio configure:@"app key" secretKey:@"secret key"];
  Yozio *instance = [Yozio getInstance];
  STAssertTrue([[instance.dataQueue objectAtIndex:0] isEqualToDictionary:expectedOpenEvent],
               @"dataQueues don't match");

}

- (void)testConfigureFlushesLoadedData
{
  [[mock expect] doFlush];
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
