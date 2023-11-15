//
//  SGAVPlayer.m
//  SGPlayer
//
//  Created by Single on 16/6/28.
//  Copyright © 2016年 single. All rights reserved.
//

#import "SGAVPlayer.h"
#import "SGPlayer+DisplayView.h"
#import "SGPlayerMacro.h"
#import "SGPlayerNotification.h"
#import <AVFoundation/AVFoundation.h>

static CGFloat const PixelBufferRequestInterval = 0.03f;
static NSString * const AVMediaSelectionOptionTrackIDKey = @"MediaSelectionOptionsPersistentID";

@interface SGAVPlayer ()

@property (nonatomic, weak) SGPlayer * abstractPlayer;

@property (nonatomic, assign) SGPlayerState state;
@property (nonatomic, assign) NSTimeInterval playableTime;
@property (nonatomic, assign) BOOL seeking;

@property (atomic, strong) id playBackTimeObserver;
@property (nonatomic, strong) AVPlayer * avPlayer;
@property (nonatomic, strong) AVPlayerItem * avPlayerItem;
@property (atomic, strong) AVURLAsset * avAsset;
@property (atomic, strong) AVPlayerItemVideoOutput * avOutput;
@property (atomic, assign) NSTimeInterval readyToPlayTime;

@property (atomic, assign) BOOL playing;
@property (atomic, assign) BOOL buffering;
@property (atomic, assign) BOOL hasPixelBuffer;

@property (nonatomic, assign) SGPlayerState stateBeforBuffering;


#pragma mark - track info

@property (nonatomic, assign) BOOL videoEnable;
@property (nonatomic, assign) BOOL audioEnable;

@property (nonatomic, strong) SGPlayerTrack * videoTrack;
@property (nonatomic, strong) SGPlayerTrack * audioTrack;

@property (nonatomic, strong) NSArray <SGPlayerTrack *> * videoTracks;
@property (nonatomic, strong) NSArray <SGPlayerTrack *> * audioTracks;

@end

@implementation SGAVPlayer

+ (instancetype)playerWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    return [[self alloc] initWithAbstractPlayer:abstractPlayer];
}

- (instancetype)initWithAbstractPlayer:(SGPlayer *)abstractPlayer
{
    if (self = [super init]) {
        self.abstractPlayer = abstractPlayer;
        self.abstractPlayer.displayView.playerOutputAV = self;
    }
    return self;
}

#pragma mark - play control

- (void)play
{
    self.playing = YES;
    
    switch (self.state) {
        case SGPlayerStateFinished:
            [self.avPlayer seekToTime:kCMTimeZero];
            self.state = SGPlayerStatePlaying;
            break;
        case SGPlayerStateFailed:
            [self replaceEmpty];
            [self replaceVideo];
            break;
        case SGPlayerStateNone:
            self.state = SGPlayerStateBuffering;
            break;
        case SGPlayerStateSuspend:
            if (self.buffering) {
                self.state = SGPlayerStateBuffering;
            } else {
                self.state = SGPlayerStatePlaying;
            }
            break;
        case SGPlayerStateReadyToPlay:
            self.state = SGPlayerStatePlaying;
            break;
        default:
            break;
    }
    
    [self.avPlayer play];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        switch (self.state) {
            case SGPlayerStateBuffering:
            case SGPlayerStatePlaying:
            case SGPlayerStateReadyToPlay:
                [self.avPlayer play];
            default:
                break;
        }
    });
}

- (void)startBuffering
{
    if (self.playing) {
        [self.avPlayer pause];
    }
    self.buffering = YES;
    if (self.state != SGPlayerStateBuffering) {
        self.stateBeforBuffering = self.state;
    }
    self.state = SGPlayerStateBuffering;
}

- (void)stopBuffering
{
    self.buffering = NO;
}

- (void)resumeStateAfterBuffering
{
    if (self.playing) {
        [self.avPlayer play];
        self.state = SGPlayerStatePlaying;
    } else if (self.state == SGPlayerStateBuffering) {
        self.state = self.stateBeforBuffering;
    }
}

- (BOOL)playIfNeed
{
    if (self.playing) {
        [self.avPlayer play];
        self.state = SGPlayerStatePlaying;
        return YES;
    }
    return NO;
}

- (void)pause
{
    [self.avPlayer pause];
    self.playing = NO;
    if (self.state == SGPlayerStateFailed) return;
    self.state = SGPlayerStateSuspend;
}

- (BOOL)seekEnable
{
    if (self.duration <= 0 || self.avPlayerItem.status != AVPlayerItemStatusReadyToPlay) {
        return NO;
    }
    return YES;
}

- (void)seekToTime:(NSTimeInterval)time
{
    [self seekToTime:time completeHandler:nil];
}

- (void)seekToTime:(NSTimeInterval)time completeHandler:(void (^)(BOOL))completeHandler
{
    if (!self.seekEnable || self.avPlayerItem.status != AVPlayerItemStatusReadyToPlay) {
        if (completeHandler) {
            completeHandler(NO);
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.seeking = YES;
        [self startBuffering];
        SGWeakSelf
        [self.avPlayerItem seekToTime:CMTimeMakeWithSeconds(time, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SGStrongSelf
                self.seeking = NO;
                [strongSelf stopBuffering];
                [strongSelf resumeStateAfterBuffering];
                if (completeHandler) {
                    completeHandler(finished);
                }
                SGPlayerLog(@"SGAVPlayer seek success");
            });
        }];
    });
}

- (void)stop
{
    [self replaceEmpty];
}

- (NSTimeInterval)progress
{
    CMTime currentTime = self.avPlayerItem.currentTime;
    Boolean indefinite = CMTIME_IS_INDEFINITE(currentTime);
    Boolean invalid = CMTIME_IS_INVALID(currentTime);
    if (indefinite || invalid) {
        return 0;
    }
    return CMTimeGetSeconds(self.avPlayerItem.currentTime);
}

- (NSTimeInterval)duration
{
    CMTime duration = self.avPlayerItem.duration;
    Boolean indefinite = CMTIME_IS_INDEFINITE(duration);
    Boolean invalid = CMTIME_IS_INVALID(duration);
    if (indefinite || invalid) {
        return 0;
    }
    return CMTimeGetSeconds(self.avPlayerItem.duration);;
}

- (double)percentForTime:(NSTimeInterval)time duration:(NSTimeInterval)duration
{
    double percent = 0;
    if (time > 0) {
        if (duration <= 0) {
            percent = 1;
        } else {
            percent = time / duration;
        }
    }
    return percent;
}

- (NSTimeInterval)bitrate
{
    return 0;
}

#pragma mark - Setter/Getter

- (void)setState:(SGPlayerState)state
{
    if (_state != state) {
        SGPlayerState temp = _state;
        _state = state;
        switch (self.state) {
            case SGPlayerStateFinished:
                self.playing = NO;
                break;
            case SGPlayerStateFailed:
                self.playing = NO;
                break;
            default:
                break;
        }
        if (_state != SGPlayerStateFailed) {
            self.abstractPlayer.error = nil;
        }
        [SGPlayerNotification postPlayer:self.abstractPlayer statePrevious:temp current:_state];
    }
}

- (void)reloadVolume
{
    self.avPlayer.volume = self.abstractPlayer.volume;
}

- (void)reloadPlayableTime
{
    if (self.avPlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        CMTimeRange range = [self.avPlayerItem.loadedTimeRanges.firstObject CMTimeRangeValue];
        if (CMTIMERANGE_IS_VALID(range)) {
            NSTimeInterval start = CMTimeGetSeconds(range.start);
            NSTimeInterval duration = CMTimeGetSeconds(range.duration);
            self.playableTime = (start + duration);
        }
    } else {
        self.playableTime = 0;
    }
}

- (void)setPlayableTime:(NSTimeInterval)playableTime
{
    if (_playableTime != playableTime) {
        _playableTime = playableTime;
        CGFloat duration = self.duration;
        double percent = [self percentForTime:_playableTime duration:duration];
        [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(percent) current:@(playableTime) total:@(duration)];
    }
}

- (CGSize)presentationSize
{
    if (self.avPlayerItem) {
        return self.avPlayerItem.presentationSize;
    }
    return CGSizeZero;
}


#pragma mark - SGAVPlayerOutput

- (AVPlayer *)playerOutputGetAVPlayer
{
    return self.avPlayer;
}

- (CVPixelBufferRef)playerOutputGetPixelBufferAtCurrentTime
{
    if (self.seeking) return nil;
    
    BOOL hasNewPixelBuffer = [self.avOutput hasNewPixelBufferForItemTime:self.avPlayerItem.currentTime];
    if (!hasNewPixelBuffer) {
        if (self.hasPixelBuffer) return nil;
        [self trySetupOutput];
        return nil;
    }
    
    CVPixelBufferRef pixelBuffer = [self.avOutput copyPixelBufferForItemTime:self.avPlayerItem.currentTime itemTimeForDisplay:nil];
    if (!pixelBuffer) {
        [self trySetupOutput];
    } else {
        self.hasPixelBuffer = YES;
    }
    return pixelBuffer;
}

- (SGPLFImage *)playerOutputGetSnapshotAtCurrentTime
{
    switch (self.abstractPlayer.videoType) {
        case SGVideoTypeNormal:
        {
            AVAssetImageGenerator * imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.avAsset];
            imageGenerator.appliesPreferredTrackTransform = YES;
            imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
            imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
            
            NSError * error = nil;
            CMTime time = self.avPlayerItem.currentTime;
            CMTime actualTime;
            CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
            SGPLFImage * image = SGPLFImageWithCGImage(cgImage);
            return image;
        }
            break;
        case SGVideoTypeVR:
        {
            return nil;
        }
            break;
    }
}


#pragma mark - play state change

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.avPlayerItem) {
        if ([keyPath isEqualToString:@"status"])
        {
            switch (self.avPlayerItem.status) {
                case AVPlayerItemStatusUnknown:
                {
                    [self startBuffering];
                    SGPlayerLog(@"SGAVPlayer item status unknown");
                }
                    break;
                case AVPlayerItemStatusReadyToPlay:
                {
                    [self stopBuffering];
                    [self setupTrackInfo];
                    SGPlayerLog(@"SGAVPlayer item status ready to play");
                    self.readyToPlayTime = [NSDate date].timeIntervalSince1970;
                    if (![self playIfNeed]) {
                        switch (self.state) {
                            case SGPlayerStateSuspend:
                            case SGPlayerStateFinished:
                            case SGPlayerStateFailed:
                                break;
                            default:
                                self.state = SGPlayerStateReadyToPlay;
                                break;
                        }
                    }
                }
                    break;
                case AVPlayerItemStatusFailed:
                {
                    SGPlayerLog(@"SGAVPlayer item status failed");
                    [self stopBuffering];
                    self.readyToPlayTime = 0;
                    SGError * error = [[SGError alloc] init];
                    if (self.avPlayerItem.error) {
                        error.error = self.avPlayerItem.error;
                        if (self.avPlayerItem.errorLog.extendedLogData.length > 0) {
                            error.extendedLogData = self.avPlayerItem.errorLog.extendedLogData;
                            error.extendedLogDataStringEncoding = self.avPlayerItem.errorLog.extendedLogDataStringEncoding;
                        }
                        if (self.avPlayerItem.errorLog.events.count > 0) {
                            NSMutableArray <SGErrorEvent *> * array = [NSMutableArray arrayWithCapacity:self.avPlayerItem.errorLog.events.count];
                            for (AVPlayerItemErrorLogEvent * obj in self.avPlayerItem.errorLog.events) {
                                SGErrorEvent * event = [[SGErrorEvent alloc] init];
                                event.date = obj.date;
                                event.URI = obj.URI;
                                event.serverAddress = obj.serverAddress;
                                event.playbackSessionID = obj.playbackSessionID;
                                event.errorStatusCode = obj.errorStatusCode;
                                event.errorDomain = obj.errorDomain;
                                event.errorComment = obj.errorComment;
                                [array addObject:event];
                            }
                            error.errorEvents = array;
                        }
                    } else if (self.avPlayer.error) {
                        error.error = self.avPlayer.error;
                    } else {
                        error.error = [NSError errorWithDomain:@"AVPlayer playback error" code:-1 userInfo:nil];
                    }
                    self.abstractPlayer.error = error;
                    self.state = SGPlayerStateFailed;
                    [SGPlayerNotification postPlayer:self.abstractPlayer error:error];
                }
                    break;
            }
        }
        else if ([keyPath isEqualToString:@"playbackBufferEmpty"])
        {
            if (self.avPlayerItem.playbackBufferEmpty) {
                [self startBuffering];
            }
        }
        else if ([keyPath isEqualToString:@"loadedTimeRanges"])
        {
            [self reloadPlayableTime];
            NSTimeInterval interval = self.playableTime - self.progress;
            NSTimeInterval residue = self.duration - self.progress;
            if (residue <= -1.5) {
                residue = 2;
            }
            if (interval > self.abstractPlayer.playableBufferInterval) {
                [self stopBuffering];
                [self resumeStateAfterBuffering];
            } else if (interval < 0.3 && residue > 1.5) {
                [self startBuffering];
            }
        }
    }
}

- (void)avplayerItemDidPlayToEnd:(NSNotification *)notification
{
    self.state = SGPlayerStateFinished;
}

- (void)avAssetPrepareFailed:(NSError *)error
{
    SGPlayerLog(@"%s", __func__);
}

#pragma mark - replace video

- (void)replaceVideo
{
    [self replaceEmpty];
    if (!self.abstractPlayer.contentURL) return;
    
    [self.abstractPlayer.displayView playerOutputTypeAV];
    [self startBuffering];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"AVURLAssetHTTPHeaderFieldsKey"] = self.httpHeaders;
    self.avAsset = [AVURLAsset URLAssetWithURL:self.abstractPlayer.contentURL options:dict];
    switch (self.abstractPlayer.videoType) {
        case SGVideoTypeNormal:
            [self setupAVPlayerItemAutoLoadedAsset:YES];
            [self setupAVPlayer];
            [self.abstractPlayer.displayView rendererTypeAVPlayerLayer];
            break;
        case SGVideoTypeVR:
        {
            [self setupAVPlayerItemAutoLoadedAsset:NO];
            [self setupAVPlayer];
            [self.abstractPlayer.displayView rendererTypeOpenGL];
            SGWeakSelf
            [self.avAsset loadValuesAsynchronouslyForKeys:[self.class AVAssetloadKeys] completionHandler:^{
                SGStrongSelf
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (NSString * loadKey in [strongSelf.class AVAssetloadKeys]) {
                        NSError * error = nil;
                        AVKeyValueStatus keyStatus = [strongSelf.avAsset statusOfValueForKey:loadKey error:&error];
                        if (keyStatus == AVKeyValueStatusFailed) {
                            [strongSelf avAssetPrepareFailed:error];
                            SGPlayerLog(@"AVAsset load failed");
                            return;
                        }
                    }
                    NSError * error = nil;
                    AVKeyValueStatus trackStatus = [strongSelf.avAsset statusOfValueForKey:@"tracks" error:&error];
                    if (trackStatus == AVKeyValueStatusLoaded) {
                        [strongSelf setupOutput];
                    } else {
                        SGPlayerLog(@"AVAsset load failed");
                    }
                });
            }];
        }
            break;
    }
}


#pragma mark - setup/clean

- (void)setupAVPlayer
{
    self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
    /*
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
        self.avPlayer.automaticallyWaitsToMinimizeStalling = NO;
    }
     */
    SGWeakSelf
    self.playBackTimeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        SGStrongSelf
        if (strongSelf.state == SGPlayerStatePlaying) {
            CGFloat current = CMTimeGetSeconds(time);
            CGFloat duration = strongSelf.duration;
            double percent = [strongSelf percentForTime:current duration:duration];
            [SGPlayerNotification postPlayer:strongSelf.abstractPlayer progressPercent:@(percent) current:@(current) total:@(duration)];
        }
    }];
    [self.abstractPlayer.displayView reloadPlayerConfig];
    [self reloadVolume];
}

- (void)cleanAVPlayer
{
    [self.avPlayer pause];
    [self.avPlayer cancelPendingPrerolls];
    [self.avPlayer replaceCurrentItemWithPlayerItem:nil];
    
    if (self.playBackTimeObserver) {
        [self.avPlayer removeTimeObserver:self.playBackTimeObserver];
        self.playBackTimeObserver = nil;
    }
    self.avPlayer = nil;
    [self.abstractPlayer.displayView reloadPlayerConfig];
}

- (void)setupAVPlayerItemAutoLoadedAsset:(BOOL)autoLoadedAsset
{
    if (autoLoadedAsset) {
        self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.avAsset automaticallyLoadedAssetKeys:[self.class AVAssetloadKeys]];
    } else {
        self.avPlayerItem = [AVPlayerItem playerItemWithAsset:self.avAsset];
    }
    
    if (self.abstractPlayer.hasGrayFilter) {
        self.avPlayerItem.videoComposition = [AVVideoComposition videoCompositionWithAsset:self.avAsset
                                                              applyingCIFiltersWithHandler:
                                              ^(AVAsynchronousCIImageFilteringRequest *request)
                                              {
                                                  @autoreleasepool {
                                                      NSError *err = nil;
                                                      CIImage *ciImage = request.sourceImage;
                                                      //灰色滤镜
                                                      CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome"];
                                                      [filter setValue:ciImage forKey:kCIInputImageKey];
                                                      [filter setValue:[CIColor colorWithRed:0.7 green:0.7 blue:0.7] forKey:kCIInputColorKey];
                                                      [filter setValue:@1.0 forKey:kCIInputIntensityKey];
                                                      
                                                      CIImage *outputImage = filter.outputImage;
                                                      if (outputImage)
                                                      [request finishWithImage:outputImage context:nil];
                                                      else
                                                      [request finishWithError:err];
                                                      
                                                      outputImage = nil;
                                                  }
                                              }];
    }
    [self.avPlayerItem addObserver:self forKeyPath:@"status" options:0 context:NULL];
    [self.avPlayerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:NULL];
    [self.avPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avplayerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_avPlayerItem];
}

- (void)cleanAVPlayerItem
{
    if (self.avPlayerItem) {
        [self.avPlayerItem cancelPendingSeeks];
        [self.avPlayerItem removeObserver:self forKeyPath:@"status"];
        [self.avPlayerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.avPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [self.avPlayerItem removeOutput:self.avOutput];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayerItem];
        self.avPlayerItem = nil;
    }
}

- (void)trySetupOutput
{
    BOOL isReadyToPlay = self.avPlayerItem.status == AVPlayerStatusReadyToPlay && self.readyToPlayTime > 10 && (([NSDate date].timeIntervalSince1970 - self.readyToPlayTime) > 0.3);
    if (isReadyToPlay) {
        [self setupOutput];
    }
}

- (void)setupOutput
{
    [self cleanOutput];
    
    NSDictionary * pixelBuffer = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    self.avOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixelBuffer];
    [self.avOutput requestNotificationOfMediaDataChangeWithAdvanceInterval:PixelBufferRequestInterval];
    [self.avPlayerItem addOutput:self.avOutput];
    
    SGPlayerLog(@"SGAVPlayer add output success");
}

- (void)cleanOutput
{
    if (self.avPlayerItem) {
        [self.avPlayerItem removeOutput:self.avOutput];
    }
    self.avOutput = nil;
    self.hasPixelBuffer = NO;
}

- (void)replaceEmpty
{
    [SGPlayerNotification postPlayer:self.abstractPlayer playablePercent:@(0) current:@(0) total:@(0)];
    [SGPlayerNotification postPlayer:self.abstractPlayer progressPercent:@(0) current:@(0) total:@(0)];
    [self.avAsset cancelLoading];
    self.avAsset = nil;
    [self cleanOutput];
    [self cleanAVPlayerItem];
    [self cleanAVPlayer];
    [self cleanTrackInfo];
    self.state = SGPlayerStateNone;
    self.stateBeforBuffering = SGPlayerStateNone;
    self.seeking = NO;
    self.playableTime = 0;
    self.readyToPlayTime = 0;
    self.buffering = NO;
    self.playing = NO;
    [self.abstractPlayer.displayView playerOutputTypeEmpty];
    [self.abstractPlayer.displayView rendererTypeEmpty];
}

+ (NSArray <NSString *> *)AVAssetloadKeys
{
    static NSArray * keys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keys =@[@"tracks", @"playable"];
    });
    return keys;
}

- (void)dealloc
{
    SGPlayerLog(@"SGAVPlayer release");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self replaceEmpty];
    [self cleanAVPlayer];
}


#pragma mark - track info

- (void)setupTrackInfo
{
    if (self.videoEnable || self.audioEnable) return;
    
    NSMutableArray <SGPlayerTrack *> * videoTracks = [NSMutableArray array];
    NSMutableArray <SGPlayerTrack *> * audioTracks = [NSMutableArray array];
    
    for (AVAssetTrack * obj in self.avAsset.tracks) {
        if ([obj.mediaType isEqualToString:AVMediaTypeVideo]) {
            self.videoEnable = YES;
            [videoTracks addObject:[self playerTrackFromAVTrack:obj]];
        } else if ([obj.mediaType isEqualToString:AVMediaTypeAudio]) {
            self.audioEnable = YES;
            [audioTracks addObject:[self playerTrackFromAVTrack:obj]];
        }
    }
    
    if (videoTracks.count > 0) {
        self.videoTracks = videoTracks;
        AVMediaSelectionGroup * videoGroup = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicVisual];
        if (videoGroup) {
            int trackID = [[videoGroup.defaultOption.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            for (SGPlayerTrack * obj in self.audioTracks) {
                if (obj.index == (int)trackID) {
                    self.videoTrack = obj;
                }
            }
            if (!self.videoTrack) {
                self.videoTrack = self.videoTracks.firstObject;
            }
        } else {
            self.videoTrack = self.videoTracks.firstObject;
        }
    }
    if (audioTracks.count > 0) {
        self.audioTracks = audioTracks;
        AVMediaSelectionGroup * audioGroup = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
        if (audioGroup) {
            int trackID = [[audioGroup.defaultOption.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            for (SGPlayerTrack * obj in self.audioTracks) {
                if (obj.index == (int)trackID) {
                    self.audioTrack = obj;
                }
            }
            if (!self.audioTrack) {
                self.audioTrack = self.audioTracks.firstObject;
            }
        } else {
            self.audioTrack = self.audioTracks.firstObject;
        }
    }
}

- (void)cleanTrackInfo
{
    self.videoEnable = NO;
    self.videoTrack = nil;
    self.videoTracks = nil;
    
    self.audioEnable = NO;
    self.audioTrack = nil;
    self.audioTracks = nil;
}

- (void)selectAudioTrackIndex:(int)audioTrackIndex
{
    if (self.audioTrack.index == audioTrackIndex) return;
    AVMediaSelectionGroup * group = [self.avAsset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    if (group) {
        for (AVMediaSelectionOption * option in group.options) {
            int trackID = [[option.propertyList objectForKey:AVMediaSelectionOptionTrackIDKey] intValue];
            if (audioTrackIndex == trackID) {
                [self.avPlayerItem selectMediaOption:option inMediaSelectionGroup:group];
                for (SGPlayerTrack * track in self.audioTracks) {
                    if (track.index == audioTrackIndex) {
                        self.audioTrack = track;
                        break;
                    }
                }
                break;
            }
        }
    }
}

- (SGPlayerTrack *)playerTrackFromAVTrack:(AVAssetTrack *)track
{
    if (track) {
        SGPlayerTrack * obj = [[SGPlayerTrack alloc] init];
        obj.index = (int)track.trackID;
        obj.name = track.languageCode;
        return obj;
    }
    return nil;
}

@end
