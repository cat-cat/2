/******************************************************************************
 * Copyright (c) 2009, Maher Ali <maher.ali@gmail.com>
 * iPhone SDK 3 Programming - Advanced Mobile Development for Apple iPhone and iPod touch
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

#import "BookViewController.h"
#import "MainViewController.h"
#import "Book.h"
#import "AppDelegate.h"
#import "GlobalSingleton.h"
#import "PlayerFreeViewController.h"
#import "ChaptersViewController.h"

@implementation BookViewController
//@synthesize nameLabel = _nameLabel, book = _book;

- (IBAction)btnSeeChaptersClick:(id)sender {
    
    //*****
    ChaptersViewController* chaptersViewController = [[ChaptersViewController alloc] initWithBook:book.abookId];
    
    //            if (bookViewController.view) {// !!! accessing view will initialize view with all controls before it's shown
    //                [bookViewController.nameLabel setText:g.name]; // !!! will work only after "if" above
    //            }
    
    
    //*****
    
    //CharacterViewController *characterController = [[CharacterViewController alloc] initWithDelegate:delegate andBookID:g.ID];
    [[GlobalSingleton sharedInstance].navigationController pushViewController:chaptersViewController animated:YES];
    
}

- (IBAction)btnPlayFreeClicked:(UIButton *)sender {
    
    PlayerFreeViewController *playerController = [[PlayerFreeViewController alloc] initWithBook:book.abookId];
    [[GlobalSingleton sharedInstance].navigationController pushViewController:playerController animated:YES];

    
//    AppDelegate *d = [[UIApplication sharedApplication] delegate];
//    PlayerFreeViewController* player = [d getViewControllerForTabIndex:3];
//    [player updateToBook:[NSString stringWithFormat:@"%d", book.abookId]];
//    
//    [d changeViewControllerToIndex:3];
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle andBook:(NSString*) bid
{
    if (self = [super initWithNibName:nibName bundle:nibBundle]) {
        // custom initialization
        book = [GlobalSingleton db_GetBookWithID:bid];
    }
    return self;
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = book.title; // navigation bar title
    [_nameLabel setText:book.title];
}

//- (void)loadView {
//    [self view].backgroundColor = [UIColor whiteColor];
//    
//    return;
////	TVAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//	theView   = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
//	theView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
//	theView.backgroundColor = [UIColor  whiteColor];
//    	
//    // name label
//	//CGRect labelFrame =  CGRectMake(80, 10, 190, 50);
////	nameLabel = [[UILabel alloc] initWithFrame:labelFrame];
////    nameLabel.font = [UIFont systemFontOfSize:25.0];
////	nameLabel.textColor = [UIColor  blackColor];
////	nameLabel.backgroundColor = [UIColor clearColor];
////	nameLabel.textAlignment = UITextAlignmentLeft;   
////	nameLabel.lineBreakMode = UILineBreakModeWordWrap;
//	NSString  *theName = [delegate characterNameForShowIndex:delegate.selectedShow.row atIndex:delegate.selectedCharacter.row];
////	nameLabel.text = [NSString stringWithFormat:@"%@:  %@", @"Name", theName];
//    //theView addSubview: nameLabel];
//	UIImageView   *imgView = [[UIImageView alloc] 
//								initWithImage:[UIImage
//												imageNamed:[NSString stringWithFormat:@"%@.jpg",  theName]]];
//	imgView.frame = CGRectMake(30, 70, 250, 300);
//	//[theView addSubview:imgView];
//    
//    
//    // addButton
//    UIButton* myButton =
//    [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    myButton.frame = CGRectMake(40.0, 100.0, 190, 50);
//    [myButton setTitle:@"Слушать бесплатно" forState:UIControlStateNormal];
//    [myButton addTarget:self
//                 action:@selector(listenFree:)
//       forControlEvents:UIControlEventTouchUpInside];
//    //[theView addSubview: myButton];
//    
//    
//    //*****
////    NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:@"CharacterViewController"
////                                                      owner:self
////                                                    options:nil];
////    CharacterViewController* nibView = [[CharacterViewController alloc] initWithNibName:@"CharacterViewController" bundle:[NSBundle mainBundle]];
////    
////    CharacterViewController* cView = [ nibViews objectAtIndex: 1];
////    cView.nameLabel.text = theName;
//    
//    //*****
//    
//	
//	//self.view = cView.view;
//}




@end
