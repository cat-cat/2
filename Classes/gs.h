//
//  GlobalSingleton.h
//  audiobook
//
//  Created by Mac Pro on 1/18/13.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
@class DDXMLDocument;
@class ASINetworkQueue;
@class Book;
@class MainViewController;
@class Reachability;

static NSString* AppConnectionHost = @"192.168.0.100:8080";

@interface gs : NSObject
{    
    UINavigationController *navigationController;
//    ASINetworkQueue* queue;
}
@property(nonatomic, strong) UINavigationController *navigationController;

-(NSString*)pathForBuy:(int)bid;
+(NSString*)md5:(NSString*)object;
-(int)bidFromChapterIdentity:(NSString*)ci;

-(NSString*)chidFromChapterIdentity:(NSString*)ci;

-(DDXMLDocument*) docForFile:(NSString*)path;
-(NSString*) pathForBookMeta:(int)bid;
-(NSString*) pathForBookFinished:(int)bid chapter:(NSString*) ch;
-(NSString*) pathForBook:(int)bid andChapter:(NSString*) ch;
-(NSArray*) arrayForDoc:(DDXMLDocument *)doc xpath:(NSString*) xpath;
- (NSString*)dirsForBook:(int)bid;
- (bool) handleError:(NSError*)err;
- (int) handleSrvError:(NSString*)err;
+ (Book*)db_GetBookWithID:(NSString*) bid;
+ (void) assertNoError:(int)noErrorFlag withMsg:(NSString*)message;
+ (const char*) dbname;
+ (gs*)sharedInstance;
@end

gs* gss();
