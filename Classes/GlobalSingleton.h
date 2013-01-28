//
//  GlobalSingleton.h
//  audiobook
//
//  Created by Mac Pro on 1/18/13.
//
//

#import <Foundation/Foundation.h>
#import "/usr/include/sqlite3.h"
@class CatalogViewController;
@class Reachability;

@interface GlobalSingleton : NSObject
{
}
+ (void) assertNoError:(int)noErrorFlag withMsg:(NSString*)message;
+ (const char*) dbname;
+ (GlobalSingleton*)sharedInstance;
@end
