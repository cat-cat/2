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
+ (bool) checkNetworkStatus:(NSNotification *)notice;
+(UITableViewCell*) catalogCellForBook:(NSString*)bid tableView:(UITableView*)tableView title:(NSString*)title;
@property(nonatomic, strong) UIButton* playerButton;
@property(nonatomic, strong) UINavigationController *navigationController;
+(void)db_MybooksRemove:(NSString*)bid;
+(NSArray*)db_GetMybooks;
//+(NSArray*)srvArrForUrl:(NSString*)strWithFormat args:(NSArray*)arguments xpath:(NSString*)xp message:(NSString*)msg;
+(NSArray*)srvArrForUrl:(NSString*)strUrl xpath:(NSString*)xp message:(NSString*)msg;
-(NSString*)pathForBuy:(NSString*)bid;
//+(NSString*)md5:(NSString*)object;
-(NSString*)bidFromChapterIdentity:(NSString*)ci;

-(NSString*)chidFromChapterIdentity:(NSString*)ci;

-(DDXMLDocument*) docForFile:(NSString*)path;
-(NSString*) pathForBookMeta:(NSString*)bid;
-(NSString*) pathForBookFinished:(NSString*)bid chapter:(NSString*) ch;
-(NSString*) pathForBook:(NSString*)bid andChapter:(NSString*) ch;
-(NSArray*) arrayForDoc:(DDXMLDocument *)doc xpath:(NSString*) xpath;
- (NSString*)dirsForBook:(NSString*)bid;
- (bool) handleError:(NSError*)err;
- (int) handleSrvError:(NSString*)err;
+ (Book*)db_GetBookWithID:(NSString*) bid;
+ (void) assertNoError:(int)noErrorFlag withMsg:(NSString*)message;
+ (const char*) dbname;
+ (gs*)sharedInstance;
@end

gs* gss();
