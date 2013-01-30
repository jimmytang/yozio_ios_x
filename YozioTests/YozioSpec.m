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


      NSDictionary *expectedJsonPayload = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"2", @"device_type",
                                        instance.dataToSend, @"payload",
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
                                        nil];

      NSError *e = nil;
      NSData *expectedJsonPayloadData = [NSJSONSerialization dataWithJSONObject:expectedJsonPayload
                                                      options:NSJSONReadingMutableContainers
                                                        error:&e];
      NSString* expectedJsonPayloadStr = [[[NSString alloc] initWithData:expectedJsonPayloadData
                                              encoding:NSUTF8StringEncoding] autorelease];

      NSString *urlString = urlSpy.argument;
      NSString *expectedUrlString = [NSString stringWithFormat:@"http://yoz.io/api/sdk/v1/batch_events"];
      NSDictionary *urlParams = urlParamsSpy.argument;
      NSDictionary *expectedUrlParams = [NSDictionary dictionaryWithObject:expectedJsonPayloadStr forKey:@"data"];
      [[urlString should] equal:expectedUrlString];
      
      NSData *urlParamsData = [NSJSONSerialization dataWithJSONObject:urlParams
                                                                      options:NSJSONReadingMutableContainers
                                                                        error:&e];
      NSString* urlParamsStr = [[[NSString alloc] initWithData:urlParamsData
                                                              encoding:NSUTF8StringEncoding] autorelease];

      NSData *expectedUrlParamsData = [NSJSONSerialization dataWithJSONObject:expectedUrlParams
                                                                        options:NSJSONReadingMutableContainers
                                                                          error:&e];
      NSString* expectedUrlParamsStr = [[[NSString alloc] initWithData:expectedUrlParamsData
                                                                encoding:NSUTF8StringEncoding] autorelease];

      [[urlParamsStr should] equal:expectedUrlParamsStr];
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

    NSString *payload = [instance buildPayload:instance.dataToSend];
    
    NSString *expectedPayload = [NSDictionary dictionaryWithObjectsAndKeys:
     @"2", @"device_type",
     instance.dataToSend, @"payload",
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
     nil];
    [[payload should] equal:expectedPayload];
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
      [yozioMock stub:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *viralLoopNameSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *channelSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *eventOptionsSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:3];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:4];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:5];
      [Yozio setInstance:yozioMock];
      
      [Yozio userLoggedIn:@"popo" properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_LOGIN_ACTION];
      [[viralLoopNameSpy.argument should] equal:@""];
      [[channelSpy.argument should] equal:@""];
      [[eventOptionsSpy.argument should] equal:[NSDictionary dictionary]];
      [[maxQueueSpy.argument should] equal:theValue(YOZIO_ACTION_DATA_LIMIT)];
      [[propertiesSpy.argument should] equal:[NSDictionary dictionary]];

      [Yozio setInstance:instance];
    });
  });
  context(@"enteredViralLoop", ^{
    it(@"should call collect with the correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *viralLoopNameSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *channelSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *eventOptionsSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:3];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:4];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:5];
      [Yozio setInstance:yozioMock];
      
      [Yozio enteredViralLoop:@"loop name" channel:@"channel" properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_VIEWED_LINK_ACTION];
      [[viralLoopNameSpy.argument should] equal:@"loop name"];
      [[channelSpy.argument should] equal:@"channel"];
      [[eventOptionsSpy.argument should] equal:[NSDictionary dictionary]];
      [[maxQueueSpy.argument should] equal:theValue(YOZIO_ACTION_DATA_LIMIT)];
      [[propertiesSpy.argument should] equal:[NSDictionary dictionary]];
      
      [Yozio setInstance:instance];
    });
  });

  context(@"sharedYozioLink", ^{
    it(@"should call collect with the correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *viralLoopNameSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *channelSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *eventOptionsSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:3];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:4];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:viralLoopName:channel:eventOptions:maxQueue:properties:) atIndex:5];
      [Yozio setInstance:yozioMock];
      
      [Yozio sharedYozioLink:@"loop name" channel:@"channel" count:3 properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_SHARED_LINK_ACTION];
      [[viralLoopNameSpy.argument should] equal:@"loop name"];
      [[channelSpy.argument should] equal:@"channel"];
      [[eventOptionsSpy.argument should] equal:[NSDictionary dictionaryWithObject:@"3" forKey:YOZIO_D_COUNT]];
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
      [instance doCollect:type viralLoopName:viralLoopName channel:@"channel" eventOptions:NULL maxQueue:YOZIO_ACTION_DATA_LIMIT properties:properties];
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
                                     @"channel", YOZIO_D_CHANNEL,
                                     @"time stamp string", YOZIO_D_TIMESTAMP,
                                     @"event id", YOZIO_D_EVENT_IDENTIFIER,
                                     [Yozio toJSON:properties], YOZIO_P_EXTERNAL_PROPERTIES,
                                     nil],
                                    nil];
      instance.dataQueue = [NSMutableArray array];
      [instance doCollect:type viralLoopName:viralLoopName channel:@"channel" eventOptions:NULL maxQueue:YOZIO_ACTION_DATA_LIMIT properties:properties];
      [[instance.dataQueue should] equal:expectedDataQueue];
    });
  });
});

describe(@"getYozioLink", ^{
  context(@"", ^{
    it(@"should return destinationUrl if viralLoopName is null", ^{
      [[[Yozio getYozioLink:nil channel:@"channel" destinationUrl:@"destination url"] should] equal:@"destination url"];
      [[[Yozio getYozioLink:NULL channel:@"channel" destinationUrl:@"destination url"] should] equal:@"destination url"];
    });
    
    it(@"should return null if destinationUrl is null", ^{
      [[Yozio getYozioLink:@"twitter" channel:@"channel" destinationUrl:nil] shouldBeNil];
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
                     obj:[Yozio toJSON:[NSDictionary dictionaryWithObjectsAndKeys:
                           [NSDictionary dictionaryWithObject:@"value" forKey:@"key"], YOZIO_P_EXPERIMENT_VARIATION_SIDS,
                           @"channel", YOZIO_GET_URL_P_CHANNEL, nil]]];

      [Yozio getYozioLink:linkName channel:@"channel" destinationUrl:destinationUrl];
      [[[Yozio toJSON:urlParamsSpy.argument] should] equal:[Yozio toJSON:expectedUrlParams]];
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
                     obj:[Yozio toJSON:[NSDictionary dictionaryWithObjectsAndKeys:
                           experimentVariationSids, YOZIO_P_EXPERIMENT_VARIATION_SIDS,
                           @"channel", YOZIO_GET_URL_P_CHANNEL, nil]]];
      [Yozio addIfNotNil:expectedUrlParams
                     key:YOZIO_P_EXTERNAL_PROPERTIES
                     obj:[Yozio toJSON:properties]];

      [Yozio getYozioLink:@"twitter"
                  channel:@"channel"
           destinationUrl:destinationUrl
               properties:properties];
      [[[Yozio toJSON:urlParamsSpy.argument] should] equal:[Yozio toJSON:expectedUrlParams]];
      [[destUrlSpy.argument should] equal:@"destination url"];
      
      [Yozio setInstance:instance];
    });
    
    it(@"should call getYozioLinkRequest with the correct parameters if multiple destination Url", ^{
      Yozio *instance = [Yozio getInstance];
      
      NSString *appKey = @"app key";
      NSString *deviceId = @"device id";
      NSString *linkName = @"twitter";
      NSString *channel = @"channel";
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
                     obj:[Yozio toJSON:[NSDictionary dictionaryWithObjectsAndKeys:experimentVariationSids, YOZIO_P_EXPERIMENT_VARIATION_SIDS, @"channel", YOZIO_GET_URL_P_CHANNEL, nil]]];

      [Yozio getYozioLink:linkName
                  channel:channel
        iosDestinationUrl:iosDestinationUrl
    androidDestinationUrl:androidDestinationUrl
  nonMobileDestinationUrl:nonMobileDestinationUrl];
      
      [[[Yozio toJSON:urlParamsSpy.argument] should] equal:[Yozio toJSON:expectedUrlParams]];
      [[destUrlSpy.argument should] equal:@"non mobile destination"];
      
      [Yozio setInstance:instance];
    });

    it(@"should call getYozioLinkRequest with the correct parameters if multiple destination Url with properties", ^{
      Yozio *instance = [Yozio getInstance];
      
      NSString *appKey = @"app key";
      NSString *deviceId = @"device id";
      NSString *linkName = @"twitter";
      NSString *channel = @"channel";
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
                     obj:[Yozio toJSON:[NSDictionary dictionaryWithObjectsAndKeys:experimentVariationSids, YOZIO_P_EXPERIMENT_VARIATION_SIDS, @"channel", YOZIO_GET_URL_P_CHANNEL, nil]]];
      [Yozio addIfNotNil:expectedUrlParams
                     key:YOZIO_P_EXTERNAL_PROPERTIES
                     obj:[Yozio toJSON:properties]];
      
      
      [Yozio getYozioLink:linkName
                  channel:channel
        iosDestinationUrl:iosDestinationUrl
    androidDestinationUrl:androidDestinationUrl
  nonMobileDestinationUrl:nonMobileDestinationUrl
               properties:properties];
      [[[Yozio toJSON:urlParamsSpy.argument] should] equal:[Yozio toJSON:expectedUrlParams]];
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
