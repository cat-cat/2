//
//  StreamingPlayer.h
//

#import <UIKit/UIKit.h>



@class StreamingPlayer;

@protocol StreamingPlayerDelegate <NSObject>

@optional
- (void) setPlayButton:(int)play;
- (void) streamingPlayerIsWaiting:(StreamingPlayer *) anPlayer;
- (void) streamingPlayerDidStartPlaying:(StreamingPlayer *) anPlayer;
- (void) streamingPlayerDidStopPlaying:(StreamingPlayer *) anPlayer;

- (void) streamingPlayer:(StreamingPlayer *) anPlayer didUpdateProgress:(double) anProgress;

@end



@class AudioStreamer;

@interface StreamingPlayer : NSObject
{	
	//
	// Delegating:
	id<StreamingPlayerDelegate> delegate;
	
	//
	// Streamer:
	AudioStreamer *streamer;
	NSTimer *progressUpdateTimer;
}

@property (readonly, nonatomic, retain) NSString* bookId;
@property (readonly, nonatomic, retain) NSString * chapter;
@property (nonatomic, readwrite, assign) id<StreamingPlayerDelegate> delegate;
@property (nonatomic, retain) AudioStreamer *streamer;

-(void)myrelease;
//- (id)initPlayerWithURL:(NSURL*)anURL;
- (id)initPlayerWithBook:(NSString*)bid chapter:(NSString*)ch;
- (void)updateProgress:(NSTimer *)aNotification;

@end

