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

bool NeedToStartWithFistDownloadedBytes = false;
- (void) request:(ASIHTTPRequest *)request didReceiveBytes:(unsigned long long) bytes
{
    NSLog(@"++bytes received: %lld", bytes);
    
    if (NeedToStartWithFistDownloadedBytes)
    {
        NeedToStartWithFistDownloadedBytes = false;
        if (sPlayer.streamer.state == AS_INITIALIZED) {
            //[sPlayer.streamer startAtPos:500.0 withFade:NO doPlay:YES];
            [sPlayer.streamer start];
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

-(void)startChapter:(NSString *)chid
{
    if (chid != [sPlayer chapter]) {
        [sPlayer myrelease];
        sPlayer = [[StreamingPlayer alloc] initPlayerWithBook:bookId  chapter:chid];
        sPlayer.delegate = self;
        [self handlePlayPauseClick];
    }
}

-(void) handlePlayPauseClick
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
        }
        
        ASIHTTPRequest* request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:[arr objectAtIndex:0] ]];
        NSString *downloadPath = [gss() pathForBook:book.abookId andChapter:[sPlayer chapter] ] ;
        
        // create empty file for player could start streaming
        //        if(![[NSFileManager defaultManager]  fileExistsAtPath:downloadPath])
        //            [[NSFileManager defaultManager] createFileAtPath:downloadPath contents:nil attributes:nil];
        
        // The full file will be moved here if and when the request completes successfully
        [request setDownloadDestinationPath:downloadPath];
        
        // This file has part of the download in it already
        [request setTemporaryFileDownloadPath:downloadPath];
        [request setAllowResumeForFileDownloads:YES];
        [request setDelegate:self];
        [request setDownloadProgressDelegate:self];
        //    int alreadyDownloaded = 2354100;
        //    [request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%i-", alreadyDownloaded]];
        [request setMyDontRemoveFlag:true];
        [request startAsynchronous];
    }
    
    
    
    if (sPlayer.streamer.state == AS_INITIALIZED) {
        //[sPlayer.streamer startAtPos:500.0 withFade:NO doPlay:YES];
        if(![[NSFileManager defaultManager]  fileExistsAtPath:[gss() pathForBook:book.abookId andChapter:[sPlayer chapter] ]])
            NeedToStartWithFistDownloadedBytes = true;
        else
        {
            [sPlayer.streamer start];
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

- (void) getAndDisplayFreeTrackMeta
{
    // TODO: read data from local bookMeta.xml
    
    // request to server
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/getAbookFreePart.php?bid=%d", AppConnectionHost, book.abookId ]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request startSynchronous];
    NSError *error = [request error];
    [[gs sharedInstance] handleError:error];
    NSString *response;
    if (!error) {
        response = [request responseString];
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
    }
    else
        [self handlePlayPauseClick];
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
