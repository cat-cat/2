//
//  DownloadsViewController.h
//  audiobook
//
//  Created by User on 2/19/13.
//
//

#import <UIKit/UIKit.h>
#import "MyTableViewController.h"
@class StaticPlayer;
@interface DownloadsViewController : MyTableViewController
@property (nonatomic,strong) NSMutableArray* downq;
@property (nonatomic,strong) StaticPlayer* delegate;
- (id)initWithStyle:(UITableViewStyle)style andDelegate:(StaticPlayer*)d;

@end
