//
//  PlayerViewController.m
//  SGVideoPlayer
//
//  Created by TRS on 2019/5/8.
//  Copyright © 2019 yegail. All rights reserved.
//

#import "PlayerViewController.h"
#import <SGPlayer/SGPlayer.h>
#import "SGVideoPlayer.h"

@interface PlayerViewController ()

@property (nonatomic, strong) SGVideoPlayer * videoPlayer;

@end

@implementation PlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    
    [self.view addSubview:self.videoPlayer];
    
    static NSURL * normalVideo = nil;
    static NSURL * vrVideo = nil;
    static NSURL * vrVideoOnline = nil;
    static NSURL * liveVideo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        normalVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"i-see-fire" ofType:@"mp4"]];
        vrVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
        vrVideoOnline = [NSURL URLWithString:@"http://media.snxw.com/masvod/public/2017/04/11/20170411_15b5b277d53_r1_1200k.mp4"];
        liveVideo = [NSURL URLWithString:@"http://cstv.live.wscdns.com/live/xiamen/playlist.m3u8"];
    });
    switch (self.demoType)
    {
        case DemoType_AVPlayer_Normal:
            [self.videoPlayer replaceVideoWithURL:normalVideo];
            break;
        case DemoType_AVPlayer_live:
            [self.videoPlayer replaceVideoWithURL:liveVideo];
            break;
        case DemoType_AVPlayer_VR:
            [self.videoPlayer replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
            break;
        case DemoType_AVPlayer_VR_Box:
            [self.videoPlayer replaceVideoWithURL:vrVideoOnline videoType:SGVideoTypeVR];
            break;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.videoPlayer destroyPlayer];
    self.videoPlayer = nil;
}

- (SGVideoPlayer *)videoPlayer {
    if (!_videoPlayer) {
        _videoPlayer = [[SGVideoPlayer alloc] init];
        _videoPlayer.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 400);
        __weak typeof(self) weakSelf = self;
        _videoPlayer.closeBlock = ^(SGVideoPlayer *player) {
            [weakSelf.navigationController popViewControllerAnimated:YES];
        };
    }
    return _videoPlayer;
}

+ (NSString *)displayNameForDemoType:(DemoType)demoType
{
    static NSArray * displayNames = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        displayNames = @[@"普通视频，i see fire",
                         @"厦门卫视直播 m3u8格式",
                         @"本地VR视频，VR",
                         @"线上VR视频，VR online"];
    });
    if (demoType < displayNames.count) {
        return [displayNames objectAtIndex:demoType];
    }
    return nil;
}

- (IBAction)back:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
