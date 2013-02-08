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
#import "GlobalSingleton.h"
#import "Book.h"
#import "ASIHTTPRequest.h"
#import "AudioStreamer.h"
#import "DDXMLDocument.h"


@implementation PlayerFreeViewController
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
    //NSLog(@"++ player DidUpdateProgress: %f", anProgress);
    
    if (bindProgresVal) {
        progressSlider.value = anProgress;        
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

- (void)requestFinished:(ASIHTTPRequest *)request
{
    
    
    NSLog(@"++Finished request !");
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSLog(@"requestFailed:(ASIHTTPRequest *)request");
    NSLog(@" error description%@", [request.error description]);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

StreamingPlayer *sPlayer = nil;

- (void) request:(ASIHTTPRequest *)request didReceiveBytes:(unsigned long long) bytes
{
    NSLog(@"++bytes received: %lld", bytes);
    
    if (sPlayer==nil)
    {
        NSURL *bookURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"tmp/m.mp3"]];
        sPlayer = [[StreamingPlayer alloc] initPlayerWithURL:bookURL];
        sPlayer.delegate = self;
        if (sPlayer.streamer.state == AS_INITIALIZED) {
            //[sPlayer.streamer startAtPos:500.0 withFade:NO doPlay:YES];
            [sPlayer.streamer start];
        }
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


- (id)initWithBook:(int)bid
{
    if (self = [super init]) {
        // custom initialization
        if (bid != -1) {
            book = [GlobalSingleton db_GetBookWithID:[NSString stringWithFormat:@"%d",bid]];
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
    // request to server
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@/getAbookFreePart.php?bid=%d", AppConnectionHost, book.abookId ]];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request startSynchronous];
    NSError *error = [request error];
    [[GlobalSingleton sharedInstance] handleError:error];
    NSString *response;
    if (!error) {
        response = [request responseString];
    }
    
    // xml doc and it's handling
    DDXMLDocument *doc = [[DDXMLDocument alloc] initWithXMLString:response options:0 error:&error];
    
    [[GlobalSingleton sharedInstance] handleError:error];
    NSArray *nds = [doc nodesForXPath:@"//file_length" error:&error];
    [[GlobalSingleton sharedInstance] handleError:error];
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
    bindProgresVal = YES;
}

- (IBAction)onSliderDown:(UISlider *)sender {
    bindProgresVal = NO;
}

- (IBAction)btnPlayStopClick:(UIBarButtonItem *)sender {
    
    
    
    NSURL *url = [NSURL URLWithString:@"http://192.168.0.100:80/m.mp3"];
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    NSString *downloadPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp/m.mp3"];
    
    // The full file will be moved here if and when the request completes successfully
    [request setDownloadDestinationPath:downloadPath];
    
    // This file has part of the download in it already
    [request setTemporaryFileDownloadPath:[NSHomeDirectory() stringByAppendingPathComponent:@"tmp/m.mp3"]];
    [request setAllowResumeForFileDownloads:YES];
    [request setDelegate:self];
    [request setDownloadProgressDelegate:self];
    //    int alreadyDownloaded = 2354100;
    //    [request addRequestHeader:@"Range" value:[NSString stringWithFormat:@"bytes=%i-", alreadyDownloaded]];
    [request setMyDontRemoveFlag:true];
    [request startAsynchronous];
    
    
    // TODO: try to start playing
    
    
    // TODO: add
    //    if (sPlayer==nil)
    //    {
    //        NSURL *bookURL = [NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:@"tmp/m.mp3"]];
    //        sPlayer = [[StreamingPlayer alloc] initPlayerWithURL:bookURL];
    //        sPlayer.delegate = self;
    //    }
    //
    //    if (sPlayer.streamer.state == AS_INITIALIZED) {
    //        //[sPlayer.streamer startAtPos:500.0 withFade:NO doPlay:YES];
    //        [sPlayer.streamer start];
    //    }
    //    else
    //        [sPlayer.streamer pause];
    //    
    //    return;
    

    
}
- (void)viewDidUnload {
    progressSlider = nil;
    [super viewDidUnload];
}
@end
