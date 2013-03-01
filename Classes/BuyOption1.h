//
//  BuyOption1.h
//  audiobook
//
//  Created by User on 22.02.13.
//
//
#import <Foundation/Foundation.h>

@interface BuyOption1 : NSObject
-(BOOL)startWithBook:(NSString*)bid isfree:(BOOL)free;
+(BuyOption1*) sharedInstance;
@end
