
#import "JRMAudioPlayer.h"

@import AVFoundation;
@import CoreMedia;
@import AudioToolbox;

@interface JRMAudioPlayer ()

@property (strong, nonatomic) NSArray<AVPlayer *> *players;

@end

@implementation JRMAudioPlayer

- (void)playTrack:(int)trackNumber {
    if (self.players == nil) {
        NSMutableArray *mutablePlayers = [NSMutableArray array];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"layer_1" ofType:@"mp3"];
        AVPlayer *player = [self setupAVPlayerForPath:path];
        [mutablePlayers addObject:player];
        path = [[NSBundle mainBundle] pathForResource:@"layer_2" ofType:@"mp3"];
        player = [self setupAVPlayerForPath:path];
        [mutablePlayers addObject:player];
        path = [[NSBundle mainBundle] pathForResource:@"layer_3" ofType:@"mp3"];
        player = [self setupAVPlayerForPath:path];
        [mutablePlayers addObject:player];
        self.players = mutablePlayers.copy;
    }
    [self.players[trackNumber] play];
}

- (void)pauseTrack:(int)trackNumber {
    [self.players[trackNumber] pause];
}

-(AVPlayer *)setupAVPlayerForPath:(NSString *)path {
    NSURL *url = [[NSURL alloc] initFileURLWithPath: path];
    AVAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVPlayerItem *anItem = [AVPlayerItem playerItemWithAsset:asset];
    
    AVPlayer *player = [AVPlayer playerWithPlayerItem:anItem];
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification *notification) {
        [player seekToTime:kCMTimeZero];
        [player play];
    }];
    return player;
}

- (void)startSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    NSError *setCategoryError = nil;
    BOOL success = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    if (!success) { /* handle the error condition */ }
    
    NSError *activationError = nil;
    success = [audioSession setActive:YES error:&activationError];
    if (!success) { /* handle the error condition */ }
}

@end
