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
    int bookId;
    NSString* chapter;
    
@private
	
	//
	// Delegating:
	id<StreamingPlayerDelegate> delegate;
	
	//
	// Streamer:
	AudioStreamer *streamer;
	NSTimer *progressUpdateTimer;
}

@property (nonatomic, assign) int bookId;
@property (nonatomic,copy) NSString * chapter;
@property (nonatomic, readwrite, assign) id<StreamingPlayerDelegate> delegate;
@property (nonatomic, retain) AudioStreamer *streamer;

-(void)myrelease;
//- (id)initPlayerWithURL:(NSURL*)anURL;
- (id)initPlayerWithBookAndChapter:(int)bid chapter:(NSString*)ch;
- (void)updateProgress:(NSTimer *)aNotification;

@end

