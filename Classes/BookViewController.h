//
//  BookViewController.h
//  audiobook
//
//  Created by User on 15.03.13.
//
//

#import <UIKit/UIKit.h>

@interface BookViewController : UIViewController {
    NSString* bookId;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil bookId:(NSString*)bid;
@end
