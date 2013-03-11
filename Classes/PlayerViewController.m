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

#import "PlayerViewController.h"
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

MBProgressHUD *HUD = nil;
PlayerViewController* PlayerFreeViewControllerPtr = nil;
static ASIHTTPRequest* currentRequest;
BOOL isBought = NO;
//static int bookId;
NSInteger trackLength = 0, trackSize = 0;
bool NeedToStartWithFistDownloadedBytes = false;
static BOOL bindProgressVal;
ChaptersViewController *chaptersControllerPtr;
UIProgressView *progressViewPtr;
UISlider *progressSliderPtr;
UIBarButtonItem *btnPlayPtr;

@implementation StaticPlayer
enum BuyButtons {BB_BUY, BB_GETFREE, BB_CANCEL};

+(BOOL)checkBuyBook
{    
    NSError* error;
    NSString* buy = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:[gss() pathForBuy:[StaticPlayer sharedInstance].bookID] ] encoding:NSUTF8StringEncoding error:&error];
    [gss() handleError:error];
    if (buy && [buy rangeOfString:@"yes"].location != NSNotFound) {
        isBought = YES;
    }
    else
    {
        isBought = NO;
    }
    
    return isBought;
}

+(void) deleteBook:(NSString*)bid
{
    @synchronized([[StaticPlayer sharedInstance] downq])
    {
        NSMutableArray* downq = [[StaticPlayer sharedInstance] downq];
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
    
    if (currentRequest && [[PlayerViewController chapterIdentityFromRequest:currentRequest] hasPrefix:bid]) {
        [currentRequest cancel];
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
    isBought = YES;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Покупка книги"
                                                    message:@"Книга куплена, поздравляем!"
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void) removeDownqObject:(NSString *)object
{
    NSString* strURL = [PlayerViewController chapterIdentityFromRequest:currentRequest];

    if ([strURL isEqualToString:object]) {
        [currentRequest cancel]; // will remove request from downq in onRequestFailed
    }
    else
    {
        @synchronized(self.downq)
        {
            [self.downq removeObject:object];
        }
    }
}

-(void) setPlayButton:(int)play
{
    if (play)
        [btnPlayPtr setImage:[UIImage imageNamed:@"player_button_pause.png"]];
    else
        [btnPlayPtr setImage:[UIImage imageNamed:@"player_button_play.png"]];
}

-(void)showHUD
{
    if (!HUD) {
        // The hud will dispable all input on the view (use the higest view possible in the view hierarchy)
        HUD = [MBProgressHUD showHUDAddedTo:PlayerFreeViewControllerPtr.view animated:YES];
    }
    //hud.mode = MBProgressHUDModeAnnularDeterminate;
	
    //	// Regiser for HUD callbacks so we can remove it from the window at the right time
    //	HUD.delegate = self;
	
	// Show the HUD while the provided method executes in a new thread
	//[HUD showWhileExecuting:@selector(myTask) onTarget:self withObject:nil animated:YES];    
}

-(void)hideHUD
{
    if (HUD) {
        [MBProgressHUD hideHUDForView:PlayerFreeViewControllerPtr.view animated:YES];
        HUD=nil;        
    }
}

- (void) streamingPlayerIsWaiting:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player IsWaiting");
    if (PlayerFreeViewControllerPtr) {
        [self showHUD];
    }
}
- (void) streamingPlayerDidStartPlaying:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player DidStartPlaying");
    if (PlayerFreeViewControllerPtr) {
        [self hideHUD];
    }
    
    [PlayerViewController db_InsertMybook:[NSString stringWithFormat:@"%@",sPlayer.bookId]];
    bindProgressVal = YES;
    [sPlayer.streamer performSelector:@selector(doVolumeFadeIn) withObject:nil afterDelay:1.0];
}

- (void) streamingPlayerDidStopPlaying:(StreamingPlayer *) anPlayer {
    // checkIf chapter dowloaded correctly
    [PlayerViewController checkChapter:sPlayer.chapter];
    
    // reinit player
    NSString* chid = sPlayer.chapter;
    NSString* bid = sPlayer.bookId;
    [sPlayer myrelease];
    if (progressSliderPtr) {
        progressSliderPtr.value = 0.0;
    }
    [PlayerViewController db_SaveTrackProgress];
    sPlayer = [[StreamingPlayer alloc] initPlayerWithBook:bid  chapter:chid];
    [sPlayer setDelegate:[StaticPlayer sharedInstance]];
    [PlayerViewController setDelegates:[StaticPlayer sharedInstance]];
    bindProgressVal = YES;
    
    if (PlayerFreeViewControllerPtr) {
        [self hideHUD];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"++alertView button clicked at index %d", buttonIndex);
    if (buttonIndex == 1) { // yes
        [[Myshop sharedInstance] startWithBook:[StaticPlayer sharedInstance].bookID isfree:YES];
    }
}

BOOL shouldShowPlayerButton = YES;
BOOL buyQueryStarted = NO;
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSLog(@"++actionsheet item clicked at index %d", buttonIndex);
    buyQueryStarted = NO;
    switch (buttonIndex) {
        case BB_GETFREE:
        {
            // TODO: check inet, then loading screen
            NSString *devid = [[UIDevice currentDevice] uniqueIdentifier];
            NSArray *arr = [gs srvArrForUrl:[NSString stringWithFormat:@"http://%@/free1checkcode.php?dev=%@", BookHost, devid] xpath:@"//freeflag" message:[NSString stringWithFormat:@"unable to get freeflag: %s", __func__ ]];
            int freeflag = [[arr objectAtIndex:0] intValue];

            switch (freeflag) {
                case 1: // can use free book
                    // you'we got free book
                {
                Book* b = [gs db_GetBookWithID:[NSString stringWithFormat:@"%@",[StaticPlayer sharedInstance].bookID ]];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Получение бесплатной книги"
                                                                message:[NSString stringWithFormat:@"Хотите получить бесплатно книгу %@?", b.title] delegate:self cancelButtonTitle:@"Нет" otherButtonTitles:@"Да", nil];
                [alert show];
                    break;
                }
                case 0: // should register email and promocode first
                {
                    shouldShowPlayerButton = NO;
                    Free1ViewController* vc = [[Free1ViewController alloc] init];
                    [[gss() navigationController] pushViewController:vc animated:YES];
                    break;
                }
                case 2: // already used
                {
                    [PlayerViewController showAlertAtTimer:@"Бесплатная книга уже получена" delay:1];
                    break;
                }
                    
                default:
                    break;
            }
            
            break;
        }
        case BB_BUY:
        {
            [[Myshop sharedInstance] requestProductData:[StaticPlayer sharedInstance].bookID];
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

- (void) streamingPlayer:(StreamingPlayer *) anPlayer didUpdateProgress:(double) anProgress {

//    if (buyQueryStarted) {
//        return;
//    }
    
    if (!isBought && [[StaticPlayer sharedInstance].bookID isEqualToString: sPlayer.bookId]) {
        float actual = anProgress;
        float max = progressSliderPtr.maximumValue;
        float procSize = (actual / max) * 100;
        if (procSize > 70.0 && anProgress > 350.0 && [sPlayer.streamer isPlaying] && !buyQueryStarted) {
            buyQueryStarted = YES;
            if ([sPlayer.streamer isPlaying]) {
                [sPlayer.streamer stop];   
            }
            
            // show action sheet
            UIActionSheet *
            actionSheet = [[UIActionSheet alloc]
                           initWithTitle:@"Ограничение прослушивания книги" delegate:self cancelButtonTitle:@"Отмена" destructiveButtonTitle:@"Купить" otherButtonTitles: @"Получить бесплатно", nil];
            [actionSheet showInView:PlayerFreeViewControllerPtr.view];
        }
//        int length = [self metaLengthForChapter:sPlayer.chapter];
//        int val = (procSize / 100) * length;
//        return val;

    }
    
    if (bindProgressVal && progressSliderPtr && ([[StaticPlayer sharedInstance].bookID isEqualToString: sPlayer.bookId])) {
        progressSliderPtr.value = anProgress;
        float passedTime = anProgress;
        float leftTime   = progressSliderPtr.maximumValue - anProgress;
        [PlayerViewController setPassedTime:passedTime leftTime:leftTime];
        //NSLog(@"++ player DidUpdateProgress: %f", anProgress);
    }
}


- (void)request:(ASIHTTPRequest *)request didReceiveResponseHeaders:(NSDictionary *)responseHeaders
{
    for (id key in responseHeaders) {
        NSLog(@"key: %@, value: %@ \n", key, [responseHeaders objectForKey:key]);
    }
    // [[NSFileManager defaultManager] removeItemAtPath:currentTrack.audioFilePath error:nil];
    //if(![[NSFileManager defaultManager] fileExistsAtPath:currentTrack.audioFilePath])
}

- (void) request:(ASIHTTPRequest *)request didReceiveBytes:(unsigned long long) bytes
{
    //    NSLog(@"++bytes received: %lld", bytes);
    NSString* strURL = [PlayerViewController chapterIdentityFromRequest:request];
    NSString* bid = [gss() bidFromChapterIdentity:strURL];
    NSString* chid = [gss() chidFromChapterIdentity:strURL];
    
    float progressVal = 0.0;
    if([[StaticPlayer sharedInstance].bookID isEqualToString: bid] && [sPlayer.chapter isEqualToString:chid])
    {
        trackLength += bytes;
        progressVal = (float)trackLength/(float)trackSize;
        if (progressViewPtr) {
            progressViewPtr.progress = progressVal;
        }
        if (NeedToStartWithFistDownloadedBytes)
        {
            NeedToStartWithFistDownloadedBytes = false;
            if (sPlayer.streamer.state == AS_INITIALIZED) {
                [PlayerViewController startPlayer];
            }
            else
                NSLog(@"**err: player is not initialized");
        }
    }
    else
    {
        int sz = [PlayerViewController actualSizeForChapter:bid chapter:chid];
        int lnt = [PlayerViewController metaSizeForChapter:bid chapter:chid];
        progressVal = (float)sz/(float)lnt;
    }
    
    if(chaptersControllerPtr)
        [chaptersControllerPtr updateProgressForChapterIdentity:[PlayerViewController chapterIdentityFromRequest: request ] value:progressVal];
    
    
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
    NSString* strURL = [PlayerViewController chapterIdentityFromRequest:request];
    NSString* bid = [gss() bidFromChapterIdentity:strURL];
    NSString* chid = [gss() chidFromChapterIdentity:strURL];
    NSString *path = [gss() pathForBookFinished:bid chapter:chid];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    bool fileCreationSuccess = [ fm createFileAtPath:path contents:nil  attributes:nil];
    if(fileCreationSuccess == NO){ NSLog(@"Failed to create the finished! file"); }
    
    // set up requests queue
    [PlayerViewController downqNextAfter:request];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"**err: request failed description %@, url: %@", [request.error description], [request url]);
    //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // set up requests queue
    [PlayerViewController downqNextAfter:request];
}



+ (StaticPlayer *)sharedInstance
{
    static StaticPlayer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[StaticPlayer alloc] init];
        // Do any other initialisation stuff here
        [sharedInstance setDownq:[[NSMutableArray alloc] init] ];

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


@implementation PlayerViewController
static UILabel *lbTimePassedPtr;
static UILabel *lbTimeLeftPtr;
static Book *book;

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
    @synchronized([[StaticPlayer sharedInstance] downq])
    {
        [[[StaticPlayer sharedInstance] downq] removeObject:object];
    }
    
    if (chaptersControllerPtr) {
        [chaptersControllerPtr chapterFinishDownload:object];
    }
    
    @synchronized([[StaticPlayer sharedInstance] downq])
    {
        for (NSString* item in [[StaticPlayer sharedInstance] downq]) {
            NSString* curChId = [self chapterIdentityFromRequest:currentRequest];
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
    
    sqlite3_bind_text(compiledStatement, 1, [[NSString stringWithFormat:@"%@",[StaticPlayer sharedInstance].bookID] UTF8String], -1, SQLITE_TRANSIENT);
    
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
    
    if (!sPlayer || ![sPlayer.chapter length] || ![sPlayer.bookId isEqualToString: [StaticPlayer sharedInstance].bookID]) {
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
    
    sqlite3_bind_text(compiledStatement, 1, [[StaticPlayer sharedInstance].bookID UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(compiledStatement, 2, [sPlayer.chapter UTF8String], -1, SQLITE_TRANSIENT);
    
    if(progressSliderPtr)
    {
        float testVal = progressSliderPtr.value - 8.0;
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
    if (!sPlayer || ![sPlayer.chapter length] || ![sPlayer.bookId isEqualToString: [StaticPlayer sharedInstance].bookID]) {
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
    bool finished_exists = [fileManager fileExistsAtPath:[gss() pathForBookFinished:[StaticPlayer sharedInstance].bookID chapter:chid]];
    NSInteger actualSize = [self actualSizeForChapter:[StaticPlayer sharedInstance].bookID chapter:chid];
    NSInteger metaSize = [self metaSizeForChapter:[StaticPlayer sharedInstance].bookID chapter:chid];
    
    if((finished_exists && actualSize<metaSize) || (!finished_exists && actualSize<400))
    {
        NSError *error;
        [fileManager removeItemAtPath:[gss() pathForBookFinished:[StaticPlayer sharedInstance].bookID chapter:chid] error:&error];
        if (error) {
            NSLog(@"--warning: cannot remove finished! for book: %@, chapter: %@, error: %@", [StaticPlayer sharedInstance].bookID, chid, [error localizedDescription]);
        }
        [fileManager removeItemAtPath:[gss() pathForBook:[StaticPlayer sharedInstance].bookID andChapter:chid] error:&error];
        if (error) {
            NSLog(@"--warning: cannot remove chapter for book: %@, chapter: %@, error: %@", [StaticPlayer sharedInstance].bookID, chid, [error localizedDescription]);
        }
    }
}

- (IBAction)btnBuyBookClick:(UIBarButtonItem *)sender {
    //BOOL started =
    [[Myshop sharedInstance] requestProductData:[StaticPlayer sharedInstance].bookID];
//    NSAssert1(started, @"**err: cannot start buy process: %s", __func__);
}

+(NSInteger) metaSizeForChapter:(NSString*)bid chapter:(NSString*) chid
{
    NSInteger returnValue = 0;
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:[StaticPlayer sharedInstance].bookID]];
    // set meta file size
    NSArray* arr1 = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%@']/content/track[@number='%@']/file/size", [StaticPlayer sharedInstance].bookID, chid]];
    if ([arr1 count] != 1) {
        NSLog(@"**err: invalid meta size for book: %@, chpater: %@", [StaticPlayer sharedInstance].bookID, chid);
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
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[gss() pathForBook:[StaticPlayer sharedInstance].bookID andChapter:chid] error:&error];
    if (nil != error)
    {
        NSLog(@"**err: chapter not found for bookid: %@ chapter: %@", [StaticPlayer sharedInstance].bookID, chid);
    }
    else
    {
        NSNumber *length = [fileAttributes objectForKey:NSFileSize];
        returnValue = [length intValue];
    }
    return returnValue;
}

+(float)calcDownProgressForBook:(NSString*)bid chapter:(NSString*)chid
{
    @synchronized(self)
    {
        trackSize = [self metaSizeForChapter:bid chapter:chid];
        
        trackLength = [self actualSizeForChapter:bid chapter:chid];
        
        float downloadProgress = (float)trackLength / (float)trackSize;
        
        return downloadProgress;
    }
}

+(void)startChapter:(NSString *)chid
{
    if (![chid isEqualToString: [sPlayer chapter]] || ![[StaticPlayer sharedInstance].bookID isEqualToString:sPlayer.bookId]) {
        [self checkChapter:chid];
        
        if (sPlayer) { // already playied something
            [self db_SaveTrackProgress];
        }
        
        if(progressSliderPtr)
            progressSliderPtr.maximumValue = [self metaLengthForChapter:chid];
        
        [sPlayer myrelease];
        sPlayer = [[StreamingPlayer alloc] initPlayerWithBook:[StaticPlayer sharedInstance].bookID  chapter:chid];
        sPlayer.delegate = [StaticPlayer sharedInstance];
        [self handlePlayPause];
        
        if(progressViewPtr)
            progressViewPtr.progress = [self calcDownProgressForBook:[StaticPlayer sharedInstance].bookID chapter:chid];
    }
    // else - user come to the player at for the already playied book, so just do nothing
}

+(void)appendChapterIdentityForDownloading:(NSString*)chapterIdentity
{
    @synchronized([[StaticPlayer sharedInstance] downq])
    {
        [[[StaticPlayer sharedInstance] downq] addObject:chapterIdentity];
    }
    
    NSString* bid =  [gss() bidFromChapterIdentity:chapterIdentity];
    NSString* chid = [gss() chidFromChapterIdentity:chapterIdentity];
    
    @synchronized([[StaticPlayer sharedInstance] downq])
    {
        if ([[[StaticPlayer sharedInstance] downq] count] == 1) {
            [self startDownloadBook:bid chapter:chid];
        }
    }
}


+(void)startDownloadBook:(NSString*)bid chapter:(NSString*)chid
{
    if (![gs nfInternetAvailable:nil])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Сообщение"
                                                        message:@"Для загрузки главы нужен интернет. Проверьте соединение."
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
        return;
    }
    
    // if not doewnloaded yet, start downloading or partial downloading
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/chapter.php?bid=%@&ch=%@", BookHost, bid, chid ]];
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
        NSLog(@"**err: chapter_path eror");
        return;
    }
    
    if (currentRequest) { // cancel previous request before starting new
        [currentRequest cancel];
    }
    // don't do that - crash in requestFinished due to nil in [request originalURL]
    //currentRequest = nil;
    
    currentRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[arr objectAtIndex:0] ]];
    NSString *downloadPath = [gss() pathForBook:bid andChapter:chid ] ;
    
    // create empty file for player could start streaming
    //        if(![[NSFileManager defaultManager]  fileExistsAtPath:downloadPath])
    //            [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
    
    // The full file will be moved here if and when the request completes successfully
    [currentRequest setDownloadDestinationPath:downloadPath];
    
    // This file has part of the download in it already
    [currentRequest setTemporaryFileDownloadPath:downloadPath];
    [currentRequest setAllowResumeForFileDownloads:YES];
    [currentRequest setDelegate:[StaticPlayer sharedInstance]];
    [currentRequest setDownloadProgressDelegate:[StaticPlayer sharedInstance]];
    //    int alreadyDownloaded = 2354100;
    //    [request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%i-", alreadyDownloaded]];
    [currentRequest setMyDontRemoveFlag:true];
    [currentRequest setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSString stringWithFormat:@"%@:%@", bid, chid ], @"chid",  nil]];
    [currentRequest startAsynchronous];
    [PlayerViewController db_InsertMybook:[NSString stringWithFormat:@"%@",bid ]];
}

+(void) handlePlayPause
{
    NSString* object = [NSString stringWithFormat:@"%@:%@", [StaticPlayer sharedInstance].bookID, sPlayer.chapter ];
    
    NSString* curChId;
    if(currentRequest)
        curChId = [self chapterIdentityFromRequest:currentRequest];
    
    if(![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBookFinished:[StaticPlayer sharedInstance].bookID chapter:[sPlayer chapter] ]] && ![curChId isEqualToString:object] /*do not start download of the same chapter again*/ && [gs nfInternetAvailable:nil])
    {
        
        // set downloaded object to the top of array
        @synchronized([[StaticPlayer sharedInstance] downq])
        {
            [[[StaticPlayer sharedInstance] downq] removeObject:object];
            [[[StaticPlayer sharedInstance] downq] insertObject:object atIndex:0];
        }
        
        
        [self startDownloadBook:[StaticPlayer sharedInstance].bookID chapter:sPlayer.chapter];
    }
    else if (![gs nfInternetAvailable:nil] && ![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBook:[StaticPlayer sharedInstance].bookID andChapter:[sPlayer chapter]]]) // no downloaded chapter, even partially and no connection
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Сообщение"
                                                        message:@"Для загрузки главы нужен интернет. Проверьте соединение."
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        
        return;
    }
    // else play full or partially downloaded chapter
    
    
    
    if (sPlayer.streamer.state == AS_INITIALIZED) {
        //[sPlayer.streamer startAtPos:500.0 withFade:NO doPlay:YES];
        if(![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBook:[StaticPlayer sharedInstance].bookID andChapter:[sPlayer chapter] ]])
            NeedToStartWithFistDownloadedBytes = true;
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
    if (self = [super init]) {
        // custom initialization
            
        
        if ([bid intValue] > 0) { // if 0 - button Player clicked - use current bookID : means returning to last opened in player book
            trackSize = 0;
            book = [gs db_GetBookWithID:[NSString stringWithFormat:@"%@",bid]];
            [StaticPlayer sharedInstance].bookID = bid;
        }
        else if (sPlayer)
        {
                [StaticPlayer sharedInstance].bookID = sPlayer.bookId;
                book = [gs db_GetBookWithID:[NSString stringWithFormat:@"%@",[StaticPlayer sharedInstance].bookID]];
        }
        else{
            NSLog(@"**err: invalid bid initialized in player or something went wrong. PASSED BID: %@!", bid);
        }
        
        if (sPlayer && [[StaticPlayer sharedInstance].bookID isEqualToString: sPlayer.bookId]) {
            bindProgressVal = YES;
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
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:[StaticPlayer sharedInstance].bookID]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%@']/content/track[@number='%@']/file/length", [StaticPlayer sharedInstance].bookID, chid]];
    if ([arr count] != 1) {
        NSLog(@"**err: invalid length for book: %@, chpater: %@", [StaticPlayer sharedInstance].bookID, chid);
    }
    else
    {
        int fsz = [[arr objectAtIndex:0] intValue];
        returnValue = fsz;
    }
    
    return returnValue;
}

- (void) viewDidLoad
{
    
    PlayerFreeViewControllerPtr = self;

    [StaticPlayer checkBuyBook];
    
    // init controls
    lbTimePassedPtr = lbTimePassed;
    lbTimeLeftPtr = lbTimeLeft;
    progressSliderPtr = progressSlider;
    progressViewPtr = progressView;
    chaptersControllerPtr = chaptersController;
    btnPlayPtr = btnPlay;

    
    //    [labelHeader setText:book.title];
    //    [labelSmallHeader setText:book.title];
    self.title = book.title;
    
    // TODO: doesn't work
    // self.navigationItem.backBarButtonItem.title = @"в каталог";
    
    // get free track meta
    if (sPlayer && progressSliderPtr) {
        progressSliderPtr.maximumValue = [PlayerViewController metaLengthForChapter:sPlayer.chapter];
    }
    
    chaptersTableView.delegate = chaptersController;
    chaptersTableView.dataSource = chaptersController;
    if (sPlayer && [sPlayer.bookId isEqualToString: [StaticPlayer sharedInstance].bookID]) {
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
        int val = [PlayerViewController getPossibleProgressVal];
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
    shouldShowPlayerButton = NO;

    
    DownloadsViewController *dController = [[DownloadsViewController alloc] initWithStyle:UITableViewStylePlain andDelegate:[StaticPlayer sharedInstance ]];
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
    
    bindProgressVal = NO;
}

- (IBAction)btnPlayStopClick:(UIBarButtonItem *)sender {
    
    if (!sPlayer || sPlayer.bookId != [StaticPlayer sharedInstance].bookID) {
        [chaptersController first]; // will start first chapter
    }
    else
    {
        [PlayerViewController db_SaveTrackProgress];
        [PlayerViewController handlePlayPause];
    }
}

+(void)setDelegates:(id)obj
{
    if (currentRequest) {
        [currentRequest setDownloadProgressDelegate:obj];
        [currentRequest setDelegate:obj];
    }
    
    if (sPlayer) {
        [sPlayer setDelegate:obj];
        if (sPlayer.streamer.isPlaying && btnPlayPtr) {
            [btnPlayPtr setImage:[UIImage imageNamed:@"player_button_pause.png"]];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if (sPlayer) {
        if ([sPlayer.bookId isEqualToString: [StaticPlayer sharedInstance].bookID]) {
            [PlayerViewController setDelegates:[StaticPlayer sharedInstance]];
            if(progressViewPtr)
                progressViewPtr.progress = [PlayerViewController calcDownProgressForBook:[StaticPlayer sharedInstance].bookID chapter:sPlayer.chapter];
        }
        else{
            Book *b = [gs db_GetBookWithID:[NSString stringWithFormat:@"%@", sPlayer.bookId ]];
            [PlayerViewController showAlertAtTimer:[NSString stringWithFormat:@"вы слушаете %@", b.title] delay:1.0];
        }
    }
    [gss().playerButton setHidden:YES];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [PlayerViewController db_SaveTrackProgress];
    [PlayerViewController setDelegates:[StaticPlayer sharedInstance]];
    
    if (sPlayer && shouldShowPlayerButton) {
        [gss().playerButton setHidden:NO];
    }
    shouldShowPlayerButton = YES; // set it to initial state

    [super viewDidDisappear:animated];
}

- (void)viewDidUnload {
    chaptersTableView = nil;
    chaptersController = nil;
    lbTimeLeft = nil;
    lbTimePassed = nil;
    progressView = nil;

    [super viewDidUnload];
}

- (NSString*)firstChapter
{
    // create xml from string
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:[StaticPlayer sharedInstance].bookID]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%@']/content/track[1]/@number", [StaticPlayer sharedInstance].bookID]];
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
                                                       delegate:self
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
