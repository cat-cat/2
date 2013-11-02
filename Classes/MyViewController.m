//
//  MyViewController.m
//  audiobook
//
//  Created by User on 13.03.13.
//
//

#import "MyViewController.h"
#import "PlayerViewController.h"

@interface MyViewController ()

@end

@implementation MyViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)goPlayer:(id)sender
{
    //    NSLog(@"++ player button click");
    PlayerViewController* playerView = [[PlayerViewController alloc] initWithBook:0];
    [self.navigationController pushViewController:playerView animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view.
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    
    if ([StaticPlayer sharedInstance].shouldShowPlayerButton) {
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc]
                                       initWithTitle: @"Плеер"
                                       style:UIBarButtonItemStylePlain
                                       target:self
                                        action:@selector(goPlayer:)];
        
        self.navigationItem.rightBarButtonItem = rightButton;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
