/******************************************************************************
 * Copyright (c) 2009, Maher Ali <maher.ali@gmail.com>
 * iPhone SDK 3 Programming - Advanced Mobile Development for Apple iPhone and iPod touch
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

#import "AppDelegate.h"
//#import "CDBViewController.h"
#import "MainViewController.h"
#import "gs.h"
#import "PlayerViewController2.h"
#import "Myshop.h"
#import "CatalogViewController.h"
#import <AVFoundation/AVFoundation.h>

@implementation AppDelegate

//- (id)getViewControllerForTabIndex:(int)index
//{
//    return [tabBarController.viewControllers objectAtIndex:index];
//}
UIBackgroundTaskIdentifier bgTask;
NSTimer *backgroundTimer;

-(BOOL)taskActive
{
    // TODO: add StaticPlayer as well
    return [StaticPlayer2 playerIsPlaying] || [UIApplication sharedApplication].networkActivityIndicatorVisible;
}

-(void) onPerformBackgroundTask:(id) sender
{    
    if (![self taskActive])
    {
        [backgroundTimer invalidate];
        backgroundTimer = nil;
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
    
    if ([self taskActive])
    {
        bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        }];
        
        if (!backgroundTimer)
        {
            backgroundTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(onPerformBackgroundTask:) userInfo:nil repeats:YES];
        }
    }
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	NSLog(@"Received notification: %@", userInfo);
//	[self addMessageFromRemoteNotification:userInfo updateUI:YES];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	NSLog(@"My token is: %@", deviceToken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
  
//    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    
	window = [[UIWindow alloc] initWithFrame:[[UIScreen  mainScreen] bounds]] ;
    gss();

	
//	mainViewController = [[MainViewController alloc]
//                     initWithMessage:@"Triangle"
//                     andImage:[UIImage imageNamed:@"tri.png"]];
//	mainViewController.title =  @"Каталог";
    
    CatalogViewController *genresViewController = [[CatalogViewController alloc] initWithStyle:UITableViewStylePlain andParentGenre:@"-1"];
    gss().navigationController = [[UINavigationController alloc] initWithRootViewController:genresViewController];
    gss().navigationController.navigationBar.translucent = NO;

    // init main navigation controller in catalogViewController as well
    
//	viewController2 = [[CDBViewController alloc]
//                     initWithMessage:@"Rectangle"
//                     andImage:[UIImage imageNamed:@"rect.png"]];
//	viewController2.title =  @"Rect";
//	viewController3 = [[CDBViewController alloc] 
//                     initWithMessage:@"Ellipse"
//                     andImage:[UIImage imageNamed:@"ellipse.png"]];
//	viewController3.title =  @"Elli";
//	viewController4 = [[PlayerViewController alloc] initWithNibName:@"PlayerFreeView" bundle:nil];
//	viewController4.title =  @"Слушать";
//	viewController5 = [[CDBViewController alloc] 
//                     initWithMessage:@"Играть книгу"
//                     andImage:[UIImage imageNamed:@"rect-tri.png"]];
//	viewController5.title =  @"R&T";
//	viewController6 = [[CDBViewController alloc] 
//                     initWithMessage:@"Rectangle+Rectangle"
//                     andImage:[UIImage imageNamed:@"two-tri.png"]];
//	viewController6.title =  @"R&R";
//	tabBarController = [[UITabBarController alloc] init];
//	tabBarController.viewControllers = [NSArray arrayWithObjects:
//                                      mainViewController,
//                                      nil];
    //	tabBarController.viewControllers = [NSArray arrayWithObjects:
    //                                      mainViewController,
    //                                      viewController2,
    //                                      viewController3,
    //                                      viewController4,
    //                                      viewController5,
    //                                      viewController6,
    //                                      nil];

	//[window addSubview:tabBarController.view]; // warning: Application windows are expected to have a root view controller at the end of application launch
    //[tabBarController setHidesBottomBarWhenPushed:YES];
    //window.rootViewController = tabBarController;
//    window.rootViewController = mainViewController;
    window.rootViewController = gss().navigationController;
    
	[window makeKeyAndVisible];
    
    // init global singleton instance
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[Myshop sharedInstance]];
    
    // set to play audio in the background TODO: not checked
    // allows you to play in the background when app is suspended in iOS4
    //[[AVAudioSession sharedInstance] setDelegate: self];
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error:NULL];
    
    
    // init google tracker gantracker
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 178;
    // Optional: set debug to YES for extra debugging information.
    //[GAI sharedInstance].debug = YES;
    // Create tracker instance.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-39335784-1"];
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"autoplay"]) {
        [ud setBool:YES forKey:@"autoplay"];
    }
    
    if (launchOptions != nil)
	{
		NSDictionary *dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (dictionary != nil)
		{
			NSLog(@"Launched from push notification: %@", dictionary);
//			[self addMessageFromRemoteNotification:dictionary updateUI:NO];
		}
	}

    return YES;
}

//- (void)changeViewControllerToIndex:(NSUInteger)idx
//{
//    [GlobalSingleton sharedInstance];
//    tabBarController.selectedIndex = idx;
//}

@end
