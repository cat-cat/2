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
#import "CDBViewController.h"
#import "MainViewController.h"
#import "gs.h"
#import "PlayerViewController.h"
#import "Myshop.h"

@implementation AppDelegate

//- (id)getViewControllerForTabIndex:(int)index
//{
//    return [tabBarController.viewControllers objectAtIndex:index];
//}
UIBackgroundTaskIdentifier bgTask;
NSTimer *backgroundTimer;

-(BOOL)taskActive
{
    return [StaticPlayer playerIsPlaying] || [UIApplication sharedApplication].networkActivityIndicatorVisible;
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


- (void)applicationDidFinishLaunching:(UIApplication *)application {
  
	window = [[UIWindow alloc] initWithFrame:[[UIScreen  mainScreen] bounds]] ;
    gss();

	
	mainViewController = [[MainViewController alloc]
                     initWithMessage:@"Triangle"
                     andImage:[UIImage imageNamed:@"tri.png"]];
	mainViewController.title =  @"Каталог";
    // init main navigation controller in catalogViewController as well
    
	viewController2 = [[CDBViewController alloc]
                     initWithMessage:@"Rectangle"
                     andImage:[UIImage imageNamed:@"rect.png"]];
	viewController2.title =  @"Rect";
	viewController3 = [[CDBViewController alloc] 
                     initWithMessage:@"Ellipse"
                     andImage:[UIImage imageNamed:@"ellipse.png"]];
	viewController3.title =  @"Elli";
	viewController4 = [[PlayerViewController alloc] initWithNibName:@"PlayerFreeView" bundle:nil];
	viewController4.title =  @"Слушать";
	viewController5 = [[CDBViewController alloc] 
                     initWithMessage:@"Играть книгу"
                     andImage:[UIImage imageNamed:@"rect-tri.png"]];
	viewController5.title =  @"R&T";
	viewController6 = [[CDBViewController alloc] 
                     initWithMessage:@"Rectangle+Rectangle"
                     andImage:[UIImage imageNamed:@"two-tri.png"]];
	viewController6.title =  @"R&R";
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
    window.rootViewController = mainViewController;
    
	[window makeKeyAndVisible];
    
    // init global singleton instance
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[Myshop sharedInstance]];
}

//- (void)changeViewControllerToIndex:(NSUInteger)idx
//{
//    [GlobalSingleton sharedInstance];
//    tabBarController.selectedIndex = idx;
//}

@end
