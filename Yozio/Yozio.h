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
 *         [Yozio configure:@"myappKey"
 *              userId:@"MyUserId"
 *              env:@"production"
 *              appVersion:@"1.0.1"
 *              campaignSource:"google",
 *              campaignMedium:"cpc",
 *              campaignTerm:"twitter bird jump",
 *              campaignContent:"content",
 *              campaignName:"12873",
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
 * @param appKey The application name we provided you for your application.
 * @param userId The id of the user currently using your application. If your application
 *               does not support users, pass in an empty string.
 * @param env The environment that the application is currently running in. Possible values are
 *            "production" or "sandbox".
 * @param appVersion The current version of your application.
 * @param exceptionHandler A custom global uncaught exception handler for your application.
 *                         If you do not need to process uncaught exceptions, pass in nil.
 *
 * @example [Yozio configure:@"appKey"
 *              userId:@"MyUserId"
 *              env:@"production"
 *              appVersion:@"1.0.1"
 *              campaignSource:"google",
 *              campaignMedium:"cpc",
 *              campaignTerm:"twitter bird jump",
 *              campaignContent:"content",
 *              campaignName:"12873",



 *              exceptionHandler:&myExceptionHandler];
 */
+ (void)configure:(NSString *)appKey
           userId:(NSString *)userId
              env:(NSString *)env
       appVersion:(NSString *)appVersion
  campaignSource :(NSString *)campaignSource
  campaignMedium :(NSString *)campaignMedium
    campaignTerm :(NSString *)campaignTerm
 campaignContent :(NSString *)campaignContent
    campaignName :(NSString *)campaignName

    exceptionHandler:(NSUncaughtExceptionHandler *)exceptionHandler;

/**
 * Call this method when the userId becomes available.
 *
 * @param userId The id of the user currently using your application.
 *
 * @example [Yozio setUserId:@"MyUserId"
 */
+ (void)setUserId:(NSString *)userId;

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
 * @param category The category to group this event under.
 *
 * @example // User enters checkout page.
 *          [Yozio funnel:@"Checkout" category:@"MyCategory"];
 *
 *          ...later on...
 *
 *          // User verified shopping cart and proceeds to checkout.
 *          [Yozio funnel:@"Checkout" category:@"MyCategory"];
 *
 *          ...later on...
 *
 *          // User entered shipping and billing information
 *          [Yozio funnel:@"Checkout" category:@"MyCategory"];
 *
 *          ...later on...
 *
 *          // User confirmed order and finishes purchase.
 *          [Yozio funnel:@"Checkout" category:@"MyCategory"];
 */
+ (void)funnel:(NSString *)funnelName category:(NSString *)category;


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
 * @param category The category to group this event under.
 *
 * @example [Yozio action:@"jump" category:@"play"];
 */
+ (void)action:(NSString *)actionName category:(NSString *)category;


/**
 * Instruments an error in your application.
 *
 * @param errorName The name of the error.
 * @param category The category to group this event under.
 *
 * @example NSError *error = ...;
 *          [Yozio error:@"Save Error" category:@"persistence"];
 */
+ (void)error:(NSString *)errorName category:(NSString *)category;


/**
 * Convenience method for instrumenting caught exceptions.
 * Calling this exception is the equivalent of calling the error method with:
 *
 *    [Yozio exception:theException category:@"MyCategory"]
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
 * @param name The name of the event to instrument.
 * @param amount The amount of the event to instrument.
 * @param category The category to group this event under.
 *
 * @example [Yozio collect:@"SomeEvent" amount:@"SomeValue" category:@"MyCategory"];
 */
+ (void)collect:(NSString *)name amount:(NSString *)amount category:(NSString *)category;


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
