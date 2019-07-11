# SGPlayer-iOS
forked from [SGPlayer](https://github.com/libobjc/SGPlayer)
在SGPlayer的基础上删除了ffmpeg部分，直接使用avplayer播放VR视频。超轻量级VR视频播放器，编译成动态库后只有2.7M，在项目中没有直播又需要播放VR视频时使用。

# 功能

* 播放普通视频；
* 播放360°全景视频，VR视频；
* 可手势和感应来控制VR视频的方向；
* distortion correction in cardboard mode.


# 安装

pod 'SGPlayer-iOS','~>1.0.1'

# 使用

* demo中有例子，具体请看SGVideoPlayer.m

#### 依赖的库

```
- CoreMedia.framework
- AudioToolBox.framework
- VideoToolBox.framework
- libiconv.tbd
- libbz2.tbd
- libz.tbd
```
#### 播放视频

```
// 初始化
self.player = [SGPlayer player];

// 注册回调，监听进度等
[self.player registerPlayerNotificationTarget:self stateAction:@selector(stateAction:) progressAction:@selector(progressAction:) playableAction:@selector(playableAction:) errorAction:@selector(errorAction:)];

// 响应点击
[self.player setViewTapAction:^(SGPlayer * _Nonnull player, SGPLFView * _Nonnull view) {
NSLog(@"player display view did click!");
}];

// 播放普通视频
[self.player replaceVideoWithURL:contentURL]; // 方式1
[self.player replaceVideoWithURL:contentURL videoType:SGVideoTypeNormal]; // 方式2

// 播放360°全景视频
[self.player replaceVideoWithURL:contentURL videoType:SGVideoTypeVR];

// 开启黑灰滤镜
self.player.hasGrayFilter = YES;

// 播放
[self.player play];
```

#### release note

###### v1.0.1 

使用CoreImage加入视频黑灰滤镜，使用参数hasGrayFilter开启
