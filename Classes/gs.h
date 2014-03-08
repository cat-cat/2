//
//  GlobalSingleton.h
//  audiobook
//
//  Created by Mac Pro on 1/18/13.
//
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "GAI.h"
#import "OpenUDID.h"
@class CatalogItem;
@class DDXMLDocument;
@class ASINetworkQueue;
@class Book;
@class MainViewController;
@class Reachability;

//static NSString* BookHost = @"192.168.0.100:8080"; // for PhpEd
//static NSString* BookHost = @"192.168.0.100"; // for WAMP
//static NSString* BookHost = @"178.218.217.70"; // for books server
static NSString* BookHost = @"book-smile.ru";
static int TAG_PLAYER_VIEW = 20;

@interface gs : NSObject
{    
    UINavigationController *navigationController;
//    ASINetworkQueue* queue;
}
+(NSString*)nibFor:(NSString*)nibname;
+(BOOL)canGetMetaForBook:(NSString*)bookId;
+ (bool) nfInternetAvailable:(NSNotification *)notice;
+(UITableViewCell*) catalogCellForBook:(CatalogItem*)ci tableView:(UITableView*)tableView;
//@property(nonatomic, strong) UIButton* playerButton;
@property(nonatomic, strong) UINavigationController *navigationController;
+(void)db_MybooksRemove:(NSString*)bid;
+(NSArray*)db_GetMybooks;
//+(NSArray*)srvArrForUrl:(NSString*)strWithFormat args:(NSArray*)arguments xpath:(NSString*)xp message:(NSString*)msg;
+(NSArray*)srvArrForUrl:(NSString*)strUrl xpath:(NSString*)xp message:(NSString*)msg;
-(NSString*)pathForBuy:(NSString*)bid;
+(NSString*)md5:(NSString*)object;
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
