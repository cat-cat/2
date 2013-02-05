//
//  ChaptersViewController.h
//  audiobook
//
//  Created by User on 2/4/13.
//
//

#import <UIKit/UIKit.h>

@interface ChaptersViewController : UITableViewController
{
    NSMutableArray* chapters;
    IBOutlet UITableView *view;
    int bookId;
}

-(id)initWithBook:(int) bid;
@end
