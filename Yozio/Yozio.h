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
 *         [Yozio configure:@"http://m.snapette.yozio.com"
 *              userId:@"MyUserId"
 *              env:@"production"
 *              appVersion:@"1.0.1"
 *              exceptionHandler:&myExceptionHandler];
 *
 *     If you already set a global uncaught exception (NSSetUncaughtExceptionHandler), remove that
 *     code and pass your exception handler into the configure method.
 *
 *     Add instrumentation code at any point by calling any of the instrumentation methods.
 *
 *         [Yozio action:@"jump" context:@"Level 1" category:@"play"];
 *
 *     NOTE: Yozio is not thread safe. It is your responsibility to make sure that there are no
 *           concurrent calls to any of the Yozio methods.
 */


/**
 * Configures Yozio with your application's information.
 *
 * @param serverUrl The server url we provided you for your application.
 * @param userId The id of the user currently using your application. If your application
 *               does not support users, pass in an empty string.
 * @param env The environment that the application is currently running in. Possible values are
 *            "production" or "sandbox".
 * @param appVersion The current version of your application.
 * @param exceptionHandler A custom global uncaught exception handler for your application.
 *                         If you do not need to process uncaught exceptions, pass in nil.
 *
 * @example [Yozio configure:@"http://m.snapette.yozio.com"
 *              userId:@"MyUserId"
 *              env:@"production"
 *              appVersion:@"1.0.1"
 *              exceptionHandler:&myExceptionHandler];
 */
+ (void)configure:(NSString *)serverUrl
    userId:(NSString *)userId
    env:(NSString *)env
    appVersion:(NSString *)appVersion
    exceptionHandler:(NSUncaughtExceptionHandler *)exceptionHandler;


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
 * @param category The category to group this event under.
 * @throws NSException if no timer with timerName has been started.
 *
 * @example [Yozio startTimer:@"MyTimer"];
 *
 *          ...later on...
 *
 *          [Yozio endTimer:@"MyTimer" category:@"MyCategory"];
 */
+ (void)endTimer:(NSString *)timerName category:(NSString *)category;


/**
 * Instruments a new step in a funnel.
 *
 * @param funnelName The name of the funnel.
 * @param value The step of the funnel that has been reached.
 * @param category The category to group this event under.
 *
 * @example // User enters checkout page.
 *          [Yozio funnel:@"Checkout" value:@"Start Checkout" category:@"MyCategory"];
 *
 *          ...later on...
 *
 *          // User verified shopping cart and proceeds to checkout.
 *          [Yozio funnel:@"Checkout" value:@"Verified Cart" category:@"MyCategory"];
 *
 *          ...later on...
 *
 *          // User enterd shipping and billing information
 *          [Yozio funnel:@"Checkout" value:@"Submitted Billing Info" category:@"MyCategory"];
 *
 *          ...later on...
 *
 *          // User confirmed order and finishes purchase.
 *          [Yozio funnel:@"Checkout" value:@"Purchased!" category:@"MyCategory"];
 */
+ (void)funnel:(NSString *)funnelName value:(NSString *)value category:(NSString *)category;


/**
 * Instruments an item purchase.
 *
 * @param itemName The name of the item that was purchased.
 * @param cost The price the user payed to purchase the item.
 * @param category The category to group this event under.
 *
 * @example [Yozio revenue:@"PowerShield" cost:20.5 category:@"Defence"];
 */
+ (void)revenue:(NSString *)itemName cost:(double)cost category:(NSString *)category;


/**
 * Instruments some user action. An action can be anything, such as a button click.
 *
 * @param actionName The name of the action the user performed.
 * @param context The context in which the action was performed. For example, if your application
 *                is a game with muliple levels, each level can be the different context. Or if
 *                your application has multiple screens, each screen can be a different context.
 * @param category The category to group this event under.
 *
 * @example [Yozio action:@"jump" context:@"Level 1"  category:@"play"];
 */
+ (void)action:(NSString *)actionName context:(NSString *)context category:(NSString *)category;


/**
 * Instruments an error in your application.
 *
 * @param errorName The name of the error.
 * @param message The message associated with the error.
 * @param category The category to group this event under.
 *
 * @example NSError *error = ...;
 *          NSString *errorMsg = [error localizedFailureReason];
 *          [Yozio error:@"Save Error" message:errorMsg category:@"persistence"];
 */
+ (void)error:(NSString *)errorName message:(NSString *)message category:(NSString *)category;


/**
 * Convenience method for instrumenting caught exceptions.
 * Calling this exception is the equivalent of calling the error method with:
 *
 *    [Yozio error:exceptionName message:exceptionReason category:category]
 *
 * @param exception The caught exception to instrument.
 * @param category The category to group this event under.
 *
 * @example @try {
 *            [NSException raise:@"MyException"
 *                        reason:@"Some exception reason"];
 *          }
 *          @catch (id theException) {
 *            [Yozio exception:theException category:@"MyCategory"];
 *          }
 */
+ (void)exception:(NSException *)exception category:(NSString *)category;


/**
 * A general instrumentation method. Used to instrument miscellaneous events. Only use this if
 * none of the other methods can be used.
 *
 * @param key The name of the event to instrument.
 * @param value The value of the event to instrument.
 * @param category The category to group this event under.
 *
 * @example [Yozio collect:@"SomeEvent" value:@"SomeValue" category:@"MyCategory"];
 */
+ (void)collect:(NSString *)key value:(NSString *)value category:(NSString *)category;


/**
 * Forces Yozio to try to flush any unflushed instrumented events to the server.
 */
+ (void)flush;


/**
 * TODO(jt): document this
 */
+ (NSDictionary *)experimentData:(NSString *)experimentName;

@end

#endif /* ! __YOZIO__ */
