//
//  PlayerViewController.h
//  demo-ios
//
//  Created by Single on 2017/3/15.
//  Copyright © 2017年 single. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DemoType) {
    DemoType_AVPlayer_Normal = 0,
    DemoType_AVPlayer_live,
    DemoType_AVPlayer_VR,
    DemoType_AVPlayer_VR_Box,
};

@interface PlayerViewController : UIViewController

@property (nonatomic, assign) DemoType demoType;

+ (NSString *)displayNameForDemoType:(DemoType)demoType;

@end
