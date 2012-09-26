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
      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:timeOut:handler:) withCount:0];
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance.dataQueue = [NSMutableArray array];
      [instance doFlush];
    });
    
    it(@"should flush when the dataQueue is not empty", ^{
      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:timeOut:handler:) withCount:1];
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      instance.dataQueue = [NSMutableArray arrayWithObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = nil;
      [instance doFlush];
    });

    it(@"should not flush when already flushing", ^{
      [[[YozioRequestManager sharedInstance] should] receive:@selector(urlRequest:timeOut:handler:) withCount:0];
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
      KWCaptureSpy *spy = [yrmMock captureArgument:@selector(urlRequest:timeOut:handler:) atIndex:0];

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

      NSString *urlString = spy.argument;
      NSString *expectedUrlString = [NSString stringWithFormat:@"http://yoz.io/api/sdk/v1/batch_events?data=%@", [Yozio encodeToPercentEscapeString:expectedJsonPayload]];
      [[urlString should] equal:expectedUrlString];
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should remove from dataQueue and dataToSend on a 200 response", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:timeOut:handler:) atIndex:2];
      
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
      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
      block(nil, response, nil);
      
      [[instance.dataQueue should] equal:[NSMutableArray array]];
      [instance.dataToSend shouldBeNil];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should remove from dataQueue and dataToSend on a 400 response", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:timeOut:handler:) atIndex:2];
      
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = nil;
      [instance doFlush];
      
      NSInteger statusCode = 400;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
      block(nil, response, nil);
      
      [[instance.dataQueue should] equal:[NSMutableArray array]];
      [instance.dataToSend shouldBeNil];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should remove from dataQueue and dataToSend on a 400 response", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:timeOut:handler:) atIndex:2];
      
      Yozio *instance = [Yozio getInstance];
      instance._appKey = @"app key";
      [instance.dataQueue addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil]];
      instance.dataToSend = nil;
      [instance doFlush];
      
      NSInteger statusCode = 400;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      void (^block)(id, NSHTTPURLResponse*, NSError*) = handlerSpy.argument;
      block(nil, response, nil);
      
      [[instance.dataQueue should] equal:[NSMutableArray array]];
      [instance.dataToSend shouldBeNil];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should remove from only dataToSend on any response", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      id yrmMock = [YozioRequestManager nullMock];
      [YozioRequestManager setInstance:yrmMock];
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:timeOut:handler:) atIndex:2];
      
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
      KWCaptureSpy *handlerSpy = [yrmMock captureArgument:@selector(urlRequest:timeOut:handler:) atIndex:2];
      
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
      instance.eventYozioProperties = [NSMutableDictionary dictionary];
      instance.linkYozioProperties = [NSMutableDictionary dictionary];

    });
    
    afterEach(^{
      KWClearAllMessageSpies();
      KWClearAllObjectStubs();
    });
    
    it(@"should set the experimentConfig, eventYozioProperties, linkYozioProperties if 200", ^{
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
      [[[instance.eventYozioProperties objectForKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] should] equal:experimentSids];
      [[[instance.linkYozioProperties objectForKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS] should] equal:experimentSids];
      
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
      [[instance.eventYozioProperties should] equal:[NSMutableDictionary dictionary]];
      [[instance.linkYozioProperties should] equal:[NSMutableDictionary dictionary]];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    context(@"if response comes back faster than blocking time", ^{
//      it(@"should set stopBlocking to true", ^{
//        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//        
//        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
//        
//        NSInteger statusCode = 200;
//        NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
//        NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"variation id", @"experiment id", nil];
//        id body = [NSDictionary dictionaryWithObjectsAndKeys:
//                   experimentConfig, YOZIO_CONFIG_KEY,
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
    });
    
    context(@"if response comes back slower than blocking time", ^{
//      it(@"should set stopBlocking to true", ^{
//        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//        
//        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
//        
//        NSInteger statusCode = 200;
//        NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
//        NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"variation id", @"experiment id", nil];
//        id body = [NSDictionary dictionaryWithObjectsAndKeys:
//                   experimentConfig, YOZIO_CONFIG_KEY,
//                   experimentSids, YOZIO_CONFIG_EXPERIMENT_VARIATION_SIDS_KEY,
//                   nil];
//        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
//                                                                  statusCode:statusCode
//                                                                 HTTPVersion:@"HTTP/1.1"
//                                                                headerFields:[NSDictionary dictionary]];
//        yrmMock.body = body;
//        yrmMock.response = response;
//        yrmMock.error = nil;
//        yrmMock.timeOut = 3;
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
    });

    context(@"if not 200 response", ^{
//      it(@"should set stopBlocking to true", ^{
//        YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
//        
//        YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
//        
//        NSInteger statusCode = 999;
//        NSDictionary *experimentConfig = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
//        NSDictionary *experimentSids = [NSDictionary dictionaryWithObjectsAndKeys:@"value", @"key", nil];
//        id body = [NSDictionary dictionaryWithObjectsAndKeys:
//                   experimentConfig, YOZIO_CONFIG_KEY,
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
        
        [[instance.eventYozioProperties should] equal:[NSMutableDictionary dictionary]];
        [[instance.linkYozioProperties should] equal:[NSMutableDictionary dictionary]];
        
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
        
        [[instance.eventYozioProperties should] equal:[NSMutableDictionary dictionary]];
        [[instance.linkYozioProperties should] equal:[NSMutableDictionary dictionary]];
        
        [YozioRequestManager setInstance:yrmInstance];
      });
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
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(updateUserName:)];
      [yozioMock stub:@selector(doCollect:linkName:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *linkNameSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:3];
      [Yozio setInstance:yozioMock];
      
      [Yozio userLoggedIn:@"popo" properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_LOGIN_ACTION];
      [[linkNameSpy.argument should] equal:@""];
      [[maxQueueSpy.argument should] equal:theValue(YOZIO_ACTION_DATA_LIMIT)];
      [[propertiesSpy.argument should] equal:[NSDictionary dictionary]];

      [Yozio setInstance:instance];
    });
  });
  context(@"viewedLink", ^{
    it(@"should call collect with the correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(doCollect:linkName:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *linkNameSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:3];
      [Yozio setInstance:yozioMock];
      
      [Yozio viewedLink:@"link name" properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_VIEWED_LINK_ACTION];
      [[linkNameSpy.argument should] equal:@"link name"];
      [[maxQueueSpy.argument should] equal:theValue(YOZIO_ACTION_DATA_LIMIT)];
      [[propertiesSpy.argument should] equal:[NSDictionary dictionary]];
      
      [Yozio setInstance:instance];
    });
  });

  context(@"sharedLink", ^{
    it(@"should call collect with the correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(doCollect:linkName:maxQueue:properties:)];
      KWCaptureSpy *typeSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:0];
      KWCaptureSpy *linkNameSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:1];
      KWCaptureSpy *maxQueueSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:2];
      KWCaptureSpy *propertiesSpy = [yozioMock captureArgument:@selector(doCollect:linkName:maxQueue:properties:) atIndex:3];
      [Yozio setInstance:yozioMock];
      
      [Yozio sharedLink:@"link name" properties:[NSDictionary dictionary]];
      [[typeSpy.argument should] equal:YOZIO_SHARED_LINK_ACTION];
      [[linkNameSpy.argument should] equal:@"link name"];
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
      NSString *linkName = @"link name";
      NSDictionary *properties = [NSDictionary dictionaryWithObject:@"value" forKey:@"property"];
      [instance stub:@selector(timeStampString) andReturn:@"time stamp string"];
      [instance stub:@selector(eventID) andReturn:@"event id"];
      [instance doCollect:type linkName:linkName maxQueue:YOZIO_ACTION_DATA_LIMIT properties:properties];
      [[theValue(instance.dataCount) should] equal:theValue(1)];
    });
    
    it(@"should add a new event to the dataQueue with correct parameters", ^{
      Yozio *instance = [Yozio getInstance];
      NSString *type = YOZIO_SHARED_LINK_ACTION;
      NSString *linkName = @"link name";
      NSDictionary *properties = [NSDictionary dictionaryWithObject:@"value" forKey:@"property"];
      [instance stub:@selector(timeStampString) andReturn:@"time stamp string"];
      [instance stub:@selector(eventID) andReturn:@"event id"];
      NSArray *expectedDataQueue = [NSArray arrayWithObjects:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     type, YOZIO_D_EVENT_TYPE,
                                     linkName, YOZIO_D_LINK_NAME,
                                     @"time stamp string", YOZIO_D_TIMESTAMP,
                                     @"event id", YOZIO_D_EVENT_IDENTIFIER,
                                     [properties JSONString], YOZIO_P_EXTERNAL_PROPERTIES,
                                     nil],
                                    nil];
      instance.dataQueue = [NSMutableArray array];
      [instance doCollect:type linkName:linkName maxQueue:YOZIO_ACTION_DATA_LIMIT properties:properties];
      [[instance.dataQueue should] equal:expectedDataQueue];
    });
  });
});

describe(@"getUrl", ^{
  context(@"", ^{
    it(@"should return destinationUrl if linkName is null", ^{
      Yozio *instance = [Yozio getInstance];
      instance.getUrlCache = [NSDictionary dictionaryWithObject:@"short url" forKey:@"twitter"];
      [[[Yozio getUrl:nil destinationUrl:@"destination url"] should] equal:@"destination url"];
      [[[Yozio getUrl:nil destinationUrl:@"destination url"] should] equal:@"destination url"];
    });
    
    it(@"should return null if destinationUrl is null", ^{
      Yozio *instance = [Yozio getInstance];
      instance.getUrlCache = [NSDictionary dictionaryWithObject:@"short url" forKey:@"twitter"];
      [[Yozio getUrl:@"twitter" destinationUrl:nil] shouldBeNil];
    });
    
    it(@"should call getUrlRequest with the correct parameters if single destination Url", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(getUrlRequest:destUrl:)];
      [yozioMock stub:@selector(_appKey) andReturn:@"app key"];
      [yozioMock stub:@selector(deviceId) andReturn:@"device id"];
      [yozioMock stub:@selector(linkYozioProperties) andReturn:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@"value" forKey:@"key"] forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS]];
      KWCaptureSpy *urlStringSpy = [yozioMock captureArgument:@selector(getUrlRequest:destUrl:) atIndex:0];
      KWCaptureSpy *destUrlSpy = [yozioMock captureArgument:@selector(getUrlRequest:destUrl:) atIndex:1];
      [Yozio setInstance:yozioMock];
      
      [Yozio getUrl:@"twitter" destinationUrl:@"destination url"];
      [[urlStringSpy.argument should] equal:@"http://yoz.io/api/viral/v1/get_url?app_key=app%20key&yozio_udid=device%20id&device_type=2&link_name=twitter&dest_url=destination%20url&yozio_properties=%7B%22experiment_variation_sids%22%3A%7B%22key%22%3A%22value%22%7D%7D"];
      [[destUrlSpy.argument should] equal:@"destination url"];
      
      [Yozio setInstance:instance];
    });
    
    it(@"should call getUrlRequest with the correct parameters if single destination Url with properties", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(getUrlRequest:destUrl:)];
      [yozioMock stub:@selector(_appKey) andReturn:@"app key"];
      [yozioMock stub:@selector(deviceId) andReturn:@"device id"];
      [yozioMock stub:@selector(linkYozioProperties) andReturn:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@"value" forKey:@"key"] forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS]];
      KWCaptureSpy *urlStringSpy = [yozioMock captureArgument:@selector(getUrlRequest:destUrl:) atIndex:0];
      KWCaptureSpy *destUrlSpy = [yozioMock captureArgument:@selector(getUrlRequest:destUrl:) atIndex:1];
      [Yozio setInstance:yozioMock];
      
      [Yozio getUrl:@"twitter"
     destinationUrl:@"destination url"
         properties:[NSDictionary dictionaryWithObject:@"prop value" forKey:@"prop key"]];
      [[urlStringSpy.argument should] equal:@"http://yoz.io/api/viral/v1/get_url?app_key=app%20key&yozio_udid=device%20id&device_type=2&link_name=twitter&dest_url=destination%20url&yozio_properties=%7B%22experiment_variation_sids%22%3A%7B%22key%22%3A%22value%22%7D%7D&external_properties=%7B%22prop%20key%22%3A%22prop%20value%22%7D"];
      [[destUrlSpy.argument should] equal:@"destination url"];
      
      [Yozio setInstance:instance];
    });
    
    it(@"should call getUrlRequest with the correct parameters if multiple destination Url", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(getUrlRequest:destUrl:)];
      [yozioMock stub:@selector(_appKey) andReturn:@"app key"];
      [yozioMock stub:@selector(deviceId) andReturn:@"device id"];
      [yozioMock stub:@selector(linkYozioProperties) andReturn:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@"value" forKey:@"key"] forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS]];
      KWCaptureSpy *urlStringSpy = [yozioMock captureArgument:@selector(getUrlRequest:destUrl:) atIndex:0];
      KWCaptureSpy *destUrlSpy = [yozioMock captureArgument:@selector(getUrlRequest:destUrl:) atIndex:1];
      [Yozio setInstance:yozioMock];
      
      [Yozio getUrl:@"twitter"
  iosDestinationUrl:@"ios destination"
androidDestinationUrl:@"android destination"
nonMobileDestinationUrl:@"non mobile destination"];
      [[urlStringSpy.argument should] equal:@"http://yoz.io/api/viral/v1/get_url?app_key=app%20key&yozio_udid=device%20id&device_type=2&link_name=twitter&ios_dest_url=ios%20destination&android_dest_url=android%20destination&non_mobile_dest_url=non%20mobile%20destination&yozio_properties=%7B%22experiment_variation_sids%22%3A%7B%22key%22%3A%22value%22%7D%7D"];
      [[destUrlSpy.argument should] equal:@"non mobile destination"];
      
      [Yozio setInstance:instance];
    });

    it(@"should call getUrlRequest with the correct parameters if multiple destination Url with properties", ^{
      Yozio *instance = [Yozio getInstance];
      
      id yozioMock = [Yozio mock];
      [yozioMock stub:@selector(getUrlRequest:destUrl:)];
      [yozioMock stub:@selector(_appKey) andReturn:@"app key"];
      [yozioMock stub:@selector(deviceId) andReturn:@"device id"];
      [yozioMock stub:@selector(linkYozioProperties) andReturn:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@"value" forKey:@"key"] forKey:YOZIO_P_EXPERIMENT_VARIATION_SIDS]];
      KWCaptureSpy *urlStringSpy = [yozioMock captureArgument:@selector(getUrlRequest:destUrl:) atIndex:0];
      KWCaptureSpy *destUrlSpy = [yozioMock captureArgument:@selector(getUrlRequest:destUrl:) atIndex:1];
      [Yozio setInstance:yozioMock];
      
      [Yozio getUrl:@"twitter"
  iosDestinationUrl:@"ios destination"
androidDestinationUrl:@"android destination"
nonMobileDestinationUrl:@"non mobile destination"
         properties:[NSDictionary dictionaryWithObject:@"prop value" forKey:@"prop key"]];
      [[urlStringSpy.argument should] equal:@"http://yoz.io/api/viral/v1/get_url?app_key=app%20key&yozio_udid=device%20id&device_type=2&link_name=twitter&ios_dest_url=ios%20destination&android_dest_url=android%20destination&non_mobile_dest_url=non%20mobile%20destination&yozio_properties=%7B%22experiment_variation_sids%22%3A%7B%22key%22%3A%22value%22%7D%7D&external_properties=%7B%22prop%20key%22%3A%22prop%20value%22%7D"];
      [[destUrlSpy.argument should] equal:@"non mobile destination"];
      
      [Yozio setInstance:instance];
    });

  });
});

describe(@"getUrlRequest", ^{
  context(@"", ^{
    it(@"should return destinationUrl if getUrlCache is null", ^{
      Yozio *instance = [Yozio getInstance];
      instance.getUrlCache = nil;
      [[[instance getUrlRequest:@"url string" destUrl:@"dest url"] should] equal:@"dest url"];
    });
    
    it(@"should return short link without making a request if the urlString exists in getUrlCache", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      [[yrmInstance should] receive:@selector(urlRequest:timeOut:handler:) withCount:0];
      
      Yozio *instance = [Yozio getInstance];
      instance.getUrlCache = [NSMutableDictionary dictionaryWithObject:@"short link" forKey:@"url string"];
      [[[instance getUrlRequest:@"url string" destUrl:@"dest url"] should] equal:@"short link"];
    });
    
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
      instance.getUrlCache = nil;
      [[[instance getUrlRequest:@"url string" destUrl:@"dest url"] should] equal:@"dest url"];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should update getUrlCache & return a short link on a 200", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      [YozioRequestManager setInstance:yrmMock];
      NSInteger statusCode = 200;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];

      yrmMock.body = [NSDictionary dictionaryWithObject:@"short link" forKey:@"url"];
      yrmMock.response = response;
      
      Yozio *instance = [Yozio getInstance];
      instance.getUrlCache = nil;
      [[[instance getUrlRequest:@"url string" destUrl:@"dest url"] should] equal:@"short link"];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should not update getUrlCache on any other response", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      [YozioRequestManager setInstance:yrmMock];
      NSInteger statusCode = 999;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      
      yrmMock.body = [NSDictionary dictionaryWithObject:@"short link" forKey:@"url"];
      yrmMock.response = response;
      
      Yozio *instance = [Yozio getInstance];
      instance.getUrlCache = [NSMutableDictionary dictionary];
      [instance getUrlRequest:@"url string" destUrl:@"dest url"];
      [[theValue([instance.getUrlCache count]) should] equal:theValue(0)];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should not update getUrlCache if the body isn't json", ^{
      YozioRequestManager *yrmInstance = [YozioRequestManager sharedInstance];
      YozioRequestManagerMock *yrmMock = [[YozioRequestManagerMock alloc] init];
      [YozioRequestManager setInstance:yrmMock];
      NSInteger statusCode = 200;
      NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"123"]
                                                                statusCode:statusCode
                                                               HTTPVersion:@"HTTP/1.1"
                                                              headerFields:[NSDictionary dictionary]];
      
      yrmMock.body = @"not dictionary";
      yrmMock.response = response;
      
      Yozio *instance = [Yozio getInstance];
      instance.getUrlCache = [NSMutableDictionary dictionary];
      [instance getUrlRequest:@"url string" destUrl:@"dest url"];
      [[theValue([instance.getUrlCache count]) should] equal:theValue(0)];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
    it(@"should not update getUrlCache if the value is nil", ^{
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
      
      Yozio *instance = [Yozio getInstance];
      instance.getUrlCache = [NSMutableDictionary dictionary];
      [instance getUrlRequest:@"url string" destUrl:@"dest url"];
      [[theValue([instance.getUrlCache count]) should] equal:theValue(0)];
      
      [YozioRequestManager setInstance:yrmInstance];
    });
    
  });
});


SPEC_END

