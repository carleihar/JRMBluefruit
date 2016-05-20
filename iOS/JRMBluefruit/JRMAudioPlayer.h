
@import Foundation;

@interface JRMAudioPlayer : NSObject

/**
 *  Start an audio session so that the app can continue playing audio in the background.
 */
- (void)startSession;
/**
 *  Start playing or unpause a track.
 *
 *  @param trackNumber The track number to play.
 */
- (void)playTrack:(int)trackNumber;
/**
 *  Pause a track.
 *
 *  @param trackNumber The track number to pause.
 */
- (void)pauseTrack:(int)trackNumber;

@end
