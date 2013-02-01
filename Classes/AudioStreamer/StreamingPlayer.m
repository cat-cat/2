//
//  StreamingPlayer.m
//

#import "StreamingPlayer.h"
#import "AudioStreamer.h"
#import <QuartzCore/CoreAnimation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>

@implementation StreamingPlayer

@synthesize delegate;
@synthesize streamer;

- (id)initPlayerWithURL:(NSURL*)anURL
{
	if ((self = [super init]))
	{
		streamer = [[AudioStreamer alloc] initWithURL:anURL] ;
        NSLog(@"++stream URL: %@", anURL);
		
		progressUpdateTimer =
		[NSTimer
		 scheduledTimerWithTimeInterval:0.1
		 target:self
		 selector:@selector(updateProgress:)
		 userInfo:nil
		 repeats:YES];
		[[NSNotificationCenter defaultCenter]
		 addObserver:self
		 selector:@selector(playbackStateChanged:)
		 name:ASStatusChangedNotification
		 object:self.streamer];
        
        [self.streamer start];
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter]
	 removeObserver:self
	 name:ASStatusChangedNotification
	 object:streamer];
	[progressUpdateTimer invalidate];
	progressUpdateTimer = nil;
	
	[self.streamer stop];
	[streamer release];
	self.delegate = nil;
	[progressUpdateTimer invalidate];
	progressUpdateTimer = nil;
	
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
