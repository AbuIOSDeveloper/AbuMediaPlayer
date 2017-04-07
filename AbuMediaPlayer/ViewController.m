//
//  ViewController.m
//  AbuMediaPlayer
//
//  Created by 阿布 on 17/4/7.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import "ViewController.h"
#import "AbuPlayer.h"
@interface ViewController ()<AbuPlayDelegate>

@property (nonatomic, strong) AbuPlayer *abuPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.abuPlayer.Url = @"http://wvideo.spriteapp.cn/video/2015/0820/55d5addd8d4c9_wpc.mp4";
    [self.view addSubview:self.abuPlayer];
    [self.abuPlayer play];
}

- (void)didNextPlayer
{
    self.abuPlayer.Url = @"http://wimg.spriteapp.cn/picture/2016/1118/582ee6ed3a5d6_wpd_87.jpg";//自己更换链接即可
    [self.abuPlayer play];
}

- (void)didPlayerFullOrSmall:(BOOL)flag
{
    if (flag) {
        self.navigationController.navigationBarHidden = YES;
        self.tabBarController.tabBar.hidden = YES;
    }else{
        self.navigationController.navigationBarHidden = NO;
        self.tabBarController.tabBar.hidden = NO;
    }
}

- (AbuPlayer *)abuPlayer
{
    if (!_abuPlayer) {
        _abuPlayer = [[AbuPlayer alloc]initWithFrame:CGRectMake(0, 64, self.view.frame.size.width, 200)];
        _abuPlayer.delegate = self;
        //        _abuPlayer.backgroundColor = [UIColor redColor];
    }
    return _abuPlayer;
}



@end
