//
//  YozioDoFlushTests.m
//  Yozio
//
//  Created by Jimmy Tang on 9/24/12.
//  Copyright (c) 2012 University of California at Berkeley. All rights reserved.
//

#import "YozioDoFlushTests.h"
#import "Yozio.h"
#import "Yozio_Private.h"
#import <OCMock/OCMock.h>
#import <OCMock/NSObject+ClassMock.h>
#import <objc/runtime.h>
#import "YSeriously.h"

@implementation YozioDoFlushTests

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
  NSLog(@"%d", [YSeriously isKindOfClass:[NSObject class]]);

}

- (void)tearDown
{
  NSFileManager *filemgr = [NSFileManager defaultManager];
  [filemgr removeItemAtPath:YOZIO_DATA_QUEUE_FILE error: NULL];
}


// ************************************
// TESTS
// ************************************

- (void) testDoFlushDoesNotFlushWhenDataQueueIsEmpty
{
  
}

- (void) testDoFlushDoesNotFlushWhenFlushing
{
  
}

- (void) testDoFlushDoesFlushCorrectAmountIfDataQueueIsGreaterThanFlushDataSize
{
  
}

- (void) testDoFlushDoesFlushCorrectAmountIfDataQueueIsLessThanFlushDataSize
{
  
}

- (void) testDoFlushSendsTheCorrectRequest
{
  
}

- (void) testDoFlushOn200ResponseRemovesFromDataQueueAndDataToSend
{
  
}

- (void) testDoFlushOn400ResponseRemovesFromDataQueueAndDataToSend
{
  
}

- (void) testDoFlushOnAnyOtherResponseRemovesFromOnlyDataToSend
{
  
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
