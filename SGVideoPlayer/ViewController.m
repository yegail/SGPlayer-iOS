//
//  ViewController.m
//  SGVideoPlayer
//
//  Created by TRS on 2019/5/8.
//  Copyright © 2019 yegail. All rights reserved.
//

#import "ViewController.h"
#import "PlayerViewController.h"

@interface ViewController ()

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [PlayerViewController displayNameForDemoType:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PlayerViewController * obj = [[PlayerViewController alloc] init];
    obj.demoType = indexPath.row;
    [self.navigationController pushViewController:obj animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


@end
