//
//  ChaptersViewController.h
//  audiobook
//
//  Created by User on 2/4/13.
//
//

#import <UIKit/UIKit.h>
@class PlayerFreeViewController;
@interface ChaptersViewController : UITableViewController
{
    __weak IBOutlet PlayerFreeViewController *playerController;
    NSMutableArray* chapters;
    int bookId;
}
//@property (nonatomic, assign) int bookId;
-(void)first;
-(void) scrollToLastSelection;
- (IBAction)next:(UIBarButtonItem *)sender;
- (IBAction)prev:(UIBarButtonItem *)sender;
@end
