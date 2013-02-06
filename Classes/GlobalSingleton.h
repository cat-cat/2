//
//  GlobalSingleton.h
//  audiobook
//
//  Created by Mac Pro on 1/18/13.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
@class ASINetworkQueue;
@class Book;
@class MainViewController;
@class Reachability;

//static NSString* AppConnectionHost = @"192.168.0.155:8080";
static NSString* AppConnectionHost = @"192.168.0.100:8080";

@interface GlobalSingleton : NSObject
{    
    UINavigationController *navigationController;
    ASINetworkQueue* queue;
}
@property(nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) NSOperationQueue *queue;

+ (bool) handleError:(NSError*)err;
+ (Book*)db_GetBookWithID:(NSString*) bid;
+ (void) assertNoError:(int)noErrorFlag withMsg:(NSString*)message;
+ (const char*) dbname;
+ (GlobalSingleton*)sharedInstance;
@end
