//
//  StreamingPlayer.h
//

#import <UIKit/UIKit.h>



@class StreamingPlayer;

@protocol StreamingPlayerDelegate <NSObject>

@optional
- (void) streamingPlayerIsWaiting:(StreamingPlayer *) anPlayer;
- (void) streamingPlayerDidStartPlaying:(StreamingPlayer *) anPlayer;
- (void) streamingPlayerDidStopPlaying:(StreamingPlayer *) anPlayer;

- (void) streamingPlayer:(StreamingPlayer *) anPlayer didUpdateProgress:(double) anProgress;

@end



@class AudioStreamer;

@interface StreamingPlayer : NSObject
{
@private
	
	//
	// Delegating:
	id<StreamingPlayerDelegate> delegate;
	
	//
	// Streamer:
	AudioStreamer *streamer;
	NSTimer *progressUpdateTimer;
}

@property (nonatomic, readwrite, assign) id<StreamingPlayerDelegate> delegate;
@property (nonatomic, retain) AudioStreamer *streamer;

- (id)initPlayerWithURL:(NSURL*)anURL;
- (void)updateProgress:(NSTimer *)aNotification;

@end

