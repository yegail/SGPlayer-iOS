//
//  ViewController.m
//  SGVideoPlayer
//
//  Created by TRS on 2019/5/8.
//  Copyright © 2019 yegail. All rights reserved.
//

#import "ViewController.h"
#import "PlayerViewController.h"
#import "SGVideoPlayer.h"

@interface ViewController ()

@property (strong, nonatomic) SGVideoPlayer *player;

@end

@implementation ViewController

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 9;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 300;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [PlayerViewController displayNameForDemoType:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*if (indexPath.row == 0) {
        [self.player destroyPlayer];
        self.player = nil;
        
        self.player = [[SGVideoPlayer alloc] init];
        self.player.frame = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds));
        NSURL *vrVideo = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"google-help-vr" ofType:@"mp4"]];
        [self.player replaceVideoWithURL:vrVideo videoType:SGVideoTypeVR];
        [self.player playerBindTableView:tableView currentIndexPath:indexPath];
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        self.player.frame = cell.bounds;
        [cell.contentView addSubview:self.player];
        
        self.player.completedPlayingBlock = ^(SGVideoPlayer *player) {
            [player destroyPlayer];
            player = nil;
        };
        
        self.player.closeBlock = ^(SGVideoPlayer *player) {
            [player destroyPlayer];
            player = nil;
        };
    }*/
    PlayerViewController * obj = [[PlayerViewController alloc] init];
    obj.demoType = indexPath.row;
    [self.navigationController pushViewController:obj animated:YES];
}

#pragma makr -UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    [_player playerScrollIsSupportSmallWindowPlay:YES];
}

#pragma mark -
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.player destroyPlayer];
    self.player = nil;
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate {
    return NO;
}

@end
