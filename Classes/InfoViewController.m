//
//  InfoViewController.m
//  audiobook
//
//  Created by User on 30.03.13.
//
//

#import "InfoViewController.h"
#import "Myshop.h"
#import "gs.h"

@interface InfoViewController ()

@end

@implementation InfoViewController
-(void) dismissModalController {
    [self dismissModalViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:[gs nibFor:@"InfoViewController" ] bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть"
                                                                        style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalController)];
        self.navigationItem.rightBarButtonItem = rightButton;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Информация";

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnRestorePurchasesClick:(UIButton *)sender {
    [self dismissModalViewControllerAnimated:YES];
    [[Myshop sharedInstance] restorePurchases];
}
@end
