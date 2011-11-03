//
//  Yozio.h
//  GrenadeGame
//
//  Copyright 2011 Yozio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Yozio : NSObject

/**
 * Setup:
 *     Link the libraries "libYozio.a" and "Security.framework" to your binary.
 *     To do this in Xcode, click on your project in the Project navigator choose your target.
 *     Click on the "Build Phases" tab and add "libYozio.a" and "Security.framework" to the
 *     "Link Binary With Libraries" section.
 *
 * Instrumentation:
 *     Import Yozio.h in any file you wish to use Yozio.
 *     In your application delegate's applicationDidFinishLaunching method, configure Yozio:
 *
 *         [Yozio configure:@"550e8400-e29b-41d4-a716-446655440000"
 *                   userId:@"MyUserId"
 *                   bucket:@"control"
 *                      env:@"production"
 *               appVersion:@"1.0.1"];
 *
 *     Add instrumentation code at any point by calling any of the instrumentation methods.
 *
 *         [Yozio action:@"jump" context:@"Level 1" category:@"MyCategory"];
 *
 *     NOTE: Yozio is not thread safe. It is your responsibility to make sure that there are no
 *           concurrent calls to any Yozio methods.
 */


/**
 * Configures Yozio with your application's information.
 *
 * @param appId The unique application id that we provided you.
 * @param userId The id of the user currently using your application. If your application
 *               does not support users, pass in an empty string.
 * @param bucket The experiment group to use. This field is used for A/B testing.
 * @param env The environment that the application is currently running in (i.e. "production"
 *            or "sandbox").
 * @param appVersion The current version of your application.
 *
 * @example [Yozio configure:@"550e8400-e29b-41d4-a716-446655440000"
 *                   userId:@"MyUserId"
 *                   bucket:@"control"
 *                      env:@"production"
 *               appVersion:@"1.0.1"];
 */
+ (void)configure:(NSString *)appId
           userId:(NSString *)userId
           bucket:(NSString *)bucket
              env:(NSString *)env
       appVersion:(NSString *)appVersion;


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
 * @example [Yozio revenue:@"PowerShield" cost:20.5 category:@"MyCategory"];
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
 * @example [Yozio action:@"jump" context:@"Level 1"  category:@"MyCategory"];
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
 *          [Yozio error:@"Save Error" message:errorMsg category:@"MyCategory"];
 */
+ (void)error:(NSString *)errorName message:(NSString *)message category:(NSString *)category;


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

@end
