//
//  Copyright 2011 Yozio. All rights reserved.
//

#if !defined(__YOZIO__)
#define __YOZIO__ 1

#import <Foundation/Foundation.h>

@interface Yozio : NSObject

/**
 * Setup:
 *     Link the libraries "libYozio.a" and "Security.framework" to your binary.
 *     To do this in Xcode 4, click on your project in the Project navigator and choose your target.
 *     Click on the "Build Phases" tab and add "libYozio.a" and "Security.framework" to the
 *     "Link Binary With Libraries" section.
 *
 * Instrumentation:
 *     Import Yozio.h in any file you wish to use Yozio.
 *     In your application delegate's applicationDidFinishLaunching method, configure Yozio:
 *
 *         TODO(jt): use more realistic configure example
 *         [Yozio configure:@"appKey" secretKey:@"mySecretKey"];
 *
 *     Optionally set additional application information.
 *         [Yozio setApplicationVersion:@"1.0.1"];
 *         TODO(jt): add other optional setters here
 *         
 *
 *     TODO(jt): possibly add campaign example
 *
 *     If you already set a global uncaught exception (NSSetUncaughtExceptionHandler), remove that
 *     code and pass your exception handler into the configure method.
 *
 *     Add instrumentation code at any point by calling any of the instrumentation methods.
 *
 *         [Yozio action:@"jump"];
 *
 *     NOTE: Yozio is not thread safe. It is your responsibility to make sure that there are no
 *           concurrent calls to any of the Yozio methods.
 */


/**
 * Configures Yozio with your application's information.
 *
 * @param appKey  The application name we provided you for your application.
 * @param secretKey  The top secret key that only you know about. Don't share this with others!
 *
 * TODO(jt): use more realistic configure example
 * @example [Yozio configure:@"appKey" secretKey:@"mySecretKey"];
 */
+ (void)configure:(NSString *)appKey secretKey:(NSString *)secretKey;


/**
 * Set the application version. This allows you to segment your instrumented data across your
 * different application versions.
 *
 * @param appVersion  The version of your application.
 *
 * @example [Yozio setApplicationVersion:@"1.0.1"];
 */
+ (void)setApplicationVersion:(NSString *)appVersion;


/**
 * TODO(jt): do we need this?
 */
+ (void)setEnvironment:(NSString *)environment;


/**
 * Set the id of the user using the application. This is useful for applications where the
 * application user can be identified by some sort of id (i.e. user name, email address, etc).
 *
 * @param userId  The id of the user currently using the application.
 *
 * @example [Yozio setUserId:self.userEmailAddress];
 */
+ (void)setUserId:(NSString *)userId;


/**
 * TODO(jt): do we actually need this?
 * TODO(jt): document this
 */
+ (void)setCampaign:(NSString *)campaignName
     campaignSource:(NSString *)campaignSource
     campaignMedium:(NSString *)campaignMedium
       campaignTerm:(NSString *)campaignTerm
    campaignContent:(NSString *)campaignContent;


/**
 * Registers a global exception handler to handle uncaught exceptions in your application.
 *
 * @param exceptionHandler  The NSUncaughtExceptionHandler to handle all uncaught exceptions.
 *
 * @example [Yozio setUncaughtExceptionHandler:&myExceptionHandler];
 */
+ (void)setUncaughtExceptionHandler:(NSUncaughtExceptionHandler *)exceptionHandler;


/**
 * TODO(jt): document
 */
+ (void)newSession;


/**
 * Starts a new timer. This call by itself will not trigger an instrumentation event. You must
 * call endTimer with the same timerName to capture the timing information.
 *
 * @param timerName A unique name to assign the timer. Use this name in the endTimer method to
 *                  to stop the timer.
 *
 * @example [Yozio startTimer:@"MyTimer"];
 */
+ (void)startTimer:(NSString *)timerName;


/**
 * Stops a timer started with startTimer and instruments the elapsed time.
 *
 * @param timerName The name of the timer to end. Must be the same as the one used in startTimer.
 * @throws NSException if no timer with timerName has been started.
 *
 * @example [Yozio startTimer:@"MyTimer"];
 *
 *          ...later on...
 *
 *          [Yozio endTimer:@"MyView"];
 */
+ (void)endTimer:(NSString *)timerName;

/**
 * Instruments an item purchase.
 *
 * @param itemName The name of the item that was purchased.
 * @param cost The price the user payed to purchase the item.
 *
 * @example [Yozio revenue:@"PowerShield" cost:20.5];
 */
+ (void)revenue:(NSString *)itemName cost:(double)cost;


/**
 * Instruments some user action. An action can be anything, such as a button click.
 *
 * @param actionName The name of the action the user performed.
 *
 * @example [Yozio action:@"jump"];
 */
+ (void)action:(NSString *)actionName;


/**
 * Instruments an error in your application.
 *
 * @param errorName The name of the error.
 *
 * @example NSError *error = ...;
 *          [Yozio error:@"Save Error"];
 */
+ (void)error:(NSString *)errorName;


/**
 * Convenience method for instrumenting caught exceptions.
 * Calling this exception is the equivalent of calling the error method with:
 *
 *    [Yozio exception:theException]
 *
 * @param exception The caught exception to instrument.
 *
 * @example @try {
 *            [NSException raise:@"MyException"
 *                        reason:@"Some exception reason"];
 *          }
 *          @catch (id theException) {
 *            [Yozio exception:theException];
 *          }
 */
+ (void)exception:(NSException *)exception;


/**
 * Forces Yozio to try to flush any unflushed instrumented events to the server.
 */
+ (void)flush;


/**
 * TODO(jt): document this
 */
+ (NSString *)stringForKey:(NSString *)key defaultValue:(NSString *)defaultValue;

/**
 * TODO(jt): document this
 */
+ (NSInteger)intForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;

@end

#endif /* ! __YOZIO__ */
