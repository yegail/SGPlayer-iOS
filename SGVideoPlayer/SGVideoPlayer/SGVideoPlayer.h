//
//  SGVideoPlayer.h
//  SGPlayer iOS
//
//  Created by TRS on 2019/5/8.
//  Copyright © 2019 yegail. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SGPlayer/SGPlayer.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGVideoPlayer : UIView
/**
 * 播放完成回调
 */
@property (nonatomic, copy) void (^completedPlayingBlock)(SGVideoPlayer *videoPlayer);

/**
 * 关闭按钮回调
 */
@property (nonatomic, copy) void (^closeBlock)(SGVideoPlayer *videoPlayer);
/**
 *  video url 视频路径
 */
- (void)replaceVideoWithURL:(NSURL *)contentURL;
- (void)replaceVideoWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType;
- (void)replaceVideoWithURL:(NSURL *)contentURL videoType:(SGVideoType)videoType displayMode:(SGDisplayMode)displayMode;

/*
 * 关闭按钮定制
 */
@property (nonatomic, assign) BOOL  closeHidden;

/**
 *  play or pause
 */
- (void)playPause;

/**
 *  dealloc 销毁
 */
- (void)destroyPlayer;

/**
 *  在cell上播放必须绑定TableView、当前播放cell的IndexPath
 */
- (void)playerBindTableView:(UITableView *)bindTableView currentIndexPath:(NSIndexPath *)currentIndexPath;

/**
 *  在scrollview的scrollViewDidScroll代理中调用
 *
 *  @param support        是否支持右下角小窗悬停播放
 */
- (void)playerScrollIsSupportSmallWindowPlay:(BOOL)support;

@end

NS_ASSUME_NONNULL_END
