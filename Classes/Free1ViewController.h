//
//  Free1ViewController.h
//  audiobook
//
//  Created by User on 22.02.13.
//
//

#import <UIKit/UIKit.h>
#import "MyViewController.h"

@interface Free1ViewController : MyViewController <UITextFieldDelegate> {
    
    IBOutlet UITextField *txtCode;
    IBOutlet UITextField *txtEmail;
}
- (IBAction)getCode:(UIButton *)sender;
- (IBAction)checkCode:(UIButton *)sender;

@end
