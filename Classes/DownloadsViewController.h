//
//  DownloadsViewController.h
//  audiobook
//
//  Created by User on 2/19/13.
//
//

#import <UIKit/UIKit.h>
#import "MyTableViewController.h"
@class StaticPlayer2;
@interface DownloadsViewController : MyTableViewController
@property (nonatomic,strong) NSMutableArray* downq;
@property (nonatomic,strong) StaticPlayer2* delegate;
- (id)initWithStyle:(UITableViewStyle)style andDelegate:(StaticPlayer2*)d;

@end
