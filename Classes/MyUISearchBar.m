//
//  MyUISearchBar.m
//  audiobook
//
//  Created by User on 20.06.14.
//
//

#import "MyUISearchBar.h"

@implementation MyUISearchBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)layoutSubviews
{
    [super layoutSubviews];
    if([[UIDevice currentDevice].systemVersion floatValue]>=7.0) {
        //Get search bar with scope bar to reappear after search keyboard is dismissed
        [[[[self.subviews objectAtIndex:0] subviews] objectAtIndex:0] setHidden:NO];
        [self setShowsScopeBar:YES];
    }
}

-(void) setShowsScopeBar:(BOOL)showsScopeBar {
    [super setShowsScopeBar:YES]; //Initially make search bar appear with scope bar
}
@end
