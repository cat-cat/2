//
//  Free1ViewController.h
//  audiobook
//
//  Created by User on 22.02.13.
//
//

#import <UIKit/UIKit.h>

@interface Free1ViewController : UIViewController <UITextFieldDelegate> {
    
    IBOutlet UITextField *txtCode;
    IBOutlet UITextField *txtEmail;
}
- (IBAction)getCode:(UIButton *)sender;
- (IBAction)checkCode:(UIButton *)sender;

@end
