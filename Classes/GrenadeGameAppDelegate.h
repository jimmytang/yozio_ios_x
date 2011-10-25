//
//  GrenadeGameAppDelegate.h
//  GrenadeGame
//
//  Created by Robert Blackwood on 1/19/11.
//  Copyright Mobile Bros 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
@class Yozio;

@interface GrenadeGameAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
  Yozio *yozio;
}

@property (nonatomic, retain) UIWindow *window;

@end
