/*
 * Copyright (C) 2012 Yozio Inc.
 *
 * This file is part of the Yozio SDK.
 *
 * By using the Yozio SDK in your software, you agree to the terms of the
 * Yozio SDK License Agreement which can be found at www.yozio.com/sdk_license.
 */


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

describe(@"doFlush", ^{
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

    it(@"should not flush when the dataQueue is empty", ^{
      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:body:timeOut:handler:) withCount:0];
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance.dataQueue = [NSMutableArray array];
      [instance doFlush];
    });
    
    it(@"should flush when the dataQueue is not empty", ^{
      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:body:timeOut:handler:) withCount:1];
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance.dataQueue = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = nil;
      [instance doFlush];
    });

    it(@"should not flush when already flushing", ^{
      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:body:timeOut:handler:) withCount:0];
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance.dataQueue = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      [instance doFlush];
    });

    it(@"should flush the correct amount if dataQueue is greater than flush data size", ^{
      [YSeriously stub:@selector(get:handler:)];
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance.dataQueue = [NSMutableArray array];
      for (int i = 0; i < 21; i++)
      {
        [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key1", nil]];
      }
      instance.dataToSend = nil;
      [instance doFlush];
      [[theValue([instance.dataToSend count]) should] equal:theValue(20)];
    });

    it(@"should flush the correct amount if dataQueue is less than flush data size", ^{
      [YSeriously stub:@selector(get:handler:)];
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance.dataQueue = [NSMutableArray array];
      for (int i = 0; i < 5; i++)
      {
        [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key1", nil]];
      }
      instance.dataToSend = nil;
      [instance doFlush];
      [[theValue([instance.dataToSend count]) should] equal:theValue(5)];
    });

    it(@"should flush the correct request", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *urlSpy = [yrmMock captureArgument:@selector(urlRequest:body:timeOut:handler:) atIndex:0];
      KWCaptureSpy *urlParamsSpy = [yrmMock captureArgument:@selector(urlRequest:body:timeOut:handler:) atIndex:1];

      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key1", nil]];
      instance.dataToSend = nil;
      [instance doFlush];

      NSString *expectedJsonPayload = [[NSDictionary dictionaryWithObjectsAndKeys:
                                        @"2", @"device_type",
                                        instance.dataToSend, @"payload",
                                        @"Unknown", @"hardware",
                                        @"open udid value", @"open_udid",
                                        @"5.1", @"os_version",
                                        @"device id", @"yozio_udid",
                                        @"1", @"open_udid_count",
                                        @"1.000000", @"display_multiplier",
                                        @"mac address", @"mac_address",
                                        @"app key", @"app_key",
                                        @"bundle version", @"app_version",
                                        @"0", @"is_jailbroken",
                                        nil] JSONString];

      NSString *urlString = urlSpy.argument;
      NSString *expectedUrlString = [NSString stringWithFormat:@"http://yoz.io/api/sdk/v1/batch_events"];
      NSDictionary *urlParams = urlParamsSpy.argument;
      NSDictionary *expectedUrlParams = [NSDictionary dictionaryWithObject:expectedJsonPayload forKey:@"data"];
      [[urlString should] equal:expectedUrlString];
      [[[urlParams JSONString] should] equal:[expectedUrlParams JSONString]];
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should remove from dataQueue and dataToSend on a 200 response", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:body:timeOut:handler:) atIndex:3];
      
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = nil;
      [instance doFlush];
      
      
      id body = [NSDictionary dictionaryWithObjectsAndKeys:
                 @"ok", @"status",
                 nil];
      NSInteger statusCode = 200;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
      block(body, response, nil);
      
      [[instance.dataQueue should] equal:[NSMutableArray array]];
      [instance.dataToSend shouldBeNil];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should remove from dataQueue and dataToSend on a 400 response", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:body:timeOut:handler:) atIndex:3];
      
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = nil;
      [instance doFlush];
      
      id body = [NSDictionary dictionaryWithObjectsAndKeys:
                 @"ok", @"status",
                 nil];
      NSInteger statusCode = 400;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
      block(body, response, nil);
      
      [[instance.dataQueue should] equal:[NSMutableArray array]];
      [instance.dataToSend shouldBeNil];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
        
    it(@"should remove from only dataToSend on any response", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:body:timeOut:handler:) atIndex:3];
      
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = nil;
      [instance doFlush];
      
      NSInteger statusCode = 999;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
      block(nil, response, nil);
      
      [[instance.dataQueue shouldNot] equal:[NSMutableArray array]];
      [instance.dataToSend shouldBeNil];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should remove from only dataToSend on error", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:body:timeOut:handler:) atIndex:3];
      
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = nil;
      [instance doFlush];
      
      NSInteger statusCode = 200;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      NSError *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
      block(nil, response, error);
      
      [[instance.dataQueue shouldNot] equal:[NSMutableArray array]];
      [instance.dataToSend shouldBeNil];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
  });
});

describe(@"buildPayload", ^{
  it(@"should create the correct payload", ^{
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

    NSString *jsonPayload = [instance buildPayload];
    NSString *expectedJsonPayload = [[NSDictionary dictionaryWithObjectsAndKeys:
     @"2", @"device_type",
     instance.dataToSend, @"payload",
     @"Unknown", @"hardware",
     @"open udid value", @"open_udid",
     @"5.1", @"os_version",
     @"device id", @"yozio_udid",
     @"1", @"open_udid_count",
     @"1.000000", @"display_multiplier",
     @"mac address", @"mac_address",
     @"app key", @"app_key",
     @"bundle version", @"app_version",
     @"0", @"is_jailbroken",
     nil] JSONString];
    [[jsonPayload should] equal:expectedJsonPayload];
  });
});

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
      instance._appKey = @"app key";
      instance._secretKey = @"secret key";
      instance.experimentConfig = [NSMutableDictionary dictionary];
      instance.experimentVariationSids = [NSMutableDictionary dictionary];
    });
    
    afterEach(^{
      KWClearAllMessageSpies();
      KWClearAllObjectStubs();
    });
    
    it(@"should set the experimentConfig and experimentVariationSids if 200", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      
      NSInteger statusCode = 200;
      NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
      NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"variation id", @"experiment id", nil];
      id body = [NSDictionary dictionaryWithObjectsAndKeys:
                 experimentConfig, YOZIO_CONFIG_KEY,
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
      
      [Yozio initializeExperiments];
      
      Yozio *instance = [Yozio getInstance];
      [[instance.experimentConfig should] equal:experimentConfig];
      [[instance.experimentVariationSids should] equal:experimentSids];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should not set either the experimentConfig nor the experimentVariationSids if one of them is blank and the other isn't", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      
      NSInteger statusCode = 200;
      NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
      NSDictionary *experimentSids = nil;
      id body = [NSDictionary dictionaryWithObjectsAndKeys:
                 experimentConfig, YOZIO_CONFIG_KEY,
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
      
      [Yozio initializeExperiments];
      
      Yozio *instance = [Yozio getInstance];
      [[instance.experimentConfig should] equal:[NSDictionary dictionary]];
      [[instance.experimentVariationSids should] equal:[NSDictionary dictionary]];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    

    
    it(@"should not set the experimentConfig, eventYozioProperties, linkYozioProperties if not 200", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      
      NSInteger statusCode = 999;
      NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
      NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"variation id", @"experiment id", nil];
      id body = [NSDictionary dictionaryWithObjectsAndKeys:
                 experimentConfig, YOZIO_CONFIG_KEY,
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
      
      [Yozio initializeExperiments];
      
      Yozio *instance = [Yozio getInstance];
      [[instance.experimentConfig should] equal:[NSMutableDictionary dictionary]];
      [[instance.experimentVariationSids should] equal:[NSMutableDictionary dictionary]];
      
      [YozioRequestManager setInstance:yrmInstance];
    });

    context(@"if body missing value for YOZIO_CONFIG_KEY", ^{
      it(@"should not set experimentConfig", ^{
        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
        
        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
        
        NSInteger statusCode = 200;
        NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"variation id", @"experiment id", nil];
        id body = [NSDictionary dictionaryWithObjectsAndKeys:
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
        
        [[instance.experimentConfig should] equal:[NSMutableDictionary dictionary]];
        
        [YozioRequestManager setInstance:yrmInstance];
      });
    });

    context(@"if value for YOZIO_CONFIG_KEY is not a dictionary", ^{
      it(@"should not set experimentConfig", ^{
        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
        
        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
        
        NSInteger statusCode = 200;
        NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"variation id", @"experiment id", nil];
        id body = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"not a dictionary", YOZIO_CONFIG_KEY,
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
        
        [[instance.experimentConfig should] equal:[NSMutableDictionary dictionary]];
        
        [YozioRequestManager setInstance:yrmInstance];
      });
    });

    context(@"if body missing value for YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY", ^{
      it(@"should not set eventYozioProperties or linkYozioProperties", ^{
        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
        
        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
        
        NSInteger statusCode = 200;
        NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
        id body = [NSDictionary dictionaryWithObjectsAndKeys:
                   experimentConfig, YOZIO_CONFIG_KEY,
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
        
        [[instance.experimentVariationSids should] equal:[NSMutableDictionary dictionary]];
        
        [YozioRequestManager setInstance:yrmInstance];
      });
    });
    

    context(@"if value for YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY is not a dictionary", ^{
      it(@"should not set eventYozioProperties or linkYozioProperties", ^{
        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
        
        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
        
        NSInteger statusCode = 200;
        NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
        id body = [NSDictionary dictionaryWithObjectsAndKeys:
                   experimentConfig, YOZIO_CONFIG_KEY,
                   @"not a dictionary", YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY,
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
        
        [[instance.experimentVariationSids should] equal:[NSMutableDictionary dictionary]];
        
        [YozioRequestManager setInstance:yrmInstance];
      });
    });

  });
});

describe(@"initializeExperimentsAsync", ^{
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
      instance._appKey = @"app key";
      instance._secretKey = @"secret key";
      instance.experimentConfig = [NSMutableDictionary dictionary];
      instance.experimentVariationSids = [NSMutableDictionary dictionary];
    });
    
    it(@"should execute the callback", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      
      NSInteger statusCode = 200;
      NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
      NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"variation id", @"experiment id", nil];
      id body = [NSDictionary dictionaryWithObjectsAndKeys:
                 experimentConfig, YOZIO_CONFIG_KEY,
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
      
      __block BOOL testBool = false;
      [Yozio initializeExperimentsAsync:^{testBool = true;}];
      [[theValue(testBool) should] equal:theValue(true)];
      
      [YozioRequestManager setInstance:yrmInstance];

    });

  });
});
          
describe(@"stringForKey", ^{
  context(@"", ^{
    it(@"should return default if key is null", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
      [[[Yozio stringForKey:nil defaultValue:@"default value"] should] equal:@"default value"];
      [[[Yozio stringForKey:NULL defaultValue:@"default value"] should] equal:@"default value"];
    });
    
    it(@"should return default if experimentConfig is null", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = nil;
      [[[Yozio stringForKey:@"key" defaultValue:@"default value"] should] equal:@"default value"];
    });
    
    it(@"should return default if the key isn't found in experimentConfig", ^{
      [[[Yozio stringForKey:@"key" defaultValue:@"default value"] should] equal:@"default value"];
    });
    
    it(@"should return default if the value for key isn't a string", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSArray array], @"key", nil];
      [[[Yozio stringForKey:@"key" defaultValue:@"default value"] should] equal:@"default value"];
    });
    
    it(@"should return value for key if it exists in experimentConfig and is a string", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
      [[[Yozio stringForKey:@"key" defaultValue:@"default value"] should] equal:@"value"];
    });
  });
});

describe(@"intForKey", ^{
  context(@"", ^{
    it(@"should return default if key is null", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
      [[theValue([Yozio intForKey:nil defaultValue:-1]) should] equal:theValue(-1)];
      [[theValue([Yozio intForKey:NULL defaultValue:-1]) should] equal:theValue(-1)];
    });
    
    it(@"should return default if experimentConfig is null", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = nil;
      [[theValue([Yozio intForKey:@"key" defaultValue:-1]) should] equal:theValue(-1)];
    });
    
    it(@"should return default if the key isn't found in experimentConfig", ^{
      [[theValue([Yozio intForKey:@"key" defaultValue:-1]) should] equal:theValue(-1)];
    });
    
    it(@"should return default if the value for key isn't a string that converts to an int", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSArray array], @"key", nil];
      [[theValue([Yozio intForKey:@"key" defaultValue:-1]) should] equal:theValue(-1)];
    });
    
    it(@"should return default if the value for key is a string that doesn't convert to an int", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"non int string 1", @"key", nil];
      [[theValue([Yozio intForKey:@"key" defaultValue:-1]) should] equal:theValue(-1)];
    });
    
    it(@"should return value for key if it exists in experimentConfig and is a string that converts to an int", ^{
      Yozio *instance = [Yozio getInstance];
      instance.experimentConfig = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"1", @"key", nil];
      [[theValue([Yozio intForKey:@"key" defaultValue:-1]) should] equal:theValue(1)];
    });
  });
});

describe(@"doCollect", ^{
  context(@"userLoggedIn", ^{
    it(@"should update the user name to null if null user name passed", ^{
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance._secretKey = @"secret key";
      [Yozio userLoggedIn:nil];
      [instance._userName shouldBeNil];
    });
    it(@"should update the user name", ^{
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance._secretKey = @"secret key";
      [Yozio userLoggedIn:@"popo"];
      [[instance._userName should] equal:@"popo"];
    });
    it(@"should call collect with the correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio nullMock];
      [yozioMock stub:@selector(doCollect:viralLoopName:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *viralLoopNameSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:3];
      [Yozio setInstance:yozioMock];
      
      [Yozio userLoggedIn:@"popo" properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_LOGIN_ACTION];
      [[viralLoopNameSpy.argument should] equal:@""];
      [[maxQueueSpy.argument should] equal:theValue(YOZIO_ACTION_DATA_LIMIT)];
      [[propertiesSpy.argument should] equal:[NSDictionary dictionary]];

      [Yozio setInstance:instance];
    });
  });
  context(@"enteredViralLoop", ^{
    it(@"should call collect with the correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(doCollect:viralLoopName:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *viralLoopNameSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:3];
      [Yozio setInstance:yozioMock];
      
      [Yozio enteredViralLoop:@"loop name" properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_VIEWED_LINK_ACTION];
      [[viralLoopNameSpy.argument should] equal:@"loop name"];
      [[maxQueueSpy.argument should] equal:theValue(YOZIO_ACTION_DATA_LIMIT)];
      [[propertiesSpy.argument should] equal:[NSDictionary dictionary]];
      
      [Yozio setInstance:instance];
    });
  });

  context(@"sharedYozioLink", ^{
    it(@"should call collect with the correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(doCollect:viralLoopName:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *viralLoopNameSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:maxQueue:properties:) atIndex:3];
      [Yozio setInstance:yozioMock];
      
      [Yozio sharedYozioLink:@"loop name" properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_SHARED_LINK_ACTION];
      [[viralLoopNameSpy.argument should] equal:@"loop name"];
      [[maxQueueSpy.argument should] equal:theValue(YOZIO_ACTION_DATA_LIMIT)];
      [[propertiesSpy.argument should] equal:[NSDictionary dictionary]];
      
      [Yozio setInstance:instance];
    });
  });
  
  context(@"doCollect", ^{
    beforeEach(^{
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance._secretKey = @"secret key";
    });
    
    it(@"should increment the dataCount", ^{
      Yozio *instance = [Yozio getInstance];
      instance.dataCount = 0;
      NSString *type = YOZIO_SHARED_LINK_ACTION;
      NSString *viralLoopName = @"loop name";
      NSDictionary *properties = [NSDictionary dictionaryWithObject:@"value" forKey:@"property"];
      [instance stub:@selector(timeStampString) andReturn:@"time stamp string"];
      [instance stub:@selector(eventID) andReturn:@"event id"];
      [instance doCollect:type viralLoopName:viralLoopName maxQueue:YOZIO_ACTION_DATA_LIMIT properties:properties];
      [[theValue(instance.dataCount) should] equal:theValue(1)];
    });
    
    it(@"should add a new event to the dataQueue with correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      NSString *type = YOZIO_SHARED_LINK_ACTION;
      NSString *viralLoopName = @"loop name";
      NSDictionary *properties = [NSDictionary dictionaryWithObject:@"value" forKey:@"property"];
      [instance stub:@selector(timeStampString) andReturn:@"time stamp string"];
      [instance stub:@selector(eventID) andReturn:@"event id"];
      NSArray *expectedDataQueue = [NSArray arrayWithObjects:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     type, YOZIO_D_EVENT_TYPE,
                                     viralLoopName, YOZIO_D_LINK_NAME,
                                     @"time stamp string", YOZIO_D_TIMESTAMP,
                                     @"event id", YOZIO_D_EVENT_IDENTIFIER,
                                     [properties JSONString], YOZIO_P_EXTERNAL_PROPERTIES,
                                     nil],
                                    nil];
      instance.dataQueue = [NSMutableArray array];
      [instance doCollect:type viralLoopName:viralLoopName maxQueue:YOZIO_ACTION_DATA_LIMIT properties:properties];
      [[instance.dataQueue should] equal:expectedDataQueue];
    });
  });
});

describe(@"getYozioLink", ^{
  context(@"", ^{
    it(@"should return destinationUrl if viralLoopName is null", ^{
      [[[Yozio getYozioLink:nil destinationUrl:@"destination url"] should] equal:@"destination url"];
      [[[Yozio getYozioLink:NULL destinationUrl:@"destination url"] should] equal:@"destination url"];
    });
    
    it(@"should return null if destinationUrl is null", ^{
      [[Yozio getYozioLink:@"twitter" destinationUrl:nil] shouldBeNil];
    });
    
    it(@"should call getYozioLinkRequest with the correct parameters if single destination Url", ^{
      Yozio *instance = [Yozio getInstance];
      
      NSString *appKey = @"app key";
      NSString *deviceId = @"device id";
      NSString *linkName = @"twitter";
      NSString *destinationUrl = @"destination url";
      NSDictionary *experimentVariationSids = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];

      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(_appKey) andReturn:appKey];
      [yozioMock stub:@selector(deviceId) andReturn:deviceId];
      [yozioMock stub:@selector(experimentVariationSids) andReturn:experimentVariationSids];
      KWCaptureSpy *urlParamsSpy = [yozioMock captureArgument:@selector(getYozioLinkRequest:destUrl:timeOut:callback:) atIndex:0];
      KWCaptureSpy *destUrlSpy = [yozioMock captureArgument:@selector(getYozioLinkRequest:destUrl:timeOut:callback:) atIndex:1];
      [yozioMock stub:@selector(getYozioLinkRequest:destUrl:timeOut:callback:)];
      [Yozio setInstance:yozioMock];
      
      NSMutableDictionary *expectedUrlParams =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
       appKey, YOZIO_GET_CONFIGURATION_P_APP_KEY,
       deviceId, YOZIO_GET_CONFIGURATION_P_YOZIO_UDID,
       YOZIO_DEVICE_TYPE_IOS, YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE,
       linkName, YOZIO_GET_URL_P_LINK_NAME,
       destinationUrl, YOZIO_GET_URL_P_DEST_URL, nil];
      [Yozio addIfNotNil:expectedUrlParams
                     key:YOZIO_GET_URL_P_YOZIO_PROPERTIES
                     obj:[[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@"value" forKey:@"key"] forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] JSONString]];

      [Yozio getYozioLink:linkName destinationUrl:destinationUrl];
      [[[urlParamsSpy.argument JSONString] should] equal:[expectedUrlParams JSONString]];
      [[destUrlSpy.argument should] equal:@"destination url"];
      
      [Yozio setInstance:instance];
    });
    
    it(@"should call getYozioLinkRequest with the correct parameters if single destination Url with properties", ^{
      Yozio *instance = [Yozio getInstance];
      
      NSString *appKey = @"app key";
      NSString *deviceId = @"device id";
      NSString *linkName = @"twitter";
      NSString *destinationUrl = @"destination url";
      NSDictionary *properties = [NSDictionary dictionaryWithObject:@"prop value" forKey:@"prop key"];
      NSDictionary *experimentVariationSids = [NSMutableDictionary dictionaryWithObject:@"value" forKey:@"key"];

      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(getYozioLinkRequest:destUrl:timeOut:callback:)];
      [yozioMock stub:@selector(_appKey) andReturn:appKey];
      [yozioMock stub:@selector(deviceId) andReturn:deviceId];
      [yozioMock stub:@selector(experimentVariationSids) andReturn:experimentVariationSids];
      KWCaptureSpy *urlParamsSpy = [yozioMock captureArgument:@selector(getYozioLinkRequest:destUrl:timeOut:callback:) atIndex:0];
      KWCaptureSpy *destUrlSpy = [yozioMock captureArgument:@selector(getYozioLinkRequest:destUrl:timeOut:callback:) atIndex:1];
      [Yozio setInstance:yozioMock];
      
      
      NSMutableDictionary *expectedUrlParams =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
       appKey, YOZIO_GET_CONFIGURATION_P_APP_KEY,
       deviceId, YOZIO_GET_CONFIGURATION_P_YOZIO_UDID,
       YOZIO_DEVICE_TYPE_IOS, YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE,
       linkName, YOZIO_GET_URL_P_LINK_NAME,
       destinationUrl, YOZIO_GET_URL_P_DEST_URL, nil];
      [Yozio addIfNotNil:expectedUrlParams
                     key:YOZIO_GET_URL_P_YOZIO_PROPERTIES
                     obj:[[NSDictionary dictionaryWithObject:experimentVariationSids forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] JSONString]];
      [Yozio addIfNotNil:expectedUrlParams
                     key:YOZIO_P_EXTERNAL_PROPERTIES
                     obj:[properties JSONString]];

      [Yozio getYozioLink:@"twitter"
     destinationUrl:destinationUrl
         properties:properties];
      [[[urlParamsSpy.argument JSONString] should] equal:[expectedUrlParams JSONString]];
      [[destUrlSpy.argument should] equal:@"destination url"];
      
      [Yozio setInstance:instance];
    });
    
    it(@"should call getYozioLinkRequest with the correct parameters if multiple destination Url", ^{
      Yozio *instance = [Yozio getInstance];
      
      NSString *appKey = @"app key";
      NSString *deviceId = @"device id";
      NSString *linkName = @"twitter";
      NSString *iosDestinationUrl = @"ios destination";
      NSString *androidDestinationUrl = @"android destination";
      NSString *nonMobileDestinationUrl = @"non mobile destination";
      NSDictionary *experimentVariationSids = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];

      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(getYozioLinkRequest:destUrl:timeOut:callback:)];
      [yozioMock stub:@selector(_appKey) andReturn:appKey];
      [yozioMock stub:@selector(deviceId) andReturn:deviceId];
      [yozioMock stub:@selector(experimentVariationSids) andReturn:experimentVariationSids];
      KWCaptureSpy *urlParamsSpy = [yozioMock captureArgument:@selector(getYozioLinkRequest:destUrl:timeOut:callback:) atIndex:0];
      KWCaptureSpy *destUrlSpy = [yozioMock captureArgument:@selector(getYozioLinkRequest:destUrl:timeOut:callback:) atIndex:1];
      [Yozio setInstance:yozioMock];      
      
      NSMutableDictionary *expectedUrlParams =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
       appKey, YOZIO_GET_CONFIGURATION_P_APP_KEY,
       deviceId, YOZIO_GET_CONFIGURATION_P_YOZIO_UDID,
       YOZIO_DEVICE_TYPE_IOS, YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE,
       linkName, YOZIO_GET_URL_P_LINK_NAME,
       iosDestinationUrl, YOZIO_GET_URL_P_IOS_DEST_URL,
       androidDestinationUrl, YOZIO_GET_URL_P_ANDROID_DEST_URL,
       nonMobileDestinationUrl, YOZIO_GET_URL_P_NON_MOBILE_DEST_URL, nil];
      [Yozio addIfNotNil:expectedUrlParams
                     key:YOZIO_GET_URL_P_YOZIO_PROPERTIES
                     obj:[[NSDictionary dictionaryWithObject:experimentVariationSids forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] JSONString]];

      [Yozio getYozioLink:linkName
        iosDestinationUrl:iosDestinationUrl
    androidDestinationUrl:androidDestinationUrl
  nonMobileDestinationUrl:nonMobileDestinationUrl];
      
      [[[urlParamsSpy.argument JSONString] should] equal:[expectedUrlParams JSONString]];
      [[destUrlSpy.argument should] equal:@"non mobile destination"];
      
      [Yozio setInstance:instance];
    });

    it(@"should call getYozioLinkRequest with the correct parameters if multiple destination Url with properties", ^{
      Yozio *instance = [Yozio getInstance];
      
      NSString *appKey = @"app key";
      NSString *deviceId = @"device id";
      NSString *linkName = @"twitter";
      NSString *iosDestinationUrl = @"ios destination";
      NSString *androidDestinationUrl = @"android destination";
      NSString *nonMobileDestinationUrl = @"non mobile destination";
      NSDictionary *properties = [NSDictionary dictionaryWithObject:@"prop value" forKey:@"prop key"];
      NSDictionary *experimentVariationSids = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(getYozioLinkRequest:destUrl:timeOut:callback:)];
      [yozioMock stub:@selector(_appKey) andReturn:appKey];
      [yozioMock stub:@selector(deviceId) andReturn:deviceId];
      [yozioMock stub:@selector(experimentVariationSids) andReturn:experimentVariationSids];
      KWCaptureSpy *urlParamsSpy = [yozioMock captureArgument:@selector(getYozioLinkRequest:destUrl:timeOut:callback:) atIndex:0];
      KWCaptureSpy *destUrlSpy = [yozioMock captureArgument:@selector(getYozioLinkRequest:destUrl:timeOut:callback:) atIndex:1];
      [Yozio setInstance:yozioMock];
      
      NSMutableDictionary *expectedUrlParams =
      [NSMutableDictionary dictionaryWithObjectsAndKeys:
       appKey, YOZIO_GET_CONFIGURATION_P_APP_KEY,
       deviceId, YOZIO_GET_CONFIGURATION_P_YOZIO_UDID,
       YOZIO_DEVICE_TYPE_IOS, YOZIO_GET_CONFIGURATION_P_DEVICE_TYPE,
       linkName, YOZIO_GET_URL_P_LINK_NAME,
       iosDestinationUrl, YOZIO_GET_URL_P_IOS_DEST_URL,
       androidDestinationUrl, YOZIO_GET_URL_P_ANDROID_DEST_URL,
       nonMobileDestinationUrl, YOZIO_GET_URL_P_NON_MOBILE_DEST_URL, nil];
      [Yozio addIfNotNil:expectedUrlParams
                     key:YOZIO_GET_URL_P_YOZIO_PROPERTIES
                     obj:[[NSDictionary dictionaryWithObject:experimentVariationSids forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] JSONString]];
      [Yozio addIfNotNil:expectedUrlParams
                     key:YOZIO_P_EXTERNAL_PROPERTIES
                     obj:[properties JSONString]];
      
      
      [Yozio getYozioLink:linkName
        iosDestinationUrl:iosDestinationUrl
    androidDestinationUrl:androidDestinationUrl
  nonMobileDestinationUrl:nonMobileDestinationUrl
               properties:properties];
      [[[urlParamsSpy.argument JSONString] should] equal:[expectedUrlParams JSONString]];
      [[destUrlSpy.argument should] equal:@"non mobile destination"];
      
      [Yozio setInstance:instance];
    });

  });
});

describe(@"getYozioLinkRequest", ^{
  context(@"", ^{
    it(@"should return destination url if an error occurs", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      [YozioRequestManager setInstance:yrmMock];
      NSInteger statusCode = 200;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      NSError *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
      yrmMock.response = response;
      yrmMock.error = error;
      
      Yozio *instance = [Yozio getInstance];
      [[[instance getYozioLinkRequest:[NSDictionary dictionary] destUrl:@"dest url" timeOut:5 callback:nil] should] equal:@"dest url"];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should update return a Yozio link on a 200", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      [YozioRequestManager setInstance:yrmMock];
      NSInteger statusCode = 200;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      
      yrmMock.body = [NSDictionary dictionaryWithObject:@"yozio link" forKey:@"url"];
      yrmMock.response = response;
      
      Yozio *instance = [Yozio getInstance];
      [[[instance getYozioLinkRequest:[NSDictionary dictionary] destUrl:@"dest url" timeOut:5 callback:nil] should] equal:@"yozio link"];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should execute the callback", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      [YozioRequestManager setInstance:yrmMock];
      NSInteger statusCode = 200;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      
      yrmMock.body = [NSDictionary dictionaryWithObject:@"yozio link" forKey:@"url"];
      yrmMock.response = response;
      
      Yozio *instance = [Yozio getInstance];
      __block NSString *testShortLink = @"";
      [instance getYozioLinkRequest:[NSDictionary dictionary] destUrl:@"dest url" timeOut:0 callback:^(NSString * shortLink){ testShortLink = shortLink; }];
      [[testShortLink should] equal:@"yozio link"];
      [YozioRequestManager setInstance:yrmInstance];
    });

    it(@"should return destination url if response isn't json", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      [YozioRequestManager setInstance:yrmMock];
      NSInteger statusCode = 200;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      NSError *error = [[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
      yrmMock.body = @"not a dictionary";
      yrmMock.response = response;
      yrmMock.error = error;
      
      Yozio *instance = [Yozio getInstance];
      [[[instance getYozioLinkRequest:[NSDictionary dictionary] destUrl:@"dest url" timeOut:5 callback:nil] should] equal:@"dest url"];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
  });
});


SPEC_END

