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
#import "MyViewController.h"

//*************** StaticPlayer
@interface StaticPlayer : NSObject <StreamingPlayerDelegate, UIActionSheetDelegate> {
}
+(BOOL)checkBuyBook;
+(BOOL)playerIsPlaying;
+(StaticPlayer*) sharedInstance;
+(void) deleteBook:(NSString*)bid;
+ (void) buyBook;
- (void) removeDownqObject:(NSString *)object;
@property (nonatomic,assign) BOOL shouldShowPlayerButton;
@property (nonatomic, strong) NSString* bookID;
@property (nonatomic, strong) NSMutableArray* downq; // queue for downloading
@end


//************** PlayerViewController
@class ASIHTTPRequest;
@class ChaptersViewController;
@interface PlayerViewController : MyViewController {
    IBOutlet UIBarButtonItem *btnPlay;
    IBOutlet UIProgressView *progressView;
    IBOutlet UILabel *lbTimePassed;
    IBOutlet UILabel *lbTimeLeft;
    IBOutlet ChaptersViewController *chaptersController;
    IBOutlet UITableView *chaptersTableView;
    IBOutlet UISlider *progressSlider;
    //    __weak IBOutlet UILabel *labelSmallHeader;
    //    __weak IBOutlet UILabel *labelHeader;
}
+(void)db_InsertMybook:(NSString*)bid;
+ (void) showAlertAtTimer:(NSString*)msg delay:(int)delayInSeconds;
- (IBAction)btnBuyBookClick:(UIBarButtonItem *)sender;
+(NSInteger) metaSizeForChapter:(NSString*)bid chapter:(NSString*) chid;
+(NSInteger) actualSizeForChapter:(NSString*)bid chapter:(NSString*)chid;
+(void)startPlayer;
+(void)startChapter:(NSString *)chid;
+(void)downqNextAfter:(ASIHTTPRequest*)req;
+ (void)setPassedTime:(double)passedTime leftTime:(double)leftTime;
+(void)setDelegates:(id)obj;
+(void)db_SaveTrackProgress;
+(void)checkChapter:(NSString*)chid;
+(NSString*)chapterIdentityFromRequest:(ASIHTTPRequest*)req;
+(void)appendChapterIdentityForDownloading:(NSString*)chapterIdentity;
+(float)calcDownProgressForBook:(NSString*)bid chapter:(NSString*)chid;

+(void)startChapter:(NSString*)chid;
- (IBAction)onSliderUpInside:(UISlider *)sender;
- (IBAction)btnOpenDownloadQueueClick:(UIBarButtonItem *)sender;

- (IBAction)onSliderDown:(UISlider *)sender;
- (IBAction)btnPlayStopClick:(UIBarButtonItem *)sender;
//@property (nonatomic, strong) NSString *message;
//- (IBAction)btnPressFF:(UIBarButtonItem *)sender;
//- (void)updateToBook:(NSString*)bid;
- (id)initWithBook:(NSString*) bid;

@end
