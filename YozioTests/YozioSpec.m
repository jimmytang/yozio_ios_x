#import "Kiwi.h"
#import "KWIntercept.h"
#import "Yozio.h"
#import "Yozio_Private.h"
#import "YozioRequestManager.h"
#import "YozioRequestManagerMock.h"
#import "YSeriously.h"
#import "YJSONKit.h"
#import "YOpenUDID.h"

SPEC_BEGIN(YozioSpec)

//describe(@"doFlush", ^{
//  context(@"", ^{
//    beforeEach(^{
//      [Yozio stub:@selector(getMACAddress) andReturn:@"mac address"];
//      [YOpenUDID stub:@selector(getOpenUDIDSlotCount) andReturn:theValue(1)];
//      [YOpenUDID stub:@selector(value) andReturn:@"open udid value"];
//      [Yozio stub:@selector(bundleVersion) andReturn:@"bundle version"];
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      instance.dataToSend = [NSMutableArray arrayWithObjects:
//                            [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil],
//                            [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil], nil];
//      instance.deviceId = @"device id";
//    });
//    
//    afterEach(^{
//      KWClearAllMessageSpies();
//      KWClearAllObjectStubs();
//    });
//
//    it(@"should not flush when the dataQueue is empty", ^{
//      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:handler:) withCount:0];
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      instance.dataQueue = [NSMutableArray array];
//      [instance doFlush];
//    });
//    
//    it(@"should flush when the dataQueue is not empty", ^{
//      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:handler:) withCount:1];
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      instance.dataQueue = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
//      instance.dataToSend = nil;
//      [instance doFlush];
//    });
//
//    it(@"should not flush when already flushing", ^{
//      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:handler:) withCount:0];
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      instance.dataQueue = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
//      instance.dataToSend = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
//      [instance doFlush];
//    });
//
//    it(@"should flush the correct amount if dataQueue is greater than flush data size", ^{
//      [YSeriously stub:@selector(get:handler:)];
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      instance.dataQueue = [NSMutableArray array];
//      for (int i = 0; i < 21; i++)
//      {
//        [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key1", nil]];
//      }
//      instance.dataToSend = nil;
//      [instance doFlush];
//      [[theValue([instance.dataToSend count]) should] equal:theValue(20)];
//    });
//
//    it(@"should flush the correct amount if dataQueue is less than flush data size", ^{
//      [YSeriously stub:@selector(get:handler:)];
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      instance.dataQueue = [NSMutableArray array];
//      for (int i = 0; i < 5; i++)
//      {
//        [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key1", nil]];
//      }
//      instance.dataToSend = nil;
//      [instance doFlush];
//      [[theValue([instance.dataToSend count]) should] equal:theValue(5)];
//    });
//
//    it(@"should flush the correct request", ^{
//      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//      id yrmMock = [YozioRequestManager nullMock];
//      [YozioRequestManager setInstance:yrmMock];
//      KWCaptureSpy *spy = [yrmMock captureArgument:@selector(urlRequest:handler:) atIndex:0];
//
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key1", nil]];
//      instance.dataToSend = nil;
//      [instance doFlush];
//
//      NSString *expectedJsonPayload = [[NSDictionary dictionaryWithObjectsAndKeys:
//                                        @"2", @"device_type",
//                                        instance.dataToSend, @"payload",
//                                        @"Unknown", @"hardware",
//                                        @"open udid value", @"open_udid",
//                                        @"5.1", @"os_version",
//                                        @"IOS-v2.4", @"sdk_version",
//                                        @"device id", @"yozio_udid",
//                                        @"1", @"open_udid_count",
//                                        @"1.000000", @"display_multiplier",
//                                        @"mac address", @"mac_address",
//                                        @"app key", @"app_key",
//                                        @"bundle version", @"app_version",
//                                        @"0", @"is_jailbroken",
//                                        nil] JSONString];
//
//      NSString *urlString = spy.argument;
//      NSString *expectedUrlString = [NSString stringWithFormat:@"http://yoz.io/api/sdk/v1/batch_events?data=%@", [Yozio encodeToPercentEscapeString:expectedJsonPayload]];
//      [[urlString should] equal:expectedUrlString];
//      [YozioRequestManager setInstance:yrmInstance];
//    });
//    
//    it(@"should remove from dataQueue and dataToSend on a 200 response", ^{
//      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//      id yrmMock = [YozioRequestManager nullMock];
//      [YozioRequestManager setInstance:yrmMock];
//      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:handler:) atIndex:1];
//      
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
//      instance.dataToSend = nil;
//      [instance doFlush];
//      
//      NSInteger statusCode = 200;
//      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
//                                                                statusCode:statusCode
//                                                               HTTPVersion:@"HTTP/1.1"
//                                                              headerFields:[NSDictionary dictionary]];
//      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
//      block(nil, response, nil);
//      
//      [[instance.dataQueue should] equal:[NSMutableArray array]];
//      [instance.dataToSend shouldBeNil];
//      
//      [YozioRequestManager setInstance:yrmInstance];
//    });
//    
//    it(@"should remove from dataQueue and dataToSend on a 400 response", ^{
//      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//      id yrmMock = [YozioRequestManager nullMock];
//      [YozioRequestManager setInstance:yrmMock];
//      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:handler:) atIndex:1];
//      
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
//      instance.dataToSend = nil;
//      [instance doFlush];
//      
//      NSInteger statusCode = 400;
//      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
//                                                                statusCode:statusCode
//                                                               HTTPVersion:@"HTTP/1.1"
//                                                              headerFields:[NSDictionary dictionary]];
//      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
//      block(nil, response, nil);
//      
//      [[instance.dataQueue should] equal:[NSMutableArray array]];
//      [instance.dataToSend shouldBeNil];
//      
//      [YozioRequestManager setInstance:yrmInstance];
//    });
//    
//    it(@"should remove from dataQueue and dataToSend on a 400 response", ^{
//      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//      id yrmMock = [YozioRequestManager nullMock];
//      [YozioRequestManager setInstance:yrmMock];
//      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:handler:) atIndex:1];
//      
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
//      instance.dataToSend = nil;
//      [instance doFlush];
//      
//      NSInteger statusCode = 400;
//      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
//                                                                statusCode:statusCode
//                                                               HTTPVersion:@"HTTP/1.1"
//                                                              headerFields:[NSDictionary dictionary]];
//      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
//      block(nil, response, nil);
//      
//      [[instance.dataQueue should] equal:[NSMutableArray array]];
//      [instance.dataToSend shouldBeNil];
//      
//      [YozioRequestManager setInstance:yrmInstance];
//    });
//    
//    it(@"should remove from only dataToSend on any response", ^{
//      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//      id yrmMock = [YozioRequestManager nullMock];
//      [YozioRequestManager setInstance:yrmMock];
//      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:handler:) atIndex:1];
//      
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
//      instance.dataToSend = nil;
//      [instance doFlush];
//      
//      NSInteger statusCode = 999;
//      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
//                                                                statusCode:statusCode
//                                                               HTTPVersion:@"HTTP/1.1"
//                                                              headerFields:[NSDictionary dictionary]];
//      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
//      block(nil, response, nil);
//      
//      [[instance.dataQueue shouldNot] equal:[NSMutableArray array]];
//      [instance.dataToSend shouldBeNil];
//      
//      [YozioRequestManager setInstance:yrmInstance];
//    });
//    
//    it(@"should remove from only dataToSend on error", ^{
//      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//      id yrmMock = [YozioRequestManager nullMock];
//      [YozioRequestManager setInstance:yrmMock];
//      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:handler:) atIndex:1];
//      
//      Yozio *instance = [Yozio getInstance];
//      instance._appKey = @"app key";
//      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
//      instance.dataToSend = nil;
//      [instance doFlush];
//      
//      NSInteger statusCode = 200;
//      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
//                                                                statusCode:statusCode
//                                                               HTTPVersion:@"HTTP/1.1"
//                                                              headerFields:[NSDictionary dictionary]];
//      NSError *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
//      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
//      block(nil, response, error);
//      
//      [[instance.dataQueue shouldNot] equal:[NSMutableArray array]];
//      [instance.dataToSend shouldBeNil];
//      
//      [YozioRequestManager setInstance:yrmInstance];
//    });
//  });
//});
//
//describe(@"buildPayload", ^{
//  it(@"should create the correct payload", ^{
//    [Yozio stub:@selector(getMACAddress) andReturn:@"mac address"];
//    [YOpenUDID stub:@selector(getOpenUDIDSlotCount) andReturn:theValue(1)];
//    [YOpenUDID stub:@selector(value) andReturn:@"open udid value"];
//    [Yozio stub:@selector(bundleVersion) andReturn:@"bundle version"];
//    Yozio *instance = [Yozio getInstance];
//    instance._appKey = @"app key";
//    instance.dataToSend = [NSMutableArray arrayWithObjects:
//                           [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil],
//                           [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil], nil];
//    instance.deviceId = @"device id";
//
//    NSString *jsonPayload = [instance buildPayload];
//    NSString *expectedJsonPayload = [[NSDictionary dictionaryWithObjectsAndKeys:
//     @"2", @"device_type",
//     instance.dataToSend, @"payload",
//     @"Unknown", @"hardware",
//     @"open udid value", @"open_udid",
//     @"5.1", @"os_version",
//     @"IOS-v2.4", @"sdk_version",
//     @"device id", @"yozio_udid",
//     @"1", @"open_udid_count",
//     @"1.000000", @"display_multiplier",
//     @"mac address", @"mac_address",
//     @"app key", @"app_key",
//     @"bundle version", @"app_version",
//     @"0", @"is_jailbroken",
//     nil] JSONString];
//    [[jsonPayload should] equal:expectedJsonPayload];
//  });
//});

describe(@"initializeExperiments", ^{
  context(@"", ^{
    beforeEach(^{
      [Yozio stub:@selector(getMACAddress) andReturn:@"mac address"];
      [YOpenUDID stub:@selector(getOpenUDIDSlotCount) andReturn:theValue(1)];
      [YOpenUDID stub:@selector(value) andReturn:@"open udid value"];
      [Yozio stub:@selector(bundleVersion) andReturn:@"bundle version"];
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance.dataToSend = [NSMutableArray arrayWithObjects:
                             [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil],
                             [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil], nil];
      instance.deviceId = @"device id";
    });
    
    afterEach(^{
      KWClearAllMessageSpies();
      KWClearAllObjectStubs();
    });
    
    it(@"should set the experimentConfig, eventSuperProperties, linkSuperProperties if 200", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];

      NSInteger statusCode = 200;
      NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
      id body = [NSDictionary dictionaryWithObjectsAndKeys:
                 @"experiment config", YOZIO_CONFIG_KEY,
                 experimentSids, YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY,
                 nil];
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      yrmMock.body = body;
      yrmMock.response = response;
      yrmMock.error = nil;
      
      [YozioRequestManager setInstance:yrmMock];

      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance._secretKey = @"secret key";
      [Yozio initializeExperiments];
      
      [[instance.experimentConfig should] equal:@"experiment config"];
      [[[instance.eventSuperProperties objectForKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] should] equal:experimentSids];
      [[[instance.linkSuperProperties objectForKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] should] equal:experimentSids];

      [YozioRequestManager setInstance:yrmInstance];
    });
    
    context(@"if response comes back faster than blocking time", ^{
      it(@"should set stopBlocking to true", ^{
        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
        
        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
        
        NSInteger statusCode = 200;
        NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
        id body = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"experiment config", YOZIO_CONFIG_KEY,
                   experimentSids, YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY,
                   nil];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                  statusCode:statusCode
                                                                 HTTPVersion:@"HTTP/1.1"
                                                                headerFields:[NSDictionary dictionary]];
        yrmMock.body = body;
        yrmMock.response = response;
        yrmMock.error = nil;
        
        [YozioRequestManager setInstance:yrmMock];
        
        Yozio *instance = [Yozio getInstance];
        instance._appKey = @"app key";
        instance._secretKey = @"secret key";
        [Yozio initializeExperiments];
        
        [[theValue(instance.stopBlocking) should] equal:theValue(true)];
        
        [YozioRequestManager setInstance:yrmInstance];
      });
    });
    
//    context(@"if response comes back slower than blocking time", ^{
//      it(@"should set stopBlocking to true", ^{
//        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//        
//        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
//        
//        NSInteger statusCode = 200;
//        NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
//        id body = [NSDictionary dictionaryWithObjectsAndKeys:
//                   @"experiment config", YOZIO_CONFIG_KEY,
//                   experimentSids, YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY,
//                   nil];
//        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
//                                                                  statusCode:statusCode
//                                                                 HTTPVersion:@"HTTP/1.1"
//                                                                headerFields:[NSDictionary dictionary]];
//        yrmMock.body = body;
//        yrmMock.response = response;
//        yrmMock.error = nil;
//        
//        [YozioRequestManager setInstance:yrmMock];
//        
//        Yozio *instance = [Yozio getInstance];
//        instance._appKey = @"app key";
//        instance._secretKey = @"secret key";
//        [Yozio initializeExperiments];
//        
//        [[theValue(instance.stopBlocking) should] equal:theValue(true)];
//        
//        [YozioRequestManager setInstance:yrmInstance];
//      });
//    });

  });
});

SPEC_END

