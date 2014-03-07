//
//  StreamingPlayer.m
//

#import "StreamingPlayer.h"
#import "AudioStreamer.h"
#import <QuartzCore/CoreAnimation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>
#import "gs.h"

@implementation StreamingPlayer
@synthesize bookId, chapter;
@synthesize delegate;
@synthesize streamer;
- (id)initPlayerWithBook:(NSString*)bid chapter:(NSString*)ch
{
	if ((self = [super init]))
	{
        bookId = [[NSString alloc] initWithString: bid];
        chapter = [[NSString alloc] initWithString: ch];
        NSURL* anURL = [NSURL fileURLWithPath: [[gs sharedInstance] pathForBook:bid andChapter:ch]];
		streamer = [[AudioStreamer alloc] initWithURL:anURL] ;
        NSLog(@"++stream URL: %@", anURL);
        if ([bid hasPrefix:@"lrs"]) { // litres book - no need to decore stream
            streamer.needDecode = NO;
        } else {
            streamer.needDecode = YES;
        }
		
		progressUpdateTimer =
		[NSTimer
		 scheduledTimerWithTimeInterval:0.5
		 target:self
		 selector:@selector(updateProgress:)
		 userInfo:nil
		 repeats:YES];
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(playbackStateChanged:)
		 name:ASStatusChangedNotification
		 object:self.streamer];
        
	}
	return self;    
}

//- (id)initPlayerWithURL:(NSURL*)anURL
//{
//	if ((self = [super init]))
//	{
//		streamer = [[AudioStreamer alloc] initWithURL:anURL] ;
//        NSLog(@"++stream URL: %@", anURL);
//		
//		progressUpdateTimer =
//		[NSTimer
//		 scheduledTimerWithTimeInterval:0.1
//		 target:self
//		 selector:@selector(updateProgress:)
//		 userInfo:nil
//		 repeats:YES];
//		[[NSNotificationCenter defaultCenter]
//		 addObserver:self
//		 selector:@selector(playbackStateChanged:)
//		 name:ASStatusChangedNotification
//		 object:self.streamer];
//        
//	}
//	return self;
//}
-(void)myrelease
{
	[self.streamer stop];
	//[self.streamer release];
	self.delegate = nil;
	
    [[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:ASStatusChangedNotification
	 object:streamer];
	[progressUpdateTimer invalidate];
	progressUpdateTimer = nil;
	
    [bookId release];
	[chapter release];
    
//    @try {
//        [self dealloc];
//    }
//    @catch (NSException *exception) {
//        NSLog(@"***: exception: was unable to myrelease StreamingPlayer");
//    }
}

- (void) dealloc
{    
    
	[super dealloc];
}



#pragma mark -
#pragma mark Core logic

//
// playbackStateChanged:
//
// Invoked when the AudioStreamer
// reports that its playback status has changed.
//
- (void)playbackStateChanged:(NSNotification *)aNotification
{
    // for play button
    if( delegate && [delegate respondsToSelector:@selector(setPlayButton:)] )
    {
        if ([streamer isPlaying])
        {
            //[streamer setVolume:1.0f];
			[delegate setPlayButton:1];
        }
        else
            [delegate setPlayButton:0];
    }
    
	if ([streamer isWaiting])
	{
		if( delegate && [delegate respondsToSelector:@selector(streamingPlayerIsWaiting:)] )
		{
			[delegate streamingPlayerIsWaiting: self];
		}
	}
	else if ([streamer isPlaying])
	{
		if( delegate && [delegate respondsToSelector:@selector(streamingPlayerDidStartPlaying:)] )
		{
			[delegate streamingPlayerDidStartPlaying: self];
		}
	}
	else if ([streamer isIdle])
	{
		if( delegate && [delegate respondsToSelector:@selector(streamingPlayerDidStopPlaying:)] )
		{
			[delegate streamingPlayerDidStopPlaying: self];
		}
	}
}

//
// updateProgress:
//
// Invoked when the AudioStreamer
// reports that its playback progress has changed.
//
- (void)updateProgress:(NSTimer *)updatedTimer
{
	double progress = streamer.progress;
	//NSLog(@"%@", [NSString stringWithFormat:@"Time Played: %.1f seconds", progress]);
    
	if( delegate && [delegate respondsToSelector:@selector(streamingPlayer:didUpdateProgress:)] )
	{
		[delegate streamingPlayer:self didUpdateProgress: progress];
	}
}

@end
