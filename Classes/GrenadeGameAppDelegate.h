//
//  GrenadeGameAppDelegate.h
//  GrenadeGame
//
//  Created by Robert Blackwood on 1/19/11.
//  Copyright Mobile Bros 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
@class YozioApi;

@interface GrenadeGameAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
  YozioApi *yozio;
}

@property (nonatomic, retain) UIWindow *window;

@end
