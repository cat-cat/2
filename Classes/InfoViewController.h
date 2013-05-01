//
//  InfoViewController.h
//  audiobook
//
//  Created by User on 30.03.13.
//
//

#import <UIKit/UIKit.h>

@interface InfoViewController : UIViewController

@property (strong, nonatomic) IBOutlet UISwitch *switchAutoPlay;
- (IBAction)btnRestorePurchasesClick:(UIButton *)sender;
- (IBAction)switchAutoPlayValueChanged:(UISwitch *)sender;
@end
