//
//  DownloadsViewController.h
//  audiobook
//
//  Created by User on 2/19/13.
//
//

#import <UIKit/UIKit.h>
@class StaticPlayer;
@interface DownloadsViewController : UITableViewController
@property (nonatomic,strong) NSMutableArray* downq;
@property (nonatomic,strong) StaticPlayer* delegate;
- (id)initWithStyle:(UITableViewStyle)style andDelegate:(StaticPlayer*)d;

@end
