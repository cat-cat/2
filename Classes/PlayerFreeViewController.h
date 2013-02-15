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
#import "StreamingPlayer.h"
@class ASIHTTPRequest;
@class ChaptersViewController;
@class Book;
@interface PlayerFreeViewController : UIViewController <StreamingPlayerDelegate> {
    IBOutlet UIBarButtonItem *btnPlay;
    IBOutlet UIProgressView *progressView;
    IBOutlet UILabel *lbTimePassed;
    IBOutlet UILabel *lbTimeLeft;
    IBOutlet ChaptersViewController *chaptersController;
    __weak IBOutlet UITableView *chaptersTableView;
	BOOL bindProgressVal;
    Book *book;
    __weak IBOutlet UISlider *progressSlider;
//    __weak IBOutlet UILabel *labelSmallHeader;
//    __weak IBOutlet UILabel *labelHeader;
}

@property (nonatomic, assign) int bookId;
-(void)startChapter:(NSString*)chid;
- (IBAction)onSliderUpInside:(UISlider *)sender;

- (IBAction)onSliderDown:(UISlider *)sender;
- (IBAction)btnPlayStopClick:(UIBarButtonItem *)sender;
//@property (nonatomic, strong) NSString *message;
//- (IBAction)btnPressFF:(UIBarButtonItem *)sender;
//- (void)updateToBook:(NSString*)bid;
- (id)initWithBook:(int) bid;

@end
