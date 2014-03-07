//
//  ChaptersViewController.h
//  audiobook
//
//  Created by User on 2/4/13.
//
//

#import <UIKit/UIKit.h>
#import "MyTableViewController.h"
@class PlayerViewController2;
@interface ChaptersViewController2 : MyTableViewController
{
    IBOutlet PlayerViewController2 *playerController;
    NSMutableArray* chapters;
//    int bookId;
}
//@property (nonatomic, assign) int bookId;
-(void) updateProgressForChapterIdentity:(NSString*)chapterIdentity value:(float)val;
-(void)chapterFinishDownload:(NSString*)chapterIdentity;
-(void)first;
-(void) scrollToLastSelection;
- (IBAction)next:(UIBarButtonItem *)sender;
- (IBAction)prev:(UIBarButtonItem *)sender;
@end
