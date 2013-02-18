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

#import "PlayerFreeViewController.h"
#import "CDBUIView.h"
#import "gs.h"
#import "Book.h"
#import "ASIHTTPRequest.h"
#import "AudioStreamer.h"
#import "DDXMLDocument.h"
#import "ChaptersViewController.h"

@interface StaticPlayer : NSObject <StreamingPlayerDelegate> {
}
@end

static int bookId;
NSInteger trackLength = 0, trackSize = 0;
bool NeedToStartWithFistDownloadedBytes = false;
static BOOL bindProgressVal;
static __weak ChaptersViewController *chaptersControllerPtr;
static __weak UIProgressView *progressViewPtr;
static __weak UISlider *progressSliderPtr;

@implementation StaticPlayer

- (void) streamingPlayerIsWaiting:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player IsWaiting");
}
- (void) streamingPlayerDidStartPlaying:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player DidStartPlaying");
}
- (void) streamingPlayerDidStopPlaying:(StreamingPlayer *) anPlayer {
    // checkIf chapter dowloaded correctly
    [PlayerFreeViewController checkChapter:sPlayer.chapter];
    
    // reinit player
    NSString* chid = sPlayer.chapter;
    int bid = sPlayer.bookId;
    [sPlayer myrelease];
    if (progressSliderPtr) {
        progressSliderPtr.value = 0.0;
    }
    [PlayerFreeViewController savedbTrackProgress];
    sPlayer = [[StreamingPlayer alloc] initPlayerWithBook:bid  chapter:chid];
    [PlayerFreeViewController setDelegates:[StaticPlayer sharedInstance]];
}

- (void) streamingPlayer:(StreamingPlayer *) anPlayer didUpdateProgress:(double) anProgress {
    
    if (bindProgressVal && progressSliderPtr && (bookId==sPlayer.bookId)) {
        progressSliderPtr.value = anProgress;
        float passedTime = anProgress;
        float leftTime   = progressSliderPtr.maximumValue - anProgress;
        [PlayerFreeViewController setPassedTime:passedTime leftTime:leftTime];
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
    NSString* strURL = [PlayerFreeViewController chapterIdentityFromURL:[[request url] absoluteString]];
    int bid = [gss() bidFromChapterIdentity:strURL];
    NSString* chid = [gss() chidFromChapterIdentity:strURL];
    
    float progressVal = 0.0;
    if(bookId==bid && [sPlayer.chapter isEqualToString:chid])
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
                [PlayerFreeViewController startPlayer];
            }
            else
                NSLog(@"**err: player is not initialized");
        }
    }
    else
    {
        int sz = [PlayerFreeViewController actualSizeForChapter:bid chapter:chid];
        int lnt = [PlayerFreeViewController metaSizeForChapter:bid chapter:chid];
        progressVal = (float)sz/(float)lnt;
    }
    
    if(chaptersControllerPtr)
        [chaptersControllerPtr updateProgressForChapterIdentity:[PlayerFreeViewController chapterIdentityFromURL: [[request url] absoluteString] ] value:progressVal];
    
    
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
    NSString* strURL = [PlayerFreeViewController chapterIdentityFromURL:[[request url] absoluteString]];
    int bid = [gss() bidFromChapterIdentity:strURL];
    NSString* chid = [gss() chidFromChapterIdentity:strURL];
    NSString *path = [gss() pathForBookFinished:bid chapter:chid];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    bool fileCreationSuccess = [ fm createFileAtPath:path contents:nil  attributes:nil];
    if(fileCreationSuccess == NO){ NSLog(@"Failed to create the finished! file"); }
    
    // set up requests queue
    [PlayerFreeViewController downqNextAfter:[[request url] absoluteString]];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"**err: request failed description %@, url: %@", [request.error description], [request url]);
    //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    // set up requests queue
    [PlayerFreeViewController downqNextAfter:[[request url] absoluteString]];
}



+ (StaticPlayer *)sharedInstance
{
    static StaticPlayer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[StaticPlayer alloc] init];
        // Do any other initialisation stuff here
        
    });
    
    
    //...
    return sharedInstance;
}
@end
//******************** END StaticPlayer


@implementation PlayerFreeViewController
static __weak UILabel *lbTimePassedPtr;
static __weak UILabel *lbTimeLeftPtr;
static __weak UIBarButtonItem *btnPlayPtr;
static Book *book;
static ASIHTTPRequest* currentRequest;

-(void) setPlayButton:(int)play
{
    if (play)
        [btnPlay setImage:[UIImage imageNamed:@"player_button_pause.png"]];
    else
        [btnPlay setImage:[UIImage imageNamed:@"player_button_play.png"]];
}

+(NSString*)chapterIdentityFromURL:(NSString*)url
{
    NSString* resultString;
    
    //NSString *htmlString = @"http://192.168.0.100:80/books/3456/chaptersAudio/01_02_crypt.mp3";
    NSString *htmlString = url;
    @try {
        NSRegularExpression *nameExpression = [NSRegularExpression regularExpressionWithPattern:@"/books/(\\w+)/chaptersAudio/(\\w+)_crypt.mp3" options:NSRegularExpressionSearch error:nil];
        
        NSArray *matches = [nameExpression matchesInString:htmlString
                                                   options:0
                                                     range:NSMakeRange(0, [htmlString length])];
        for (NSTextCheckingResult *match in matches) {
            //NSRange matchRange = [match range];
            NSRange matchRange = [match rangeAtIndex:1];
            NSString *matchString1 = [htmlString substringWithRange:matchRange];
            matchRange = [match rangeAtIndex:2];
            NSString *matchString2 = [htmlString substringWithRange:matchRange];
            //NSLog(@"%@:%@", matchString1, matchString2);
            resultString = [NSString stringWithFormat:@"%@:%@", matchString1, matchString2 ];
        }
    }
    
    @catch (NSException *exception) {
        NSLog(@"**err: error getting chapter's identity for url: %@", url);
    }
    
    return resultString;
}

// called only from finished or failed requests, so we should remove it from download queue
+(void)downqNextAfter:(NSString*)completedURL
{
    NSString* object = [self chapterIdentityFromURL:completedURL];
    
    //if([[gss() downq] count] > 1)
    [[gss() downq] removeObject:object];
    
    if (chaptersControllerPtr) {
        [chaptersControllerPtr chapterFinishDownload:object];
    }
    
    for (NSString* item in [gss() downq]) {
        NSString* curChId = [self chapterIdentityFromURL:[[currentRequest url] absoluteString]];
        if ([curChId isEqualToString:item]) {
            continue;
        }
        // drop here for the only item from downq, which is not being downloaded already
        [self startDownloadBook:[gss() bidFromChapterIdentity:item] chapter:[gss() chidFromChapterIdentity:item]];
        break;
    }
}


+(void)startPlayer
{
    float stps = [self getdbTrackProgress];
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

//-(void)runOnce
//{
//    sqlite3* db;
//    int returnCode = sqlite3_open([gs dbname], &db);
//    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot open : %s", __func__, sqlite3_errmsg(db) ]];
//    returnCode = sqlite3_exec(db, "delete from t_tracks", 0, 0, 0);
//    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannnot execute : %s", __func__, sqlite3_errmsg(db) ]];
//    returnCode = sqlite3_exec(db, "create unique index idx_t_tracks on t_tracks (abook_id, track_number)", 0, 0, 0);
//    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannnot execute : %s", __func__, sqlite3_errmsg(db) ]];
//}
+(int)myGetBookId
{
    return bookId;
}

+(void)savedbTrackProgress
{
    if (!sPlayer || ![sPlayer.chapter length] || sPlayer.bookId != bookId) {
        return;
    }
    
    sqlite3* db;
    
    //    [self runOnce];
    
    // OPEN DB
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr cannot open db: %s", sqlite3_errmsg(db) ]];
    
    const char *sqlStatement = "INSERT OR REPLACE INTO t_tracks (abook_id, track_number, name, created_date, begin_time, end_time, free, in_progress, downloaded_length, size, length, bitrate, path, text_data_path, current_progress, isReachEnd) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    sqlite3_stmt *compiledStatement;
    
    returnCode = sqlite3_prepare_v2(db, sqlStatement, -1, &compiledStatement, NULL);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**err db prepare2: %s", sqlite3_errmsg(db) ]];
    
    sqlite3_bind_int(compiledStatement, 1, book.abookId);
    sqlite3_bind_text(compiledStatement, 2, [sPlayer.chapter UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(compiledStatement, 3, NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(compiledStatement, 4, NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_int(compiledStatement, 5, 0);
    sqlite3_bind_int(compiledStatement, 6, 0);
    sqlite3_bind_int(compiledStatement, 7, 0);
    sqlite3_bind_int(compiledStatement, 8, 0);
    sqlite3_bind_int(compiledStatement, 9, 0);
    sqlite3_bind_int(compiledStatement, 10, 0);
    sqlite3_bind_int(compiledStatement, 11, 0);
    sqlite3_bind_int(compiledStatement, 12, 0);
    sqlite3_bind_text(compiledStatement, 13, NULL, -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(compiledStatement, 14, NULL, -1, SQLITE_TRANSIENT);
    
    if(progressSliderPtr)
    {
        NSLog(@"Progress : %lf", progressSliderPtr.value);
        sqlite3_bind_double(compiledStatement, 15, progressSliderPtr.value);
    }
    else
    {
        sqlite3_bind_double(compiledStatement, 15, 0);
    }
    
    sqlite3_bind_int(compiledStatement, 16, 0);
    
    returnCode = sqlite3_step(compiledStatement);
    [gs assertNoError:returnCode==SQLITE_DONE withMsg:[NSString stringWithFormat:@"**dberr %s: cannot step  %s", __func__, sqlite3_errmsg(db) ]];
    
    returnCode = sqlite3_finalize(compiledStatement);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot finalize : %s", __func__, sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot close db : %s", __func__, sqlite3_errmsg(db) ]];
}

+(float)getdbTrackProgress
{
    if (!sPlayer || ![sPlayer.chapter length] || sPlayer.bookId != bookId) {
        return 0.0;
    }
    
    // assuming its not called from multiple threads, only from gui
    
    sqlite3* db;
    
    int returnCode = sqlite3_open([gs dbname], &db);
    [gs assertNoError: returnCode == SQLITE_OK withMsg:[NSString stringWithFormat:@"Unable to open db: %s", sqlite3_errmsg(db) ]];
    char *sqlStatement;
    
    sqlStatement = sqlite3_mprintf("SELECT current_progress from t_tracks where track_number='%s' AND abook_id=%d"
                                   " LIMIT 0,1", [sPlayer.chapter UTF8String], sPlayer.bookId);
    
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
    bool finished_exists = [fileManager fileExistsAtPath:[gss() pathForBookFinished:bookId chapter:chid]];
    NSInteger actualSize = [self actualSizeForChapter:bookId chapter:chid];
    NSInteger metaSize = [self metaSizeForChapter:bookId chapter:chid];
    if((finished_exists && actualSize<metaSize) || (!finished_exists && actualSize<400))
    {
        NSError *error;
        [fileManager removeItemAtPath:[gss() pathForBookFinished:bookId chapter:chid] error:&error];
        if (error) {
            NSLog(@"--warning: cannot remove finished! for book: %d, chapter: %@, error: %@", bookId, chid, [error localizedDescription]);
        }
        [fileManager removeItemAtPath:[gss() pathForBook:bookId andChapter:chid] error:&error];
        if (error) {
            NSLog(@"--warning: cannot remove chapter for book: %d, chapter: %@, error: %@", bookId, chid, [error localizedDescription]);
        }
    }
}

+(NSInteger) metaSizeForChapter:(int)bid chapter:(NSString*) chid
{
    NSInteger returnValue = 0;
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:bookId]];
    // set meta file size
    NSArray* arr1 = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%d']/content/track[@number='%@']/file/size", bookId, chid]];
    if ([arr1 count] != 1) {
        NSLog(@"**err: invalid meta size for book: %d, chpater: %@", bookId, chid);
    }
    else
    {
        returnValue = [[arr1 objectAtIndex:0] intValue];
    }
    
    return returnValue;
}

+(NSInteger) actualSizeForChapter:(int)bid chapter:(NSString*)chid
{
    NSInteger returnValue = 0;
    // get actual file size and set progressView.progress
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[gss() pathForBook:bookId andChapter:chid] error:&error];
    if (nil != error)
    {
        NSLog(@"**err: chapter not found for bookid: %d chapter: %@", bookId, chid);
    }
    else
    {
        NSNumber *length = [fileAttributes objectForKey:NSFileSize];
        returnValue = [length intValue];
    }
    return returnValue;
}

+(float)calcDownProgressForChapter:(NSString*)chid
{
    trackSize = [self metaSizeForChapter:bookId chapter:chid];
    
    trackLength = [self actualSizeForChapter:bookId chapter:chid];
    
    float downloadProgress = (float)trackLength / (float)trackSize;
    
    return downloadProgress;
}

+(void)startChapter:(NSString *)chid
{
    if (chid != [sPlayer chapter]) {
        [self checkChapter:chid];
        
        if (sPlayer) { // already playied something
            [self savedbTrackProgress];
        }
        
        if(progressSliderPtr)
            progressSliderPtr.maximumValue = [self metaLengthForChapter:chid];
        
        [sPlayer myrelease];
        sPlayer = [[StreamingPlayer alloc] initPlayerWithBook:bookId  chapter:chid];
        sPlayer.delegate = [StaticPlayer sharedInstance];
        [self handlePlayPause];
        
        if(progressViewPtr)
            progressViewPtr.progress = [self calcDownProgressForChapter:chid];
    }
    // else - user come to the player at for the already playied book, so just do nothing
}

+(void)appendChapterIdentityForDownloading:(NSString*)chapterIdentity
{
    [[gss() downq] addObject:chapterIdentity];
    int bid =  [gss() bidFromChapterIdentity:chapterIdentity];
    NSString* chid = [gss() chidFromChapterIdentity:chapterIdentity];
    
    if ([[gss() downq] count] == 1) {
        [self startDownloadBook:bid chapter:chid];
    }
}


+(void)startDownloadBook:(int)bid chapter:(NSString*)chid
{
    // if not doewnloaded yet, start downloading or partial downloading
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/chapter.php?bid=%d&ch=%@", AppConnectionHost, bid, chid ]];
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
        // TODO: message to user about not found chapter
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
    [currentRequest startAsynchronous];
}

+(void) handlePlayPause
{
    NSString* object = [NSString stringWithFormat:@"%d:%@", book.abookId, sPlayer.chapter ];
    NSString* curChId = [self chapterIdentityFromURL:[[currentRequest url] absoluteString]];
    if(![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBookFinished:book.abookId chapter:[sPlayer chapter] ]] && ![curChId isEqualToString:object])
    {
        
        // set downloaded object to the top of array
        [[gss() downq] removeObject:object];
        [[gss() downq] insertObject:object atIndex:0];
        
        
        [self startDownloadBook:book.abookId chapter:sPlayer.chapter];
    }
    
    
    
    if (sPlayer.streamer.state == AS_INITIALIZED) {
        //[sPlayer.streamer startAtPos:500.0 withFade:NO doPlay:YES];
        if(![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBook:book.abookId andChapter:[sPlayer chapter] ]])
            NeedToStartWithFistDownloadedBytes = true;
        else
        {
            [self startPlayer];
        }
    }
    else
        [sPlayer.streamer pause];
    
}

- (id)initWithBook:(int)bid
{
    if (self = [super init]) {
        // custom initialization
        if (bid > 0) {
            
            trackSize = 0;
            book = [gs db_GetBookWithID:[NSString stringWithFormat:@"%d",bid]];
            bookId = bid;
            
            //            if (sPlayer) {
            //                if (bid == [sPlayer bookId]) {
            //                    return self;
            //                }
            
            bindProgressVal = YES;
            //            }
        }
        else{
            NSLog(@"**err: invalid bid initialized in player!");
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
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:bookId]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%d']/content/track[@number='%@']/file/length", bookId, chid]];
    if ([arr count] != 1) {
        NSLog(@"**err: invalid length for book: %d, chpater: %@", bookId, chid);
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
        progressSliderPtr.maximumValue = [PlayerFreeViewController metaLengthForChapter:sPlayer.chapter];
    }
    
    chaptersTableView.delegate = chaptersController;
    chaptersTableView.dataSource = chaptersController;
    if (sPlayer && sPlayer.bookId == bookId) {
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
        int val = [PlayerFreeViewController getPossibleProgressVal];
        if (progressSlider.value < val) {
            [sPlayer.streamer startAtPos:progressSlider.value withFade:NO doPlay:YES];
        }
        else
        {
            progressSlider.value = val;
            [sPlayer.streamer startAtPos:progressSlider.value withFade:NO doPlay:YES];
        }
    }
    
    bindProgressVal = YES;
}

- (IBAction)onSliderDown:(UISlider *)sender {
    bindProgressVal = NO;
}

- (IBAction)btnPlayStopClick:(UIBarButtonItem *)sender {
    
    if (!sPlayer || sPlayer.bookId != bookId) {
        [chaptersController first]; // will start first chapter
    }
    else
    {
        [PlayerFreeViewController savedbTrackProgress];
        [PlayerFreeViewController handlePlayPause];
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
        if (sPlayer.bookId == bookId) {
            [PlayerFreeViewController setDelegates:[StaticPlayer sharedInstance]];
            if(progressViewPtr)
                progressViewPtr.progress = [PlayerFreeViewController calcDownProgressForChapter:sPlayer.chapter];
        }
        else{
            Book *b = [gs db_GetBookWithID:[NSString stringWithFormat:@"%d", sPlayer.bookId ]];
            [self showAlertAtTimer:b.title delay:2.0];
        }
    }
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [PlayerFreeViewController savedbTrackProgress];
    [PlayerFreeViewController setDelegates:[StaticPlayer sharedInstance]];
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
    DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:bookId]];
    NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%d']/content/track[1]/@number", bookId]];
    if ([arr count] != 1) {
        NSLog(@"**err: invalid tracks array");
        return nil;
    }
    NSString* chid = [arr objectAtIndex:0];
    return chid;
}

- (void) showAlertAtTimer:(NSString*)msg delay:(int)delayInSeconds
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"проигрывается"
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
