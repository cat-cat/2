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

@implementation PlayerFreeViewController
@synthesize bookId;


-(void) setPlayButton:(int)play
{
    if (play)
        [btnPlay setImage:[UIImage imageNamed:@"player_button_pause.png"]];
    else
        [btnPlay setImage:[UIImage imageNamed:@"player_button_play.png"]];
}

- (void) streamingPlayerIsWaiting:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player IsWaiting");
}
- (void) streamingPlayerDidStartPlaying:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player DidStartPlaying");
}
- (void) streamingPlayerDidStopPlaying:(StreamingPlayer *) anPlayer {
    NSLog(@"++ player DidStopPlaying");
}

- (void) streamingPlayer:(StreamingPlayer *) anPlayer didUpdateProgress:(double) anProgress {
    
    if (bindProgressVal) {
        progressSlider.value = anProgress;
        float passedTime = anProgress;
        float leftTime   = progressSlider.maximumValue - anProgress;
        [self setPassedTime:passedTime leftTime:leftTime];
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

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"requestFailed:(ASIHTTPRequest *)request");
    NSLog(@" error description%@", [request.error description]);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"++Finished request !");
    NSString *path = [gss() pathForBookFinished:book.abookId chapter:[sPlayer chapter]];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    bool fileCreationSuccess = [ fm createFileAtPath:path contents:nil  attributes:nil];
    if(fileCreationSuccess == NO){ NSLog(@"Failed to create the finished! file"); }
}

-(void)startPlayer
{
    float stps = [self getTrackProgress];
    if (stps == 0) {
        [sPlayer.streamer start];
    }
    else
    {
        [sPlayer.streamer startAtPos:stps withFade:NO doPlay:YES];
    }
}

bool NeedToStartWithFistDownloadedBytes = false;
- (void) request:(ASIHTTPRequest *)request didReceiveBytes:(unsigned long long) bytes
{
//    NSLog(@"++bytes received: %lld", bytes);
    trackLength += bytes;        
    progressView.progress = (float)trackLength/(float)trackSize;

    
    if (NeedToStartWithFistDownloadedBytes)
    {
        NeedToStartWithFistDownloadedBytes = false;
        if (sPlayer.streamer.state == AS_INITIALIZED) {
            [self startPlayer];
        }
        else
            NSLog(@"**err: player is not initialized");
    }

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

- (IBAction)btnPressFF:(UIBarButtonItem *)sender {
}

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

-(void)saveTrackProgress
{
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
        
        NSLog(@"Progress : %lf", progressSlider.value);
        sqlite3_bind_double(compiledStatement, 15, progressSlider.value);
        
        sqlite3_bind_int(compiledStatement, 16, 0);
        
    returnCode = sqlite3_step(compiledStatement);
    [gs assertNoError:returnCode==SQLITE_DONE withMsg:[NSString stringWithFormat:@"**dberr %s: cannot step  %s", __func__, sqlite3_errmsg(db) ]];
        
        returnCode = sqlite3_finalize(compiledStatement);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot finalize : %s", __func__, sqlite3_errmsg(db) ]];
    returnCode = sqlite3_close(db);
    [gs assertNoError:returnCode==SQLITE_OK withMsg:[NSString stringWithFormat:@"**dberr %s: cannot close db : %s", __func__, sqlite3_errmsg(db) ]];
}

-(float)getTrackProgress
{
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

-(void)startChapter:(NSString *)chid
{
    if (chid != [sPlayer chapter]) {
        if (sPlayer) { // already playied something
            [self saveTrackProgress];
        }
        
        [sPlayer myrelease];
        sPlayer = [[StreamingPlayer alloc] initPlayerWithBook:bookId  chapter:chid];
        sPlayer.delegate = self;
        [self handlePlayPause];
        
        // set meta track length
        DDXMLDocument *xmldoc = [gss() docForFile:[gss() pathForBookMeta:bookId]];
        NSArray* arr = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%d']/content/track[@number='%@']/file/length", bookId, chid]];
        if ([arr count] != 1) {
            NSLog(@"**err: invalid length for book: %d, chpater: %@", bookId, chid);
            progressSlider.maximumValue = 0;
        }
        else
        {
            int fsz = [[arr objectAtIndex:0] intValue];
            progressSlider.maximumValue = fsz;
        }
        
        // set meta file size
        NSArray* arr1 = [gss() arrayForDoc:xmldoc xpath:[NSString stringWithFormat:@"//abook[@id='%d']/content/track[@number='%@']/file/size", bookId, chid]];
        if ([arr1 count] != 1) {
            NSLog(@"**err: invalid meta size for book: %d, chpater: %@", bookId, chid);
            trackSize = 0;
        }
        else
        {
            //int fsz = [[arr1 objectAtIndex:0] intValue];
            trackSize = [[arr1 objectAtIndex:0] intValue];
        }
        
        // get actual file size and set progressView.progress
        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[gss() pathForBook:bookId andChapter:chid] error:&error];
        trackLength = 0;
        progressView.progress = 0.0;
        if (nil != error)
        {
            NSLog(@"**err: chapter not found for bookid: %d chapter: %@", bookId, chid);
            [fileManager removeItemAtPath:[gss() pathForBookFinished:bookId chapter:chid] error:&error];
            if (error) {
                NSLog(@"**err: cannot remove finished! for book: %d, chapter: %@, error: %@", bookId, chid, [error localizedDescription]);
            }
        }
        else
        {
            NSNumber *length = [fileAttributes objectForKey:NSFileSize];
            trackLength = [length intValue];
            // TODO: unreliable logic
            if (trackLength < 320) { // http 416 file range is not satisfiable (approx text 314 bytes)
                trackLength = 0; // will cause to delete finished! in the next if
                [fileManager removeItemAtPath:[gss() pathForBook:bookId andChapter:chid] error:&error];
                if (error) {
                    NSLog(@"**err: cannot remove chapter for book: %d, chapter: %@, error: %@", bookId, chid, [error localizedDescription]);
                }
            }
            float downloadProgress = (float)trackLength / (float)trackSize;
            
            // ASIHttpRequest somtimest fihishes for incomplete downloads
            if([fileManager fileExistsAtPath:[gss() pathForBookFinished:bookId chapter:chid]] && downloadProgress < 1.0)
            {
                [fileManager removeItemAtPath:[gss() pathForBookFinished:bookId chapter:chid] error:&error];
                if (error) {
                    NSLog(@"**err: cannot remove finished! for book: %d, chapter: %@, error: %@", bookId, chid, [error localizedDescription]);
                }
            }

            progressView.progress = downloadProgress;
        }
    }
}

-(void) handlePlayPause
{
    if(![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBookFinished:book.abookId chapter:[sPlayer chapter] ]])
    {
        // if not doewnloaded yet, start downloading or partial downloading
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/chapter.php?bid=%d&ch=%@", AppConnectionHost, book.abookId, sPlayer.chapter ]];
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
        
        currentRequest = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[arr objectAtIndex:0] ]];
        NSString *downloadPath = [gss() pathForBook:book.abookId andChapter:[sPlayer chapter] ] ;
        
        // create empty file for player could start streaming
        //        if(![[NSFileManager defaultManager]  fileExistsAtPath:downloadPath])
        //            [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
        
        // The full file will be moved here if and when the request completes successfully
        [currentRequest setDownloadDestinationPath:downloadPath];
        
        // This file has part of the download in it already
        [currentRequest setTemporaryFileDownloadPath:downloadPath];
        [currentRequest setAllowResumeForFileDownloads:YES];
        [currentRequest setDelegate:self];
        [currentRequest setDownloadProgressDelegate:self];
        //    int alreadyDownloaded = 2354100;
        //    [request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%i-", alreadyDownloaded]];
        [currentRequest setMyDontRemoveFlag:true];
        [currentRequest startAsynchronous];
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


- (void)setPassedTime:(double)passedTime leftTime:(double)leftTime
{
	lbTimePassed.text = [NSString stringWithFormat:@"%d:%02d", (NSInteger)(passedTime / 60.0),
                              (NSInteger)(passedTime) % 60];
	lbTimeLeft.text   = [NSString stringWithFormat:@"%d:%02d", (NSInteger)((leftTime) / 60.0),
                              (NSInteger)(leftTime) % 60];
}


- (void) getAndDisplayFreeTrackMeta
{
    // TODO: read data from local bookMeta.xml
    
    // request to server
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/getAbookFreePart.php?bid=%d", AppConnectionHost, book.abookId ]];
    ASIHTTPRequest *req = [ASIHTTPRequest requestWithURL:url];
    [req startSynchronous];
    NSError *error = [req error];
    [[gs sharedInstance] handleError:error];
    NSString *response;
    if (!error) {
        response = [req responseString];
    }
    
    // xml doc and it's handling
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:response options:0 error:&error];
    
    [[gs sharedInstance] handleError:error];
    NSArray *nds = [doc nodesForXPath:@"//file_length" error:&error];
    [[gs sharedInstance] handleError:error];
    if (![nds count]) {
        NSLog(@"**err: file_length is empty or error");
    }
    else{
        progressSlider.minimumValue = 0.0f;
        NSString *v = [[nds objectAtIndex:0] stringValue];
        // TODO: set duration value in seconds.miliseconds format
        progressSlider.maximumValue = [v doubleValue];
    }
}

- (void) viewDidLoad
{    
//    [labelHeader setText:book.title];
//    [labelSmallHeader setText:book.title];
        self.title = book.title;
    
        // TODO: doesn't work
        // self.navigationItem.backBarButtonItem.title = @"в каталог";

    // get free track meta
    [self getAndDisplayFreeTrackMeta];
    chaptersTableView.delegate = chaptersController;
    chaptersTableView.dataSource = chaptersController;
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
- (IBAction)onSliderUpInside:(UISlider *)sender {
    [sPlayer.streamer startAtPos:progressSlider.value withFade:NO doPlay:YES];
    bindProgressVal = YES;
}

- (IBAction)onSliderDown:(UISlider *)sender {
    bindProgressVal = NO;
}

- (IBAction)btnPlayStopClick:(UIBarButtonItem *)sender {
    
    if (!sPlayer) {
        NSString* cid = [self firstChapter];
        if (cid) {
            [self startChapter:cid];
        }
        else
            // TODO: add error to user
            NSLog(@"**err: no first chapter for book: %d", bookId);
    }
    else
        [self handlePlayPause];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [sPlayer setDelegate:nil];
   // progressSlider = nil;
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
@end
