//
//  BookViewController.m
//  audiobook
//
//  Created by User on 15.03.13.
//
//

#import "BookViewController.h"
#import "UIImageView+WebCache.h"
#import "gs.h"
#import "PlayerViewController.h"
@interface BookViewController ()

@end

@implementation BookViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UIScrollView *sv = (UIScrollView*) self.view;
    UILabel* lblBig = (UILabel*)[self.view viewWithTag:102];
    CGFloat origin_y = lblBig.frame.origin.y;
    [sv setContentSize:CGSizeMake(sv.frame.size.width, origin_y + 25)];
}

-(void) dismissModalController { 
    [self dismissModalViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil bookId:(NSString*)bid
{
    self = [super initWithNibName:[gs nibFor:@"BookViewController" ] bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        bookId = [[NSString alloc] initWithString:bid];
        
        UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Закрыть"
                                                                        style:UIBarButtonItemStyleDone target:self action:@selector(dismissModalController)];
        self.navigationItem.rightBarButtonItem = rightButton;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    // Do any additional setup after loading the view from its nib.
    UIImageView* iv = (UIImageView*) [self.view viewWithTag:10];
    //AsyncImageView* iv = (AsyncImageView*) [cell viewWithTag:3];
    //[iv setImage:nil];
    [iv setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/v2/books/%@/BookImage.jpg", BookHost, bookId]]
       placeholderImage:[UIImage imageNamed:@"Placeholder"]];
    
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:bookId]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:@"/abooks/abook/title"];
    
    if ([arr count] == 1) {
        self.title = [arr objectAtIndex:0];
        UILabel* lblBig = (UILabel*)[self.view viewWithTag:9];
        lblBig.text = self.title;
    }
    
    arr = [gss() arrayForDoc:xmldoc xpath:@"/abooks/abook/publishers/name"];
    
    if ([arr count] > 0) {
        NSString* s = [arr componentsJoinedByString:@", "];
        UILabel* lblBig = (UILabel*)[self.view viewWithTag:101];
        lblBig.text = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    arr = [gss() arrayForDoc:xmldoc xpath:@"/abooks/abook/description"];
    
    if ([arr count] == 1) {
        NSString* s = [arr objectAtIndex:0];
        UILabel* lblBig = (UILabel*)[self.view viewWithTag:1];
        lblBig.text = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }

    arr = [gss() arrayForDoc:xmldoc xpath:@"/abooks/abook/price"];
    
    if ([arr count] == 1) {
        NSString* s = [arr objectAtIndex:0];
        UILabel* lblBig = (UILabel*)[self.view viewWithTag:2];
        lblBig.text = [NSString stringWithFormat:@"$%@", s];
    }
    
    arr = [gss() arrayForDoc:xmldoc xpath:@"/abooks/abook/authors"];

    if ([arr count] == 1) {
        NSString* s = [arr objectAtIndex:0];
        UILabel* lblBig = (UILabel*)[self.view viewWithTag:3];
        lblBig.text = s;
    }
    arr = [gss() arrayForDoc:xmldoc xpath:@"/abooks/abook/readers"];
    
    if ([arr count] == 1) {
        NSString* s = [arr objectAtIndex:0];
        UILabel* lblBig = (UILabel*)[self.view viewWithTag:4];
        lblBig.text = s;
    }
    arr = [gss() arrayForDoc:xmldoc xpath:@"/abooks/abook/length"];
    
    if ([arr count] == 1) {
        NSString* s = [arr objectAtIndex:0];
        UILabel* lblBig = (UILabel*)[self.view viewWithTag:5];
        lblBig.text = [NSString stringWithFormat:@"%d ч. %d мин.", [s intValue] / 3600, ([s intValue] % 3600) / 60];
    }
    arr = [gss() arrayForDoc:xmldoc xpath:@"/abooks/abook/size"];
    
    if ([arr count] == 1) {
        NSString* s = [arr objectAtIndex:0];
        UILabel* lblBig = (UILabel*)[self.view viewWithTag:6];
        lblBig.text = [NSString stringWithFormat:@"%.1f Мб", [s intValue] / 1024.0f / 1024.0f];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
