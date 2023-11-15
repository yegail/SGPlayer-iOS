//
//  SGPlayer.m
//  SGPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGPlayerImp.h"
#import "SGPlayerMacro.h"
#import "SGPlayerNotification.h"
#import "SGDisplayView.h"
#import "SGAVPlayer.h"

#import "SGPlayerBuildConfig.h"

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
//#import "SGAudioManager.h"
#endif

@interface SGPlayer ()

@property (nonatomic, copy) NSURL * contentURL;
@property (nonatomic, assign) SGVideoType videoType;

@property (nonatomic, strong) SGDisplayView * displayView;
@property (nonatomic, assign) SGDecoderType decoderType;
@property (nonatomic, strong) SGAVPlayer * avPlayer;

@property (nonatomic, assign) BOOL needAutoPlay;
@property (nonatomic, assign) NSTimeInterval lastForegroundTimeInterval;

@end

@implementation SGPlayer

+ (instancetype)player
{
    return [[self alloc] init];
}

- (instancetype)init
{
    if (self = [super init]) {
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
//        [self setupNotification];
#endif
        self.decoder = [SGPlayerDecoder decoderByDefault];
        self.contentURL = nil;
        self.videoType = SGVideoTypeNormal;
        self.backgroundMode = SGPlayerBackgroundModeAutoPlayAndPause;
        self.displayMode = SGDisplayModeNormal;
        self.viewGravityMode = SGGravityModeResizeAspect;
        self.playableBufferInterval = 2.f;
        self.viewAnimationHidden = YES;
        self.hasGrayFilter = NO;
        self.volume = 1;
        self.displayView = [SGDisplayView displayViewWithAbstractPlayer:self];
    }
    return self;
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL
{
    [self replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal];
}

- (void)replaceVideoWithURL:(nullable NSURL *)contentURL videoType:(SGVideoType)videoType
{
    self.error = nil;
    self.contentURL = contentURL;
    self.decoderType = [self.decoder decoderTypeForContentURL:self.contentURL];
    self.videoType = videoType;
    switch (self.videoType)
    {
        case SGVideoTypeNormal:
        case SGVideoTypeVR:
            break;
        default:
            self.videoType = SGVideoTypeNormal;
            break;
    }
    
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
        {
            if (!self.avPlayer) {
                self.avPlayer =[SGAVPlayer playerWithAbstractPlayer:self];
                self.avPlayer.httpHeaders = self.httpHeaders;
            }
            [self.avPlayer replaceVideo];
        }
            break;
        case SGDecoderTypeError:
        {
            [self.avPlayer stop];
        }
            break;
    }
}

- (void)play
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = YES;
#endif
    
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer play];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)pause
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = NO;
#endif
    
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer pause];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)stop
{
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = NO;
#endif
    
    [self replaceVideoWithURL:nil];
}

- (BOOL)seekEnable
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.seekEnable;
            break;
        case SGDecoderTypeError:
            return NO;
    }
}

- (BOOL)seeking
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.seeking;
        case SGDecoderTypeError:
            return NO;
    }
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(nullable void (^)(BOOL))completeHandler
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer seekToTime:time completeHandler:completeHandler];
            break;
        case SGDecoderTypeError:
            break;
    }
}

- (void)setVolume:(CGFloat)volume
{
    _volume = volume;
    [self.avPlayer reloadVolume];
}

- (void)setPlayableBufferInterval:(NSTimeInterval)playableBufferInterval
{
    _playableBufferInterval = playableBufferInterval;
}

- (void)setViewGravityMode:(SGGravityMode)viewGravityMode
{
    _viewGravityMode = viewGravityMode;
    [self.displayView reloadGravityMode];
}

- (SGPlayerState)state
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.state;
        case SGDecoderTypeError:
            return SGPlayerStateNone;
    }
}

- (CGSize)presentationSize
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.presentationSize;
        case SGDecoderTypeError:
            return CGSizeZero;
    }
}

- (NSTimeInterval)bitrate
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.bitrate;
        case SGDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)progress
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.progress;
        case SGDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)duration
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.duration;
        case SGDecoderTypeError:
            return 0;
    }
}

- (NSTimeInterval)playableTime
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.playableTime;
        case SGDecoderTypeError:
            return 0;
    }
}

- (SGPLFImage *)snapshot
{
    return self.displayView.snapshot;
}

- (SGPLFView *)view
{
    return self.displayView;
}

- (void)setError:(SGError * _Nullable)error
{
    if (self.error != error) {
        self->_error = error;
    }
}

- (void)cleanPlayer
{
    [self.avPlayer stop];
    self.avPlayer = nil;
    [self cleanPlayerView];
    
#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
    [UIApplication sharedApplication].idleTimerDisabled = NO;
#endif
    
    self.needAutoPlay = NO;
    self.error = nil;
}

- (void)cleanPlayerView
{
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof SGPLFView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
}

- (void)dealloc
{
    SGPlayerLog(@"SGPlayer release");
    [self cleanPlayer];

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
//    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [[SGAudioManager manager] removeHandlerTarget:self];
#endif
}

#pragma mark - background mode

#if SGPLATFORM_TARGET_OS_IPHONE_OR_TV
/*
- (void)setupNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    SGWeakSelf
    SGAudioManager * manager = [SGAudioManager manager];
    [manager setHandlerTarget:self interruption:^(id handlerTarget, SGAudioManager *audioManager, SGAudioManagerInterruptionType type, SGAudioManagerInterruptionOption option) {
        SGStrongSelf
        if (type == SGAudioManagerInterruptionTypeBegin) {
            switch (strongSelf.state) {
                case SGPlayerStatePlaying:
                case SGPlayerStateBuffering:
                {
                    // fix : maybe receive interruption notification when enter foreground.
                    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSince1970];
                    if (timeInterval - strongSelf.lastForegroundTimeInterval > 1.5) {
                        [strongSelf pause];
                    }
                }
                    break;
                default:
                    break;
            }
        }
    } routeChange:^(id handlerTarget, SGAudioManager *audioManager, SGAudioManagerRouteChangeReason reason) {
        SGStrongSelf
        if (reason == SGAudioManagerRouteChangeReasonOldDeviceUnavailable) {
            switch (strongSelf.state) {
                case SGPlayerStatePlaying:
                case SGPlayerStateBuffering:
                {
                    [strongSelf pause];
                }
                    break;
                default:
                    break;
            }
        }
    }];
}
 */

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    switch (self.backgroundMode) {
        case SGPlayerBackgroundModeNothing:
        case SGPlayerBackgroundModeContinue:
            break;
        case SGPlayerBackgroundModeAutoPlayAndPause:
        {
            switch (self.state) {
                case SGPlayerStatePlaying:
                case SGPlayerStateBuffering:
                {
                    self.needAutoPlay = YES;
                    [self pause];
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    switch (self.backgroundMode) {
        case SGPlayerBackgroundModeNothing:
        case SGPlayerBackgroundModeContinue:
            break;
        case SGPlayerBackgroundModeAutoPlayAndPause:
        {
            switch (self.state) {
                case SGPlayerStateSuspend:
                {
                    if (self.needAutoPlay) {
                        self.needAutoPlay = NO;
                        [self play];
                        self.lastForegroundTimeInterval = [NSDate date].timeIntervalSince1970;
                    }
                }
                    break;
                default:
                    break;
            }
        }
            break;
    }
}
#endif

@end


#pragma mark - Tracks Category

@implementation SGPlayer (Tracks)

- (BOOL)videoEnable
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.videoEnable;
        case SGDecoderTypeError:
            return NO;
    }
}

- (BOOL)audioEnable
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.audioEnable;
        case SGDecoderTypeError:
            return NO;
    }
}

- (SGPlayerTrack *)videoTrack
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.videoTrack;
        case SGDecoderTypeError:
            return nil;
    }
}

- (SGPlayerTrack *)audioTrack
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.audioTrack;
        case SGDecoderTypeError:
            return nil;
    }
}

- (NSArray<SGPlayerTrack *> *)videoTracks
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.videoTracks;
        case SGDecoderTypeError:
            return nil;
    }
}

- (NSArray<SGPlayerTrack *> *)audioTracks
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return self.avPlayer.audioTracks;
        case SGDecoderTypeError:
            return nil;
    }
}

- (void)selectAudioTrack:(SGPlayerTrack *)audioTrack
{
    [self selectAudioTrackIndex:audioTrack.index];
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            [self.avPlayer selectAudioTrackIndex:audioTrackIndex];
        case SGDecoderTypeError:
            break;
    }
}

@end


#pragma mark - Thread Category

@implementation SGPlayer (Thread)

- (BOOL)videoDecodeOnMainThread
{
    switch (self.decoderType)
    {
        case SGDecoderTypeAVPlayer:
            return NO;
        case SGDecoderTypeError:
            return NO;
    }
}

- (BOOL)audioDecodeOnMainThread
{
    return NO;
}

@end
