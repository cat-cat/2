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

#import "PlayerViewController2.h"
#import "gs.h"
#import "Book.h"
#import "ASIHTTPRequest.h"
#import "AudioStreamer.h"
#import "DDXMLDocument.h"
#import "ChaptersViewController.h"
#import "DownloadsViewController.h"
#import "Myshop.h"
#import "Free1ViewController.h"
#import "MBProgressHUD.h"
#import "Myshop.h"
#import "BookViewController.h"
#import "InfoViewController.h"

MBProgressHUD *HUD22 = nil;
PlayerViewController2* PlayerViewController2Ptr = nil;
static ASIHTTPRequest* currentRequest2;
BOOL isBought2 = NO;
//static int bookId;
//NSInteger trackSize = 0, metaTrackSize = 0;
bool NeedToStartWithFistDownloadedBytes2 = false;
static BOOL bindProgressVal2;
ChaptersViewController *chaptersControllerPtr2;
UIProgressView *progressViewPtr2;
UISlider *progressSliderPtr2;
UIBarButtonItem *btnPlayPtr2;
UIBarButtonItem* btnBuyPtr2;
UIToolbar* toolbarPlayerPtr2;

#pragma - mark StaticPlayer2
@implementation StaticPlayer2
//enum BuyButtons {BB_BUY, BB_GETFREE, BB_CANCEL};
enum BuyButtons {BB_BUY, BB_CANCEL, BB_GETFREE};

-(void)goVote:(id)sender
{
//    NSString *escaped = [@"https://itunes.apple.com/ru/app/booksmile/id616060097?l=ru&ls=1&mt=8" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:@"itms://itunes.apple.com/ru/app/booksmile/id616060097?l=ru&ls=1&mt=8"];

    [[UIApplication sharedApplication] openURL:url];
}

+(BOOL)checkBuyBook
{
    NSError* error;
    NSString* buy = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[gss() pathForBuy:[StaticPlayer2 sharedInstance].bookID] ] encoding:NSUTF8StringEncoding error:&error];
    [gss() handleError:error];
    if (buy && [buy rangeOfString:@"yes"].location != NSNotFound) {
        isBought2 = YES;
        if (btnBuyPtr2) {
            NSArray* tms = toolbarPlayerPtr2.items;
            UIBarButtonItem* bb = [[UIBarButtonItem alloc] initWithTitle:@"Отзыв" style:UIBarButtonSystemItemEdit target:[StaticPlayer2 sharedInstance] action:@selector(goVote:)];
            [toolbarPlayerPtr2 setItems:@[[tms objectAtIndex:0],[tms objectAtIndex:1],[tms objectAtIndex:2],[tms objectAtIndex:3],[tms objectAtIndex:4],[tms objectAtIndex:5], bb]];
        }
    }
    else
    {
        isBought2 = NO;
    }
    
    return isBought2;
}

+(void) deleteBook:(NSString*)bid
{
    @synchronized([[StaticPlayer2 sharedInstance] downq])
    {
        NSMutableArray* downq = [[StaticPlayer2 sharedInstance] downq];
//        for (NSString* s in downq) {
//            if ([s hasPrefix:bid] ) {
//                [downq removeObject:bid];
//            }
//        }
        
        NSMutableArray *discardedItems = [NSMutableArray array];
        
        for (NSString* s in downq) {
            if ([s hasPrefix:bid])
                [discardedItems addObject:s];
        }
        
        [downq removeObjectsInArray:discardedItems];
    }
    
    if (currentRequest2 && [[PlayerViewController2 chapterIdentityFromRequest:currentRequest2] hasPrefix:bid]) {
        [currentRequest2 cancel];
    }
    
    // Optional wait for completeon of the request
    [NSThread sleepForTimeInterval:0.3];
    
    // remove files for book
    NSString* chaptersAudioPath = [[gss() dirsForBook:bid ] stringByAppendingString:@"/ca"];
    NSError* error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:chaptersAudioPath error:&error];
    [gss() handleError:error];
    if (success) {
        [gs db_MybooksRemove:bid];
    }
    NSString *pathToMeta = [gss() pathForBookMeta:bid];
    success = [[NSFileManager defaultManager] removeItemAtPath:pathToMeta error:&error];
    [gss() handleError:error];
    if(!success)
        NSLog(@"++warning! cannot remove bookMeta for bid: %@", bid);


//	removeFromDownqAllChaptersOfBook(bid);
//
//	if(currentDownloadingBook = bid)
//		cancelDownload(currentDownload);
//    
//	success = removeFolder("tmp/book/ca");
//	if(folder.notexist or success)
//		db.mybooks.remove(bid);
}

+(void) buyBook
{
    isBought2 = YES;
    
    if (btnBuyPtr2) {
        NSArray* tms = toolbarPlayerPtr2.items;
        UIBarButtonItem* bb = [[UIBarButtonItem alloc] initWithTitle:@"Отзыв" style:UIBarButtonSystemItemEdit target:[StaticPlayer2 sharedInstance] action:@selector(goVote:)];
        [toolbarPlayerPtr2 setItems:@[[tms objectAtIndex:0],[tms objectAtIndex:1],[tms objectAtIndex:2],[tms objectAtIndex:3],[tms objectAtIndex:4],[tms objectAtIndex:5], bb]];
    }

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Покупка книги"
                                                    message:@"Книга куплена, поздравляем!"
                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void) removeDownqObject:(NSString *)object
{
    NSString* strURL = [PlayerViewController2 chapterIdentityFromRequest:currentRequest2];
    
    if ([strURL isEqualToString:object]) {
        [currentRequest2 cancel]; // will remove request from downq in onRequestFailed
    }
    else
    {
        @synchronized(self.downq)
        {
            [self.downq removeObject:object];
        }
    }
}

- (BOOL) downqContainsObject:(NSString *)object
{
    @synchronized(self.downq)
    {
        return [self.downq containsObject:object];
    }
}

-(void) setPlayButton:(int)play
{
    if (play)
        [btnPlayPtr2 setImage:[UIImage imageNamed:@"player_button_pause.png"]];
    else
        [btnPlayPtr2 setImage:[UIImage imageNamed:@"player_button_play.png"]];
}

-(void)showHUD
{
    if (!HUD22) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        HUD22 = [MBProgressHUD showHUDAddedTo:PlayerViewController2Ptr.view animated:YES];
    }
    //hud.mode = MBProgressHUDModeAnnularDeterminate;
	
    //	// Regiser for HUD callbacks so we can remove it from the window at the right time
    //	HUD.delegate = self;
	
	// Show the HUD while the provided method executes in a new thread
	//[HUD showWhileExecuting:@selector(myTask) onTarget:self withObject:nil animated:YES];    
}

-(void)hideHUD
{
    if (HUD22) {
        [MBProgressHUD hideHUDForView:PlayerViewController2Ptr.view animated:YES];
        HUD22=nil;        
    }
}

- (void) streamingPlayerIsWaiting:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player IsWaiting");
    if (PlayerViewController2Ptr) {
        [self showHUD];
        HUD22.labelText = @"пожалуйста, подождите...";
        [self performSelector:@selector(hideHUD) withObject:nil afterDelay:5];
    }
}
- (void) streamingPlayerDidStartPlaying:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player DidStartPlaying");
    if (PlayerViewController2Ptr) {
        [self hideHUD];
    }
    
    [PlayerViewController2 db_InsertMybook:[NSString stringWithFormat:@"%@",sPlayer.bookId]];
    bindProgressVal2 = YES;
    [sPlayer.streamer performSelector:@selector(doVolumeFadeIn) withObject:nil afterDelay:1.0];
}

- (BOOL) isFreeFragmentBookId:(NSString*)bid chapter:(NSString*)chid {
    NSString* fMetaPath = [NSString stringWithFormat:@"%@/%@",[[gs sharedInstance] dirsForBook:bid ],  @"bookMeta.xml"];
    NSError *error;
    NSString* str = [NSString stringWithContentsOfFile:fMetaPath encoding:NSUTF8StringEncoding error:&error];
    [[gs sharedInstance] handleError:error];
    
    // get fragment xml
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:str options:0 error:&error];
    [[gs sharedInstance] handleError:error];
    
    NSString *xp = [NSString stringWithFormat:@"/abooks/abook/content/track[@number='%@']/name", chid];
    NSArray *items=[doc nodesForXPath:xp error:&error];
    
    NSString *chapterName = [[items objectAtIndex:0] stringValue];
    if ([chapterName isEqualToString:@"Бесплатный фрагмент"]) {
        return YES;
    }
    return NO;
}

- (void) streamingPlayerDidStopPlaying:(StreamingPlayer *) anPlayer {
    // check If chapter dowloaded correctly
    [PlayerViewController2 checkChapter:sPlayer.chapter];
 
    NSString* chid = sPlayer.chapter;
    NSString* bid = sPlayer.bookId;
    
    if (!isBought2 && [self isFreeFragmentBookId:bid chapter:chid]) { // play only free fragment
        [self showBuyActionSheet];
    }
    
    // reinit player
    [sPlayer myrelease];
    sPlayer = nil;
    double stopValue = progressSliderPtr2.value;
    if (progressSliderPtr2) {
        progressSliderPtr2.value = 0.0;
    }
    [PlayerViewController2 db_SaveTrackProgress];
    sPlayer = [[StreamingPlayer alloc] initPlayerWithBook:bid  chapter:chid];
    [sPlayer setDelegate:[StaticPlayer2 sharedInstance]];
    [PlayerViewController2 setDelegates:[StaticPlayer2 sharedInstance]];
    bindProgressVal2 = YES;
    
    if (PlayerViewController2Ptr) {
        [self hideHUD];
    }
    
    // create a standardUserDefaults variable
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    // getting an NSString object
    bool autoplay = [standardUserDefaults boolForKey:@"autoplay"];
    if (stopValue==progressSliderPtr2.maximumValue&&autoplay) {
        [chaptersControllerPtr2 next:NULL];
    }
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    NSLog(@"++alertView button clicked at index %d", buttonIndex);
//    if (buttonIndex == 1) { // yes
//        
//        if (![gs nfInternetAvailable:nil])
//        {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ошибка сети"
//                                                            message:@"Для получения бесплатной книги нужен интернет. Проверьте соединение."
//                                                           delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//            [alert show];
//            
//            return;
//        }
//
//        [[Myshop sharedInstance] startWithBook:[StaticPlayer2 sharedInstance].bookID isfree:YES];
//    }
//}


BOOL buyQueryStarted2 = NO;
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"++actionsheet item clicked at index %d", buttonIndex);
    buyQueryStarted2 = NO;
    switch (buttonIndex) {
        case BB_GETFREE:
        {
            // TODO: check inet, then loading screen
            NSString *devid = [OpenUDID value];
            NSArray *arr = [gs srvArrForUrl:[NSString stringWithFormat:@"http://%@/v2/free1checkcode.php?dev=%@", BookHost, devid] xpath:@"//freeflag" message:[NSString stringWithFormat:@"unable to get freeflag: %s", __func__ ]];
            int freeflag = [[arr objectAtIndex:0] intValue];

            switch (freeflag) {
                case 1: // can use free book
                    // you'we got free book
                {
                Book* b = [gs db_GetBookWithID:[NSString stringWithFormat:@"%@",[StaticPlayer2 sharedInstance].bookID ]];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Получение бесплатной книги"
                                                                message:[NSString stringWithFormat:@"Хотите получить бесплатно книгу %@?", b.title] delegate:self cancelButtonTitle:@"Нет" otherButtonTitles:@"Да", nil];
                [alert show];
                    break;
                }
                case 0: // should register email and promocode first
                {
                    self.shouldShowPlayerButton = NO;
                    Free1ViewController* vc = [[Free1ViewController alloc] initWithNibName:[gs nibFor: @"Free1ViewController"] bundle:nil];
                    [[gss() navigationController] pushViewController:vc animated:YES];
                    break;
                }
                case 2: // already used
                {
                    [PlayerViewController2 showAlertAtTimer:@"Бесплатная книга уже получена" delay:1];
                    break;
                }
                    
                default:
                    break;
            }
            
            break;
        }
        case BB_BUY:
        {
            [[Myshop sharedInstance] requestProductData:[StaticPlayer2 sharedInstance].bookID];
            break;
        }
        
            
        default:
            break;
    }
}

//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
//{
//    NSLog(@"++actionsheet item clicked at index %d", buttonIndex);
//    buyQueryStarted = NO;
//}

- (void) showBuyActionSheet
{
    if (buyQueryStarted2) { // may come here from different places at different time
        return;
    }
    
    // show action sheet
    UIActionSheet *
    actionSheet = [[UIActionSheet alloc]
                   initWithTitle:@"Купите книгу для прослушивания всех глав полностью" delegate:self cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil otherButtonTitles:@"Купить"/*, @"Получить бесплатно"*/, nil];
    [actionSheet showInView:PlayerViewController2Ptr.view];
    buyQueryStarted2 = YES;
}

- (void) streamingPlayer:(StreamingPlayer *) anPlayer didUpdateProgress:(double) anProgress {

//    if (buyQueryStarted) {
//        return;
//    }
    
    if (!isBought2 && [[StaticPlayer2 sharedInstance].bookID isEqualToString: sPlayer.bookId] && ![sPlayer.bookId hasPrefix:@"lrs"] /*don't interrupt at 70% litres books*/) {
//        float actual = anProgress;
//        float max = progressSliderPtr2.maximumValue;
//        float procSize = (actual / max) * 100;
        if ([sPlayer.streamer isPlaying] && !buyQueryStarted2) {
            if ([sPlayer.streamer isPlaying]) {
                [sPlayer.streamer stop];   
            }
            
            [self showBuyActionSheet];
        }
//        int length = [self metaLengthForChapter:sPlayer.chapter];
//        int val = (procSize / 100) * length;
//        return val;

    }
    
    if (bindProgressVal2 && progressSliderPtr2 && ([[StaticPlayer2 sharedInstance].bookID isEqualToString: sPlayer.bookId])) {
        progressSliderPtr2.value = anProgress;
        float passedTime = anProgress;
        float leftTime   = progressSliderPtr2.maximumValue - anProgress;
        [PlayerViewController2 setPassedTime:passedTime leftTime:leftTime];
        //NSLog(@"++ player DidUpdateProgress: %f", anProgress);
    }
}


- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
//    for (id key in responseHeaders) {
//        NSLog(@"key: %@, value: %@ \n", key, [responseHeaders objectForKey:key]);
//    }
    // [[NSFileManager defaultManager] removeItemAtPath:currentTrack.audioFilePath error:nil];
    //if(![[NSFileManager defaultManager] fileExistsAtPath:currentTrack.audioFilePath])
}

- (void) request:(ASIHTTPRequest *)request didReceiveBytes:(unsigned long long) bytes
{
    // NSLog(@"++bytes received: %lld", bytes);
    if (!progressViewPtr2)  // if not visible then nothing calculate and display
        return;

    
    NSString* strURL = [PlayerViewController2 chapterIdentityFromRequest:request];
    NSString *bid = [gss() bidFromChapterIdentity:strURL];
    NSString *chid = [gss() chidFromChapterIdentity:strURL];
    
    float progressVal = 0.0;
    if([[StaticPlayer2 sharedInstance].bookID isEqualToString: bid] && [sPlayer.chapter isEqualToString:chid])
    {
        NSInteger trackSize = [PlayerViewController2 actualSizeForChapter:bid chapter:chid];            
        
        NSInteger metaTrackSize = [PlayerViewController2 metaSizeForChapter:bid chapter:chid];

        //trackSize += bytes;
        progressVal = (float)trackSize/(float)metaTrackSize;
        progressViewPtr2.progress = progressVal;
        
        if (NeedToStartWithFistDownloadedBytes2)
        {
            NeedToStartWithFistDownloadedBytes2 = false;
            if (sPlayer.streamer.state == AS_INITIALIZED) {
                if (PlayerViewController2Ptr) {
                    [self showHUD];
                }
                [PlayerViewController2 performSelector:@selector(startPlayer) withObject:nil afterDelay:2.0];
            }
            else
                NSLog(@"**err: player is not initialized");
        }
    }
    else
    {
        int sz = [PlayerViewController2 actualSizeForChapter:bid chapter:chid];
        int lnt = [PlayerViewController2 metaSizeForChapter:bid chapter:chid];
        progressVal = (float)sz/(float)lnt;
    }
    
    if(chaptersControllerPtr2)
        [chaptersControllerPtr2 updateProgressForChapterIdentity:[PlayerViewController2 chapterIdentityFromRequest: request ] value:progressVal];
    
    
    //    else
    //        [sPlayer.streamer pause];
    //
    //    return;
    
    
    
    
    //    NSFileHandle   *fileHandle =
    //    [NSFileHandle fileHandleForUpdatingAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@"tmp/m.mp3"]];
    //    NSURL *bookURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"tmp/m.mp3"]];
    //    if (sPlayer==nil) {
    //        [self initPlayerWithUrl:bookURL];
    //    }
    
    
    //    if(fileHandle){
    //        [fileHandle seekToFileOffset:11];
    //        NSData *appendedData =
    //        [@" modified " dataUsingEncoding:NSUTF8StringEncoding];
    //[fileHandle writeData:appendedData];
    //[fileHandle closeFile];
    //    }
}

//- (void)request:(ASIHTTPRequest *)request didReceiveData:(NSData *)data
//{

// if (!ourData)
//   ourData = [NSMutableData dataWithLength:kBufferSize*1000];

//            [ourData appendData:data];
//
//            fileSize += data.length;

//                [self.trackFile seekToEndOfFile];
//                [self.trackFile writeData:data];
//ourData = nil;
//               book.isFreePartBeginDownload = YES;
//               [dbManager InsUpdBookHeader:book];
//}

static StreamingPlayer *sPlayer = nil;

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"++Finished request !");
    NSString* strURL = [PlayerViewController2 chapterIdentityFromRequest:request];
    NSString* bid = [gss() bidFromChapterIdentity:strURL];
    NSString* chid = [gss() chidFromChapterIdentity:strURL];
    NSString *path = [gss() pathForBookFinished:bid chapter:chid];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    bool fileCreationSuccess = [ fm createFileAtPath:path contents:nil  attributes:nil];
    if(fileCreationSuccess == NO){ NSLog(@"Failed to create the finished! file"); }
    
    // set up requests queue
    [PlayerViewController2 downqNextAfter:request];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"**err: request failed description %@, url: %@", [request.error description], [request url]);
    //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // set up requests queue
    [PlayerViewController2 downqNextAfter:request];
}



+ (StaticPlayer2 *)sharedInstance
{
    static StaticPlayer2 *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[StaticPlayer2 alloc] init];
        // Do any other initialisation stuff here
        [sharedInstance setDownq:[[NSMutableArray alloc] init] ];
        sharedInstance.shouldShowPlayerButton=NO;

    });
    
    
    //...
    return sharedInstance;
}

+(BOOL)playerIsPlaying
{
    BOOL res = NO;
    if (sPlayer && [sPlayer.streamer isPlaying]) {
        res = YES;
    }
    return res;
}

@end
//******************** END StaticPlayer

#pragma - mark PlayerViewController2
@implementation PlayerViewController2
static UILabel *lbTimePassedPtr;
static UILabel *lbTimeLeftPtr;
static Book *book;

- (IBAction)btn30Forward:(UIBarButtonItem *)sender {
    if (sPlayer && [sPlayer.streamer isPlaying] && [sPlayer.bookId isEqualToString:[StaticPlayer2 sharedInstance].bookID]) {
        if(progressSlider.maximumValue > progressSlider.value + 40.0)
            [sPlayer.streamer seekToTime:progressSlider.value + 25.0];
        // else do nothing
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Функция" message:@"Перемотать на 30 сек. вперед" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] ;
        [alert show];        
    }
    
}

- (IBAction)btn30Back:(UIBarButtonItem *)sender {
    if (sPlayer && [sPlayer.streamer isPlaying] && [sPlayer.bookId isEqualToString:[StaticPlayer2 sharedInstance].bookID]) {
        if ( 0.0 < progressSlider.value - 40.0)
            [sPlayer.streamer seekToTime:progressSlider.value - 35.0];            
        else
            [sPlayer.streamer seekToTime:0.0];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Функция" message:@"Перемотать на 30 сек. назад" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] ;
        [alert show];
    }
}

- (IBAction)btnBookDetailsClick:(UIBarButtonItem *)sender
{
    BookViewController* secondaryCtrl1 = [[BookViewController alloc]
                                          initWithNibName:nil
                                          bundle:nil bookId:[StaticPlayer2 sharedInstance].bookID];
    UINavigationController *secondaryNavigationCtrl = [[UINavigationController alloc]
                                                                          initWithRootViewController:secondaryCtrl1];
    [self presentModalViewController:secondaryNavigationCtrl animated:YES];
}

+(NSString*)chapterIdentityFromRequest:(ASIHTTPRequest*)req
{
    NSString* resultString;
    resultString = [req.userInfo objectForKey:@"chid" ];
    //NSString *htmlString = @"http://192.168.0.100:80/books/3456/chaptersAudio/01_02_crypt.mp3";
//    NSString *htmlString = url;
//    @try {
//        NSRegularExpression *nameExpression = [NSRegularExpression regularExpressionWithPattern:@"/books/(\\w+)/chaptersAudio/(\\w+)_crypt.mp3" options:NSRegularExpressionSearch error:nil];
//        
//        NSArray *matches = [nameExpression matchesInString:htmlString
//                                                   options:0
//                                                     range:NSMakeRange(0, [htmlString length])];
//        for (NSTextCheckingResult *match in matches) {
//            //NSRange matchRange = [match range];
//            NSRange matchRange = [match rangeAtIndex:1];
//            NSString *matchString1 = [htmlString substringWithRange:matchRange];
//            matchRange = [match rangeAtIndex:2];
//            NSString *matchString2 = [htmlString substringWithRange:matchRange];
//            //NSLog(@"%@:%@", matchString1, matchString2);
//            resultString = [NSString stringWithFormat:@"%@:%@", matchString1, matchString2 ];
//        }
//    }
//    
//    @catch (NSException *exception) {
//        NSLog(@"**err: error getting chapter's identity for url: %@", url);
//    }
    
    return resultString;
}

// called only from finished or failed requests, so we should remove it from download queue
+(void)downqNextAfter:(ASIHTTPRequest*)req
{
    NSString* object = [self chapterIdentityFromRequest:req];
    
    //if([[gss() downq] count] > 1)
    @synchronized([[StaticPlayer2 sharedInstance] downq])
    {
        [[[StaticPlayer2 sharedInstance] downq] removeObject:object];
    }
    
    if (chaptersControllerPtr2) {
        [chaptersControllerPtr2 chapterFinishDownload:object];
    }
    
    @synchronized([[StaticPlayer2 sharedInstance] downq])
    {
        for (NSString* item in [[StaticPlayer2 sharedInstance] downq]) {
            NSString* curChId = [self chapterIdentityFromRequest:currentRequest2];
            if ([curChId isEqualToString:item]) {
                continue;
            }
            // drop here for the only item from downq, which is not being downloaded already
            [self startDownloadBook:[gss() bidFromChapterIdentity:item] chapter:[gss() chidFromChapterIdentity:item]];
            break;
        }
    }
}


+(void)startPlayer
{
    float stps = [self db_GetTrackProgress];
    if (stps == 0) {
        [sPlayer.streamer start];
    }
    else
    {
        int val = [self getPossibleProgressVal];
        if (stps < val) {
            [sPlayer.streamer startAtPos:stps withFade:NO doPlay:YES];
        }
        else
        {
            [sPlayer.streamer startAtPos:val withFade:NO doPlay:YES];
        }
    }
}

//- (IBAction)btnPressFF:(UIBarButtonItem *)sender {
//}
// TODO: must permenently add index to the thracks table
//+(void)runOnce
//{
//    sqlite3* db;
//    int returnCode = sqlite3_open([gs dbname], &db);
//    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot open : %s", __func__, sqlite3_errmsg(db) ]];
//    returnCode = sqlite3_exec(db, "delete from t_tracks", 0, 0, 0);
//    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannnot execute : %s", __func__, sqlite3_errmsg(db) ]];
//    returnCode = sqlite3_exec(db, "create unique index idx_t_tracks on t_tracks (abook_id, track_id)", 0, 0, 0);
//    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannnot execute : %s", __func__, sqlite3_errmsg(db) ]];
//}


+(void)db_InsertMybook:(NSString*)bid
{    
    sqlite3* db;
    
    //    [self runOnce];
    
    // OPEN DB
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr cannot open db: %s", sqlite3_errmsg(db) ]];
    
    const char *sqlStatement = "INSERT OR REPLACE INTO mybooks (abook_id, last_touched) VALUES (?, CURRENT_TIMESTAMP)";
    sqlite3_stmt *compiledStatement;
    
    returnCode = sqlite3_prepare_v2(db, sqlStatement, -1, &compiledStatement, NULL);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**err db prepare2: %s", sqlite3_errmsg(db) ]];
    
    sqlite3_bind_text(compiledStatement, 1, [[NSString stringWithFormat:@"%@",[StaticPlayer2 sharedInstance].bookID] UTF8String], -1, SQLITE_TRANSIENT);
    
    returnCode = sqlite3_step(compiledStatement);
    [gs assertNoError:returnCode==SQLITE_DONE withMsg:[NSString stringWithFormat:@"**dberr %s: cannot step  %s", __func__, sqlite3_errmsg(db) ]];
    
    returnCode = sqlite3_finalize(compiledStatement);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot finalize : %s", __func__, sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot close db : %s", __func__, sqlite3_errmsg(db) ]];
    
}

+(void)db_SaveTrackProgress
{
    //[self runOnce];
    
    if (!sPlayer || ![sPlayer.chapter length] || ![sPlayer.bookId isEqualToString: [StaticPlayer2 sharedInstance].bookID]) {
        return;
    }
    
    sqlite3* db;
    
    //    [self runOnce];
    
    // OPEN DB
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr cannot open db: %s", sqlite3_errmsg(db) ]];
    
    const char *sqlStatement = "INSERT OR REPLACE INTO t_tracks (abook_id, track_id, current_progress) VALUES (?, ?, ?)";
    sqlite3_stmt *compiledStatement;
    
    returnCode = sqlite3_prepare_v2(db, sqlStatement, -1, &compiledStatement, NULL);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**err db prepare2: %s", sqlite3_errmsg(db) ]];
    
    sqlite3_bind_text(compiledStatement, 1, [[StaticPlayer2 sharedInstance].bookID UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(compiledStatement, 2, [sPlayer.chapter UTF8String], -1, SQLITE_TRANSIENT);
    
    if(progressSliderPtr2)
    {
        float testVal = progressSliderPtr2.value - 8.0;
        float valToSave = testVal > 0.0 ? testVal : 0.0;
        NSLog(@"Progress : %lf", valToSave);
        sqlite3_bind_double(compiledStatement, 3, valToSave);
    }
    else
    {
        sqlite3_bind_double(compiledStatement, 3, 0);
    }
        
    returnCode = sqlite3_step(compiledStatement);
    [gs assertNoError:returnCode==SQLITE_DONE withMsg:[NSString stringWithFormat:@"**dberr %s: cannot step  %s", __func__, sqlite3_errmsg(db) ]];
    
    returnCode = sqlite3_finalize(compiledStatement);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot finalize : %s", __func__, sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot close db : %s", __func__, sqlite3_errmsg(db) ]];
}

+(float)db_GetTrackProgress
{
    if (!sPlayer || ![sPlayer.chapter length] || ![sPlayer.bookId isEqualToString: [StaticPlayer2 sharedInstance].bookID]) {
        return 0.0;
    }
    
    // assuming its not called from multiple threads, only from gui
    
    sqlite3* db;
    
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to open db: %s", sqlite3_errmsg(db) ]];
    char *sqlStatement;
    
    sqlStatement = sqlite3_mprintf("SELECT current_progress from t_tracks where track_id='%s' AND abook_id='%s'"
                                   " LIMIT 0,1", [sPlayer.chapter UTF8String], [sPlayer.bookId UTF8String]);
    
    sqlite3_stmt *statement;
    
    returnCode =
    sqlite3_prepare_v2(db, sqlStatement, strlen(sqlStatement), &statement, NULL);
    [gs assertNoError:returnCode==SQLITE_OK withMsg: [NSString stringWithFormat: @"Unable to prepare statement: %s",sqlite3_errmsg(db) ]];
    
    sqlite3_free(sqlStatement);
    
    
    // get result
    float f = 0;
    returnCode = sqlite3_step(statement);
    while(returnCode == SQLITE_ROW){
        f = (float)sqlite3_column_double(statement, 0);
        returnCode = sqlite3_step(statement);
    }
    returnCode = sqlite3_finalize(statement);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot finalize %s", sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"Cannot close %s", sqlite3_errmsg(db) ]];
    
    return f;
}

+(void)checkChapter:(NSString*)chid
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    bool finished_exists = [fileManager fileExistsAtPath:[gss() pathForBookFinished:[StaticPlayer2 sharedInstance].bookID chapter:chid]];
    NSInteger actualSize = [self actualSizeForChapter:[StaticPlayer2 sharedInstance].bookID chapter:chid];
    NSInteger metaSize = [self metaSizeForChapter:[StaticPlayer2 sharedInstance].bookID chapter:chid];
    
    if((finished_exists && actualSize<metaSize) || (!finished_exists && actualSize<400))
    {
        NSError *error;
        [fileManager removeItemAtPath:[gss() pathForBookFinished:[StaticPlayer2 sharedInstance].bookID chapter:chid] error:&error];
        if (error) {
            NSLog(@"--warning: cannot remove finished! for book: %@, chapter: %@, error: %@", [StaticPlayer2 sharedInstance].bookID, chid, [error localizedDescription]);
        }
        [fileManager removeItemAtPath:[gss() pathForBook:[StaticPlayer2 sharedInstance].bookID andChapter:chid] error:&error];
        if (error) {
            NSLog(@"--warning: cannot remove chapter for book: %@, chapter: %@, error: %@", [StaticPlayer2 sharedInstance].bookID, chid, [error localizedDescription]);
        }
    }
}

- (IBAction)btnBuyBookClick:(UIBarButtonItem *)sender {
    
    if([gs nfInternetAvailable:nil] == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Сообщение" message:@"Интернет не доступен. Проверьте настройки." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] ;
        [alert show];
        return;
    }
    
    //BOOL started =
    [[Myshop sharedInstance] requestProductData:[StaticPlayer2 sharedInstance].bookID];
//    NSAssert1(started, @"**err: cannot start buy process: %s", __func__);
}

+(NSInteger) metaSizeForChapter:(NSString*)bid chapter:(NSString*) chid
{
    static NSInteger returnValue = 0;
    
    static NSString *prevbid = @"";
    static NSString *prevchid = @"";
    if (![bid isEqualToString:prevbid] || ![chid isEqualToString:prevchid]) { // retake metasize from xml for new chapter
        prevbid = bid;
        prevchid = chid;
    }
    else { // return last result
        return returnValue;
    }
    
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:[StaticPlayer2 sharedInstance].bookID]];
    // set meta file size
    NSArray* arr1 = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%@']/content/track[@number='%@']/file/size", [StaticPlayer2 sharedInstance].bookID, chid]];
    if ([arr1 count] != 1) {
        NSLog(@"**err: invalid meta size for book: %@, chpater: %@", [StaticPlayer2 sharedInstance].bookID, chid);
    }
    else
    {
        returnValue = [[arr1 objectAtIndex:0] intValue];
    }
    
    return returnValue;
}

+(NSInteger) actualSizeForChapter:(NSString*)bid chapter:(NSString*)chid
{
    NSInteger returnValue = 0;
    // get actual file size and set progressView.progress
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[gss() pathForBook:[StaticPlayer2 sharedInstance].bookID andChapter:chid] error:&error];
    if (nil != error)
    {
        NSLog(@"**err: chapter not found for bookid: %@ chapter: %@", [StaticPlayer2 sharedInstance].bookID, chid);
    }
    else
    {
        NSNumber *length = [fileAttributes objectForKey:NSFileSize];
        returnValue = [length intValue];
    }
//    NSLog(@"++actualSizeForChapter: %@:%@:%d", bid, chid, returnValue);
    return returnValue;
}

+(float)calcDownProgressForBook:(NSString*)bid chapter:(NSString*)chid
{
    @synchronized(self)
    {
        NSInteger metaTrackSize = [self metaSizeForChapter:bid chapter:chid];
        
        NSInteger trackSize = [self actualSizeForChapter:bid chapter:chid];
        
        float downloadProgress = (float)trackSize / (float)metaTrackSize;
//        NSLog(@"progress val: %f", downloadProgress);

        return downloadProgress;
    }
}

+(BOOL)startChapter:(NSString *)chid
{    
    if (!isBought2 && ![[StaticPlayer2 sharedInstance] isFreeFragmentBookId:[StaticPlayer2 sharedInstance].bookID chapter:chid]) { // play only free fragment
        [[StaticPlayer2 sharedInstance] showBuyActionSheet];
        return NO;
    }

    
    if (![chid isEqualToString: [sPlayer chapter]] || ![[StaticPlayer2 sharedInstance].bookID isEqualToString:sPlayer.bookId]) {
        [self checkChapter:chid];
        
        if (sPlayer) { // already playied something
            [self db_SaveTrackProgress];
        }
        
        if(progressSliderPtr2)
            progressSliderPtr2.maximumValue = [self metaLengthForChapter:chid];
        
        [sPlayer myrelease];
        sPlayer = nil;
        sPlayer = [[StreamingPlayer alloc] initPlayerWithBook:[StaticPlayer2 sharedInstance].bookID  chapter:chid];
        sPlayer.delegate = [StaticPlayer2 sharedInstance];
        [self handlePlayPause];
        
        if(progressViewPtr2)
            progressViewPtr2.progress = [self calcDownProgressForBook:[StaticPlayer2 sharedInstance].bookID chapter:chid];
    }
    // else - user come to the player at for the already playied book, so just do nothing
    
    return YES;
}

+(void)appendChapterIdentityForDownloading:(NSString*)chapterIdentity
{
    @synchronized([[StaticPlayer2 sharedInstance] downq])
    {
        [[[StaticPlayer2 sharedInstance] downq] addObject:chapterIdentity];
    }
    
    NSString* bid =  [gss() bidFromChapterIdentity:chapterIdentity];
    NSString* chid = [gss() chidFromChapterIdentity:chapterIdentity];
    
    @synchronized([[StaticPlayer2 sharedInstance] downq])
    {
        if ([[[StaticPlayer2 sharedInstance] downq] count] == 1) {
            [self startDownloadBook:bid chapter:chid];
        }
        else
         [self showAlertAtTimer:@"добавлено в очередь загрузки" delay:1];        
    }
}


+(void)startDownloadBook:(NSString*)bid chapter:(NSString*)chid
{
    if (!isBought2 && ![[StaticPlayer2 sharedInstance] isFreeFragmentBookId:[StaticPlayer2 sharedInstance].bookID chapter:chid]) { // play only free fragment
        [[StaticPlayer2 sharedInstance] showBuyActionSheet];
        return;
    }

    if (![gs nfInternetAvailable:nil])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Сообщение"
                                                        message:@"Для загрузки главы нужен интернет. Проверьте соединение."
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
        return;
    }
    
    // if not doewnloaded yet, start downloading or partial downloading
    NSString *devid = [OpenUDID value];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/v2/lrs_get_mm_file.php?bid=%@&fileid=%@&devid=%@", BookHost, bid, chid, devid ]];
    ASIHTTPRequest *req1 = [ASIHTTPRequest requestWithURL:url];
    [req1 startSynchronous];
    NSError *error;
    error = [req1 error];
    [[gs sharedInstance] handleError:error];
    NSString *response = [req1 responseString];
    [[gs sharedInstance] handleSrvError:response];
    DDXMLDocument* doc = [[DDXMLDocument  alloc] initWithXMLString:response options:0 error:&error];
    NSArray* arr = [gss() arrayForDoc:doc xpath:@"//chapter_path"];
    if (![arr count]) {
        NSLog(@"**err: chapter_path error");
        return;
    }
    
    if (currentRequest2) { // cancel previous request before starting new
        [currentRequest2 cancel];
    }
    // don't do that - crash in requestFinished due to nil in [request originalURL]
    //currentRequest = nil;
    
    currentRequest2 = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[arr objectAtIndex:0] ]];
    NSString *downloadPath = [gss() pathForBook:bid andChapter:chid ] ;
    
    // create empty file for player could start streaming
    //        if(![[NSFileManager defaultManager]  fileExistsAtPath:downloadPath])
    //            [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
    
    // The full file will be moved here if and when the request completes successfully
    [currentRequest2 setDownloadDestinationPath:downloadPath];
    
    // This file has part of the download in it already
    [currentRequest2 setTemporaryFileDownloadPath:downloadPath];
    [currentRequest2 setAllowResumeForFileDownloads:YES];
    [currentRequest2 setDelegate:[StaticPlayer2 sharedInstance]];
    [currentRequest2 setDownloadProgressDelegate:[StaticPlayer2 sharedInstance]];
    //    int alreadyDownloaded = 2354100;
    //    [request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%i-", alreadyDownloaded]];
    [currentRequest2 setMyDontRemoveFlag:true];
    [currentRequest2 setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithFormat:@"%@:%@", bid, chid ], @"chid",  nil]];
    [currentRequest2 startAsynchronous];
    [PlayerViewController2 db_InsertMybook:[NSString stringWithFormat:@"%@",bid ]];
}

+(void) handlePlayPause
{
    NSString* object = [NSString stringWithFormat:@"%@:%@", [StaticPlayer2 sharedInstance].bookID, sPlayer.chapter ];
    
    NSString* curChId;
    if(currentRequest2)
        curChId = [self chapterIdentityFromRequest:currentRequest2];
    
    if(![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBookFinished:[StaticPlayer2 sharedInstance].bookID chapter:[sPlayer chapter] ]] && ![curChId isEqualToString:object] /*do not start download of the same chapter again*/ && [gs nfInternetAvailable:nil])
    {
        
        // set downloaded object to the top of array
        @synchronized([[StaticPlayer2 sharedInstance] downq])
        {
            [[[StaticPlayer2 sharedInstance] downq] removeObject:object];
            [[[StaticPlayer2 sharedInstance] downq] insertObject:object atIndex:0];
        }
        
        
        [self startDownloadBook:[StaticPlayer2 sharedInstance].bookID chapter:sPlayer.chapter];
    }
    else if (![gs nfInternetAvailable:nil] && ![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBook:[StaticPlayer2 sharedInstance].bookID andChapter:[sPlayer chapter]]]) // no downloaded chapter, even partially and no connection
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Сообщение"
                                                        message:@"Для загрузки главы нужен интернет. Проверьте соединение."
                                                       delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
        return;
    }
    // else play full or partially downloaded chapter
    
    
    
    if (sPlayer.streamer.state == AS_INITIALIZED) {
        //[sPlayer.streamer startAtPos:500.0 withFade:NO doPlay:YES];
        if(![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBook:[StaticPlayer2 sharedInstance].bookID andChapter:[sPlayer chapter] ]])
            NeedToStartWithFistDownloadedBytes2 = true;
        else
        {
            [self startPlayer];
        }
    }
    else
        [sPlayer.streamer pause];
    
}

- (id)initWithBook:(NSString*)bid
{
    if (self = [super initWithNibName:[gs nibFor:@"PlayerView2"] bundle:nil]) {
        // custom initialization
            
        
        if (![bid isEqualToString:@"current"]) { // if @"current" - button Player clicked - use current bookID : means returning to last opened in player book
            book = [gs db_GetBookWithID:[NSString stringWithFormat:@"%@",bid]];
            [StaticPlayer2 sharedInstance].bookID = bid;
        }
        else if (sPlayer)
        {
                [StaticPlayer2 sharedInstance].bookID = sPlayer.bookId;
                book = [gs db_GetBookWithID:[NSString stringWithFormat:@"%@",[StaticPlayer2 sharedInstance].bookID]];
        }
        else{
            NSLog(@"**err: invalid bid initialized in player or something went wrong. PASSED BID: %@!", bid);
        }
        
        if (sPlayer && [[StaticPlayer2 sharedInstance].bookID isEqualToString: sPlayer.bookId]) {
            bindProgressVal2 = YES;
        }
        
        
    }
    return self;
}

//- (id)initWithMessage:(NSString *)theMessage andImage:(UIImage*) image {
//	if (self = [super initWithNibName:nil bundle:nil]) {
//		self.message = theMessage;
//		self.tabBarItem.image  = image;
//	}
//	return self;
//}


+ (void)setPassedTime:(double)passedTime leftTime:(double)leftTime
{
    if(lbTimeLeftPtr && lbTimePassedPtr)
    {
        lbTimePassedPtr.text = [NSString stringWithFormat:@"%d:%02d", (NSInteger)(passedTime / 60.0),
                             (NSInteger)(passedTime) % 60];
        lbTimeLeftPtr.text   = [NSString stringWithFormat:@"%d:%02d", (NSInteger)((leftTime) / 60.0),
                             (NSInteger)(leftTime) % 60];
    }
    // else player is hidden no need to update ui, controls pointers are invalid
}


+ (NSInteger) metaLengthForChapter:(NSString*)chid
{
    NSInteger returnValue = 0;
    // set meta track length
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:[StaticPlayer2 sharedInstance].bookID]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%@']/content/track[@number='%@']/file/length", [StaticPlayer2 sharedInstance].bookID, chid]];
    if ([arr count] != 1) {
        NSLog(@"**err: invalid length for book: %@, chpater: %@", [StaticPlayer2 sharedInstance].bookID, chid);
    }
    else
    {
        int fsz = [[arr objectAtIndex:0] intValue];
        returnValue = fsz;
    }
    
    return returnValue;
}

- (void) showInfo
{
    InfoViewController* secondaryCtrl1 = [[InfoViewController alloc]
                                          initWithNibName:nil
                                          bundle:nil];
    UINavigationController *secondaryNavigationCtrl = [[UINavigationController alloc]
                                                       initWithRootViewController:secondaryCtrl1];
    secondaryNavigationCtrl.navigationBar.translucent = NO;
    [self presentModalViewController:secondaryNavigationCtrl animated:YES];
}

-(void)goBack:(UIButton*)sender
{
    [gss().navigationController popViewControllerAnimated:YES];
}

- (void) viewDidLoad
{
    // must be before [super viewDidLoad]
    [StaticPlayer2 sharedInstance]. shouldShowPlayerButton = NO;

    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    
    PlayerViewController2Ptr = self;
    PlayerViewController2Ptr.view.tag = TAG_PLAYER_VIEW;
    
//    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@""
//                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(restoreCompletedTransactions)];
//    
//    self.navigationItem.rightBarButtonItem = rightButton;
    
//    UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
//    [infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];
//    self.navigationItem.rightBarButtonItem =[[UIBarButtonItem alloc] initWithCustomView:infoButton];
    
    NSString* s = [book.authors objectAtIndex:0];
    [labelAuthorName setText:s];

    [labelBookTitle setText:book.title];
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightViewController];
    
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                       target:nil action:nil];
    negativeSpacer.width = -5;
    // Note: We use 5 above b/c that's how many pixels of padding iOS seems to add
    
    // Add the two buttons together on the left:
    self.navigationItem.rightBarButtonItems = [NSArray
                                              arrayWithObjects:rightButtonItem, negativeSpacer, nil];
    
    UIButton *btnBack = [UIButton buttonWithType:UIButtonTypeCustom];
    btnBack.frame = CGRectMake(0, 0, 66, 22);
    btnBack.tag=1;
    [btnBack setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btnBack setTitle:@"Назад" forState:UIControlStateNormal];
    [btnBack.titleLabel setFont:[UIFont systemFontOfSize:16]];
//    [btnBack setBackgroundImage:[UIImage imageNamed:@"btn_back"] forState:UIControlStateNormal];
    [btnBack addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    
    if (gss().system < 7.0) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:btnBack];
    }


    
    // init controls
    lbTimePassedPtr = lbTimePassed;
    lbTimeLeftPtr = lbTimeLeft;
    progressSliderPtr2 = progressSlider;
    progressViewPtr2 = progressView;
    chaptersControllerPtr2 = chaptersController;
    btnPlayPtr2 = btnPlay;
    btnBuyPtr2 = btnBuy;
    toolbarPlayerPtr2 = toolbarPlayer;

    [StaticPlayer2 checkBuyBook];

    
    //    [labelHeader setText:book.title];
    //    [labelSmallHeader setText:book.title];
//    self.title = book.title;
    self.trackedViewName = book.title;
    
    // TODO: doesn't work
    // self.navigationItem.backBarButtonItem.title = @"в каталог";
    
    // get free track meta
    if (sPlayer && progressSliderPtr2) {
        progressSliderPtr2.maximumValue = [PlayerViewController2 metaLengthForChapter:sPlayer.chapter];
    }
    
    chaptersTableView.delegate = chaptersController;
    chaptersTableView.dataSource = chaptersController;
    if (sPlayer && [sPlayer.bookId isEqualToString: [StaticPlayer2 sharedInstance].bookID]) {
        [chaptersController scrollToLastSelection];
    }
    //[chaptersTableView reloadData];
    
    // display in a view
}

//- (void)loadView {
//	CGRect	rectFrame = [UIScreen mainScreen].applicationFrame;
//	CDBUIView *theView   = [[CDBUIView alloc] initWithFrame:rectFrame];
//	theView.backgroundColor = [UIColor whiteColor];
//	theView.myController = self;
//	theView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
//	self.view = theView;
//}
+(int)getPossibleProgressVal
{
    int actual = [self actualSizeForChapter:sPlayer.bookId chapter:sPlayer.chapter];
    int meta = [self metaSizeForChapter:sPlayer.bookId chapter:sPlayer.chapter];
    float procSize = ((float)actual / (float)meta) * 100;
    int length = [self metaLengthForChapter:sPlayer.chapter];
    int val = (procSize / 100) * length;
    return val;
}

- (IBAction)onSliderUpInside:(UISlider *)sender {
    // progressSliderValue
    // 34:60×100≈56.6%
    
    if (sPlayer) {
        // preserve setting slider beyond downloaded part of audio file
        int val = [PlayerViewController2 getPossibleProgressVal];
        if (progressSlider.value < val) {
            [sPlayer.streamer startAtPos:progressSlider.value withFade:NO doPlay:YES];
        }
        else
        {
            progressSlider.value = val;
            [sPlayer.streamer startAtPos:progressSlider.value withFade:NO doPlay:YES];
        }
    }
}

- (IBAction)btnOpenDownloadQueueClick:(UIBarButtonItem *)sender {
    [StaticPlayer2 sharedInstance]. shouldShowPlayerButton = NO;

    
    DownloadsViewController *dController = [[DownloadsViewController alloc] initWithStyle:UITableViewStylePlain andDelegate:[StaticPlayer2 sharedInstance ]];
    [[gs sharedInstance].navigationController pushViewController:dController animated:YES];
//    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:dController];
//    
//    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//    [self presentModalViewController:navController animated:YES];
    //[[gs sharedInstance].navigationController presentModalViewController:dController animated:YES];
}

- (IBAction)onSliderDown:(UISlider *)sender {
    if (sPlayer)
        [sPlayer.streamer doVolumeFadeOut];
    
    bindProgressVal2 = NO;
}

- (IBAction)btnPlayStopClick:(UIBarButtonItem *)sender {
    
    if (!sPlayer || sPlayer.bookId != [StaticPlayer2 sharedInstance].bookID) {
        [chaptersController first]; // will start first chapter
    }
    else
    {
        [PlayerViewController2 db_SaveTrackProgress];
        [PlayerViewController2 handlePlayPause];
    }
}

+(void)setDelegates:(id)obj
{
    if (currentRequest2) {
        [currentRequest2 setDownloadProgressDelegate:obj];
        [currentRequest2 setDelegate:obj];
    }
    
    if (sPlayer) {
        [sPlayer setDelegate:obj];
        if (sPlayer.streamer.isPlaying && btnPlayPtr2) {
            [btnPlayPtr2 setImage:[UIImage imageNamed:@"player_button_pause.png"]];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    //[gss().playerButton setHidden:YES];
    
    [super viewWillAppear:animated];
    
    if (sPlayer) {
        if ([sPlayer.bookId isEqualToString: [StaticPlayer2 sharedInstance].bookID]) {
            [PlayerViewController2 setDelegates:[StaticPlayer2 sharedInstance]];
            if(progressViewPtr2)
                progressViewPtr2.progress = [PlayerViewController2 calcDownProgressForBook:[StaticPlayer2 sharedInstance].bookID chapter:sPlayer.chapter];
        }
        else{
            Book *b = [gs db_GetBookWithID:[NSString stringWithFormat:@"%@", sPlayer.bookId ]];
            [PlayerViewController2 showAlertAtTimer:[NSString stringWithFormat:@"вы слушаете %@", b.title] delay:1.0];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [PlayerViewController2 db_SaveTrackProgress];
    [PlayerViewController2 setDelegates:[StaticPlayer2 sharedInstance]];
    
//    if (sPlayer && shouldShowPlayerButton) {
//        [gss().playerButton setHidden:NO];
//    }
    [StaticPlayer2 sharedInstance]. shouldShowPlayerButton = YES; // set it to initial state

    // TODO: what do I need that for ? if uncomment below lines - app locks upon exiting from player. And other ui errors occure.
//    lbTimePassedPtr = nil;
//    lbTimeLeftPtr = nil;
//    progressSliderPtr = nil;
//    progressViewPtr = nil;
//    chaptersControllerPtr = nil;
//    btnPlayPtr = nil;
//    btnBuyPtr = nil;
//    toolbarPlayerPtr = nil;
}

- (void)viewDidUnload {
    toolbarPlayer = nil;
    [super viewDidUnload];
}

- (NSString*)firstChapter
{
    // create xml from string
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:[StaticPlayer2 sharedInstance].bookID]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%@']/content/track[1]/@number", [StaticPlayer2 sharedInstance].bookID]];
    if ([arr count] != 1) {
        NSLog(@"**err: invalid tracks array");
        return nil;
    }
    NSString* chid = [arr objectAtIndex:0];
    return chid;
}

+ (void) showAlertAtTimer:(NSString*)msg delay:(int)delayInSeconds
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Информация"
                                                        message:msg
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil];
    //[alertView show];
    [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        [alertView dismissWithClickedButtonIndex:-1 animated:YES];
    });
    alertView = nil;
}

@end
