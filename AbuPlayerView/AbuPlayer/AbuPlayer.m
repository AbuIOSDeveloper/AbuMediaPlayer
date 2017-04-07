//
//  AbuPlayer.m
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import "AbuPlayer.h"
#import "VideoTask.h"
#import "LoadURLConnection.h"
#import "UIDevice+Extension.h"
#import "TapGesView.h"
#import "UIView+Extension.h"
#import <MediaPlayer/MediaPlayer.h>

#define HS_weakSelf(weakSelf) __unsafe_unretained __typeof(&*self)weakSelf = self;
#define VERSION  ([[[UIDevice currentDevice] systemVersion] floatValue])
#define DownloadPath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]

typedef NS_ENUM(NSUInteger, Direction) {
    LeftOrRight,//左或右
    UpOrDown,//上或下
    None//没有任何指示
};

@interface AbuPlayer()<TapGesViewDelegate, LoadURLConnectionDelegate>
{
    
    BOOL isAutoMovie;//是否开启自动缩到右下角
    BOOL isSmall;//判断是否在右下角
    BOOL isHiddenBottomView;//底部菜单是否收起
    BOOL isPlaying;//是否播放
    BOOL isFullScreen;//是否全屏
    BOOL isFirstLoad;//是否第一次加载
    BOOL isAutoOrient;//自动旋转（不是用放大按钮）
    BOOL isLoadFinished; //是否下载完毕
    CGRect playerFrame;//初始化的视屏大小
}

/**
 * 手势
 */
@property (nonatomic, strong) UITapGestureRecognizer * tap;

/**
 * 是否开启自动在右下角
 */
//@property (nonatomic, assign) BOOL                     isAutoMovie;

/**
 * 是否在右下角
 */
//@property (nonatomic, assign) BOOL                      isSmall;
//
///**
// * 隐藏bottomView
// */
//@property (nonatomic, assign) BOOL                      isHiddenBottomView;
//
///**
// * 是否播放
// */
//@property (nonatomic, assign) BOOL                      isPlaying;
//
///**
// * 是否全屏
// */
//@property (nonatomic, assign) BOOL                      isFullScreen;
//
///**
// * 是否第一次载入
// */
//@property (nonatomic, assign) BOOL                      isFirstLoad;
//
///**
// * 自动旋转
// */
//@property (nonatomic, assign)  BOOL                     isAutoOrient;
//
///**
// * 是否下载完毕
// */
//@property (nonatomic, assign) BOOL                      isLoadFinished;
//
///**
// * 初始化视频的大小
// */
//@property (nonatomic, assign) CGRect                    playerFrame;

/**
 * 底部控件View
 */
@property (nonatomic, strong) UIView                  * bottomMenuView;

/**
 * 开始/暂停按钮
 */
@property (nonatomic, strong) UIButton                * playOrPauseBtn;

/**
 * 下一个视屏（全屏显示）
 */
@property (nonatomic, strong) UIButton                * nextPlayerBtn;

/**
 * 缓冲进度条
 */
@property (nonatomic, strong) UIProgressView          * loadProgressView;

/**
 * 播放滑动条
 */
@property (nonatomic, strong) UISlider                * playSlider;

/**
 * 全屏/缩小按钮
 */
@property (nonatomic, strong) UIButton                * fullOrSmallBtn;

/**
 * 时间label
 */
@property (nonatomic, strong) UILabel                 * timeLabel;

/**
 * 菊花转圈
 */
@property (nonatomic, strong) UIActivityIndicatorView * loadingView;

@property (nonatomic, strong) AVPlayer                * abuPlayer;

@property (nonatomic, strong) AVPlayerItem            * abuPlayerItem;

@property (nonatomic, strong) AVURLAsset              * videoURLAsset;

@property (nonatomic, strong) AVAsset                 * videoAsset;

/**
 * 界面更新时间ID
 */
@property (nonatomic, strong) id                        playbackTimeObserver;

/**
 * 视屏时间总长
 */
@property (nonatomic, strong) NSString                * avTotalTime;
//上下左右手势操作
@property (assign, nonatomic) Direction                 direction;

/**
 * 触摸起始位置
 */
@property (assign, nonatomic) CGPoint                   startPoint;

/**
 * 记住当前音量/亮度
 */
@property (assign, nonatomic) CGFloat                   startVB;

/**
 * 开始进度
 */
@property (assign, nonatomic) CGFloat                   startVideoRate;

/**
 * 定时器(跟屏幕刷新同步)
 */
@property (strong, nonatomic) CADisplayLink           * link;
@property (assign, nonatomic) NSTimeInterval            lastTime;

/**
 * 音量view
 */
@property (strong, nonatomic) MPVolumeView            * volumeView;

/**
 * 控制音量滑块
 */
@property (strong, nonatomic) UISlider                * volumeViewSlider;

/**
 * 当期视频的播放进度
 */
@property (assign, nonatomic) CGFloat                   currentRate;
//缓存
@property (nonatomic, strong) LoadURLConnection       * resouerLoader;

/**
 * 缓存地址
 */
@property (nonatomic, strong) NSURL                   * filePath;

@property (nonatomic, strong) NSString                * mediaPath;

@end

@implementation AbuPlayer

+ (Class)layerClass
{
    return [AVPlayerLayer class];
}

- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
   [(AVPlayerLayer *)[self layer] setPlayer:player];
}


- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        [self setUserInteractionEnabled:NO];
        
        playerFrame = frame;
        self.originalFrame = frame;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.abuPlayerItem];//注册监听，视屏播放完成
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];//注册监听，屏幕方向改变
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];//home键退出
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];//进入app
    }
    return self;
}

#pragma mark - 初始化播放器
- (void)initPlayer{
    //限制锁屏
    [UIApplication sharedApplication].idleTimerDisabled=YES;
    
    if (self.abuPlayer) {
        self.abuPlayer = nil;
    }
    
    //如果是ios  < 7 或者是本地资源，直接播放
    if ([self fileExistsAtPath:self.Url]) {
        
        self.videoAsset = [AVURLAsset URLAssetWithURL:self.filePath options:nil];
        self.abuPlayerItem = [AVPlayerItem playerItemWithAsset:_videoAsset];
        
    }else{
        
        self.resouerLoader = [[LoadURLConnection alloc] init];
        self.resouerLoader.delegate = self;
        self.resouerLoader.mediaPath = self.mediaPath;
        NSURL *playUrl = [_resouerLoader getSchemeVideoURL:[NSURL URLWithString:self.Url]];
        self.videoURLAsset = [AVURLAsset URLAssetWithURL:playUrl options:nil];
        [_videoURLAsset.resourceLoader setDelegate:_resouerLoader queue:dispatch_get_main_queue()];
        self.abuPlayerItem = [AVPlayerItem playerItemWithAsset:_videoURLAsset];
        
        
    }
    
    self.abuPlayer = [AVPlayer playerWithPlayerItem:self.abuPlayerItem];
    [self setPlayer:self.abuPlayer];
    
    [self.abuPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];//监听status属性变化
    [self.abuPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];//见天loadedTimeRanges属性变化
}

#pragma mark - 添加控件
- (void)addToolView{
    
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(upadte)];//和屏幕频率刷新相同的定时器
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    [self.gesView addSubview:self.bottomMenuView];
    UITapGestureRecognizer *nilTap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
    nilTap.cancelsTouchesInView = NO;
    [self.bottomMenuView addGestureRecognizer:nilTap];//防止bottomMenuView也响应了self这个view的单击手势
    [self addSubview:self.gesView];
    [self.bottomMenuView addSubview:self.playOrPauseBtn];
    [self.bottomMenuView addSubview:self.nextPlayerBtn];
    [self.bottomMenuView addSubview:self.fullOrSmallBtn];
    [self.bottomMenuView addSubview:self.timeLabel];
    [self.bottomMenuView addSubview:self.loadProgressView];
    [self.bottomMenuView addSubview:self.playSlider];
    [self.gesView addSubview:self.loadingView];
}

#pragma mark - 单击隐藏或者展开底部菜单
- (void)showOrHidenMenuView{
    if (isHiddenBottomView) {
        [UIView animateWithDuration:0.3 animations:^{
            self.bottomMenuView.hidden  = NO;
            isHiddenBottomView = NO;
        }];
    }else{
        [UIView animateWithDuration:0.3 animations:^{
            self.bottomMenuView.hidden  = YES;
            isHiddenBottomView = YES;
        }];
    }
}

#pragma mark - 控件事件
//开始/暂停视频播放
- (void)playOrPauseAction{
    if (!isPlaying) {
        [self.abuPlayer play];
        isPlaying = YES;
        [self.playOrPauseBtn setImage:[UIImage imageNamed:@"pause_icon"] forState:UIControlStateNormal];
        if ([self.delegate respondsToSelector:@selector(didPlayerPlayOrPause:)]) {
            [self.delegate didPlayerPlayOrPause:NO];
        }
    }else{
        [self.abuPlayer pause];
        isPlaying = NO;
        [self.playOrPauseBtn setImage:[UIImage imageNamed:@"play_icon"] forState:UIControlStateNormal];
        if ([self.delegate respondsToSelector:@selector(didPlayerPlayOrPause:)]) {
            [self.delegate didPlayerPlayOrPause:YES];
        }
    }
}
//下一个视频
- (void)nextPlayerAction{
    if ([self.delegate respondsToSelector:@selector(didNextPlayer)]) {
        [self.delegate didNextPlayer];
    }
}
//放大/缩小视图
- (void)fullOrSmallAction{
    if (isFullScreen) {
        isAutoOrient = NO;
        [UIDevice middfyOrientation:UIInterfaceOrientationPortrait];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.frame = playerFrame;
        [self.fullOrSmallBtn setImage:[UIImage imageNamed:@"fullscreen_icon"] forState:UIControlStateNormal];
        isFullScreen = NO;
        if ([self.delegate respondsToSelector:@selector(didPlayerFullOrSmall:)]) {
            [self.delegate didPlayerFullOrSmall:NO];
        }
    }else{
        isAutoOrient = NO;
        [UIDevice middfyOrientation:UIInterfaceOrientationLandscapeRight];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        self.frame = self.window.bounds;
        [self.fullOrSmallBtn setImage:[UIImage imageNamed:@"fullscreen_icon"] forState:UIControlStateNormal];
        isFullScreen = YES;
        if ([self.delegate respondsToSelector:@selector(didPlayerFullOrSmall:)]) {
            [self.delegate didPlayerFullOrSmall:YES];
        }
    }
}
//slider拖动时
- (void)playSliderValueChanging:(id)sender{
    HS_weakSelf(weakSelf);
    UISlider *slider = (UISlider*)sender;
    [self.abuPlayer pause];
    [self.loadingView startAnimating];//缓冲没好时加上网络不佳，拖动后会加载网络
    if (slider.value == 0.0000) {
        [self.abuPlayer seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [weakSelf.abuPlayer play];
            [weakSelf.playOrPauseBtn setImage:[UIImage imageNamed:@"pause_icon"] forState:UIControlStateNormal];
            isPlaying = YES;
        }];
    }
}
//slider完成拖动时
- (void)playSliderValueDidChanged:(id)sender{
    HS_weakSelf(weakSelf);
    UISlider *slider = (UISlider*)sender;
    CMTime changeTime = CMTimeMakeWithSeconds(slider.value,NSEC_PER_SEC);
    [self.abuPlayer seekToTime:changeTime completionHandler:^(BOOL finished) {
        [weakSelf.abuPlayer play];
        [weakSelf.playOrPauseBtn setImage:[UIImage imageNamed:@"pause_icon"] forState:UIControlStateNormal];
        isPlaying = YES;
    }];
}

#pragma mark - 监听事件
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context{
    AVPlayerItem *playerItem = (AVPlayerItem *)object;
    if ([keyPath isEqualToString:@"status"]) {
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            
            [self.loadingView stopAnimating];
            [self setUserInteractionEnabled:YES];//成功才能弹出底部菜单
            
            CMTime duration = self.abuPlayerItem.duration;//获取视屏总长
            CGFloat totalSecond = playerItem.duration.value/playerItem.duration.timescale;//转换成秒
            
            self.playSlider.maximumValue = CMTimeGetSeconds(duration);//设置slider的最大值就是总时长
            self.avTotalTime = [self xjPlayerTimeStyle:totalSecond];//获取视屏总长及样式
            [self monitoringPlayerBack:playerItem];//监听播放状态
            
        }else if (playerItem.status == AVPlayerItemStatusUnknown){
            
        }else if (playerItem.status == AVPlayerStatusFailed){
            
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        
        NSTimeInterval timeInterval = [self caculatePlayerDuration];
        CMTime duration = self.abuPlayerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.loadProgressView setProgress:timeInterval/totalDuration animated:YES];
        
    }
    
}
//视屏播放完后的通知事件。从头开始播放；
- (void)playerFinish:(NSNotification*)notification{
    HS_weakSelf(weakSelf);
    [self.abuPlayer seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.playSlider setValue:0.0 animated:YES];
        [weakSelf.playOrPauseBtn setImage:[UIImage imageNamed:@"play_icon"] forState:UIControlStateNormal];
        isPlaying = NO;
    }];
}

//刷新，看播放是否卡顿
- (void)upadte
{
    NSTimeInterval current = CMTimeGetSeconds(self.abuPlayer.currentTime);
    if (current!=self.lastTime) {
        //没有卡顿
        if (isPlaying) {
            [self.abuPlayer play];
        }
        [self.loadingView stopAnimating];
    }else{
        if (!isPlaying) {
            [self.loadingView stopAnimating];
            return;
        }else{
            [self.loadingView startAnimating];
        }
    }
    self.lastTime = current;
}

//程序进入后台（如果播放，则暂停，否则不管）
- (void)appDidEnterBackground{
    if (isPlaying) {
        [self.abuPlayer pause];
        [self.abuPlayer removeTimeObserver:self.playbackTimeObserver];
    }
}
//程序进入前台（退出前播放，进来后继续播放，否则不管）
- (void)appDidEnterPlayGround{
    if (isPlaying) {
        [self.abuPlayer play];
        [self monitoringPlayerBack:self.abuPlayer.currentItem];
    }
}
#pragma mark - 屏幕方向改变的监听
//屏幕方向改变时的监听
- (void)screenChanged:(NSNotification *)notification{
    UIDeviceOrientation orient = [[UIDevice currentDevice] orientation];
    switch (orient) {
            isAutoOrient = YES;
        case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
        {
            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            self.frame = playerFrame;
            [self.fullOrSmallBtn setImage:[UIImage imageNamed:@"fullscreen_icon"] forState:UIControlStateNormal];
            isFullScreen = NO;
            if ([self.delegate respondsToSelector:@selector(didPlayerFullOrSmall:)]) {
                [self.delegate didPlayerFullOrSmall:NO];
            }
            [self layoutSubviews];
        }
            break;
        case UIDeviceOrientationLandscapeLeft:      // Device oriented horizontally, home button on the right
        {
            isFullScreen = YES;
            isAutoOrient = YES;
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            self.frame = self.window.bounds;
            [self.fullOrSmallBtn setImage:[UIImage imageNamed:@"fullscreen_icon"] forState:UIControlStateNormal];
            if ([self.delegate respondsToSelector:@selector(didPlayerFullOrSmall:)]) {
                [self.delegate didPlayerFullOrSmall:YES];
            }
            [self layoutSubviews];
        }
            break;
        case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
        {
            isFullScreen = YES;
            isAutoOrient = YES;
            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            self.frame = self.window.bounds;
            [self.fullOrSmallBtn setImage:[UIImage imageNamed:@"fullscreen_icon"] forState:UIControlStateNormal];
            if ([self.delegate respondsToSelector:@selector(didPlayerFullOrSmall:)]) {
                [self.delegate didPlayerFullOrSmall:YES];
            }
            
            [self layoutSubviews];
        }
            break;
        default:
            break;
    }
}
#pragma mark - 自定义事件
//定义视屏时长样式
- (NSString *)xjPlayerTimeStyle:(CGFloat)time{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (time/3600>1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }else{
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showTimeStyle = [formatter stringFromDate:date];
    return showTimeStyle;
}
//实时监听播放状态
- (void)monitoringPlayerBack:(AVPlayerItem *)playerItem{
    //一秒监听一次CMTimeMake(a, b),a/b表示多少秒一次；
    HS_weakSelf(weakSelf);
    self.playbackTimeObserver = [self.abuPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf.loadingView stopAnimating];
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;//获取当前时间
        [weakSelf.playSlider setValue:currentSecond animated:YES];
        
        if (!weakSelf->isFullScreen && weakSelf->isAutoMovie) {
            CGRect rect = [weakSelf.window convertRect:weakSelf.frame fromView:weakSelf.superview];
            
            if (rect.origin.y + (weakSelf.frame.size.height * 0.5 ) <= 0) {//当前PlayerView移除到屏幕外一半时，就缩到左下角
                [weakSelf bottomRightPlayer];
            }
        }
        
        NSString *timeString = [weakSelf xjPlayerTimeStyle:currentSecond];
        weakSelf.timeLabel.text = [NSString stringWithFormat:@"00:%@/00:%@",timeString,weakSelf.avTotalTime];
    }];
}

//移到右下角
- (void)bottomRightPlayer{
    self.frame = CGRectMake(self.window.right-160, self.window.height-150, 150, 100);
    isSmall = YES;
    [self.superview.superview addSubview:self];
    [self.superview.superview bringSubviewToFront:self];
    
    if (!isHiddenBottomView) {
        self.bottomMenuView.hidden = YES;
    }
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:nil];
    self.tap.cancelsTouchesInView = NO;
    [self.gesView addGestureRecognizer:self.tap];
    //    self.xjGestureButton.hidden = YES;
}

- (void)moviePlayeToOriginalPosition{
    if (!isFullScreen) {
        self.frame = playerFrame;
        isSmall = NO;
    }
    
    if (!isHiddenBottomView) {
        self.bottomMenuView.hidden = NO;
    }
    
    [self.gesView removeGestureRecognizer:self.tap];
    //    self.xjGestureButton.hidden = NO;
}
//计算缓冲区
- (NSTimeInterval)caculatePlayerDuration{
    NSArray *loadedTimeRanges = [[self.abuPlayer currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];//获取缓冲区域
    CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
    CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds+durationSeconds;//计算缓冲进度
    return result;
}
//判断是否存在已下载好的文件
- (BOOL)fileExistsAtPath:(NSString *)url{
    
    self.mediaPath = [[self.Url componentsSeparatedByString:@"/"] lastObject];//保存文件名是地址最后“/”后面的字符串
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempPath = DownloadPath;
    NSString *str = [tempPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",Player,self.mediaPath]];
    
    if ([fileManager fileExistsAtPath:url]) {
        self.filePath = [NSURL fileURLWithPath:url];
        NSLog(@"filePath:%@",self.filePath);
        return YES;
    }
    
    if ([fileManager fileExistsAtPath:str]) {
        self.filePath = [NSURL fileURLWithPath:str];
        NSLog(@"filePath:%@",str);
        return YES;
    }else{
        NSLog(@"没有缓存");
        return NO;
    }
    
}

#pragma mark - 自定义Button的代理***********************************************************
#pragma mark - 开始触摸
/*************************************************************************/
- (void)touchesBeganInPoint:(CGPoint)point
{
    //记录首次触摸坐标
    self.startPoint = point;
    //检测用户是触摸屏幕的左边还是右边，以此判断用户是要调节音量还是亮度，左边是音量，右边是亮度
    if (self.startPoint.x <= self.gesView.frame.size.width / 2.0) {
        //音/量
        self.startVB = self.volumeViewSlider.value;
    } else {
        //亮度
        self.startVB = [UIScreen mainScreen].brightness;
    }
    //方向置为无
    self.direction = None;
    //记录当前视频播放的进度
    CMTime ctime = self.abuPlayer.currentTime;
    self.startVideoRate = ctime.value / ctime.timescale / CMTimeGetSeconds(self.abuPlayer.currentItem.duration);
}

#pragma mark - 结束触摸
- (void)touchesEndInPoint:(CGPoint)point
{
    if (self.direction == LeftOrRight&&!isSmall) {
        [self.abuPlayer seekToTime:CMTimeMakeWithSeconds(CMTimeGetSeconds(self.abuPlayer.currentItem.duration) * self.currentRate, NSEC_PER_SEC) completionHandler:^(BOOL finished) {
            //在这里处理进度设置成功后的事情
        }];
    }
}

#pragma mark - 拖动
- (void)touchesMoveInPoint:(CGPoint)point
 {
    //得出手指在Button上移动的距离
    CGPoint panPoint = CGPointMake(point.x - self.startPoint.x, point.y - self.startPoint.y);
    
    if (isSmall) {
        // Calculate offset
        float dx = point.x - self.startPoint.x;
        float dy = point.y - self.startPoint.y;
        CGPoint newcenter = CGPointMake(self.center.x + dx, self.center.y + dy);
        
        //设置移动区域
        // Bound movement into parent bounds
        float halfx = CGRectGetMidX(self.bounds);
        newcenter.x = MAX(halfx, newcenter.x);
        newcenter.x = MIN(self.superview.bounds.size.width - halfx, newcenter.x);
        
        float halfy = CGRectGetMidY(self.bounds);
        newcenter.y = MAX(halfy, newcenter.y);
        newcenter.y = MIN(self.superview.bounds.size.height - halfy, newcenter.y);
        
        // Set new location
        self.center = newcenter;
    }
    
    //分析出用户滑动的方向
    if (self.direction == None) {
        if (panPoint.x >= 30 || panPoint.x <= -30) {
            //进度
            self.direction = LeftOrRight;
        } else if (panPoint.y >= 30 || panPoint.y <= -30) {
            //音量和亮度
            self.direction = UpOrDown;
        }
    }
    
    if (self.direction == None) {
        return;
    } else if (self.direction == UpOrDown && !isSmall) {
        //音量和亮度
        if (self.startPoint.x <= self.gesView.frame.size.width / 2.0) {
            //音量
            if (panPoint.y < 0) {
                //增大音量
                [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                if (self.startVB + (-panPoint.y / 30 / 10) - self.volumeViewSlider.value >= 0.1) {
                    [self.volumeViewSlider setValue:0.1 animated:NO];
                    [self.volumeViewSlider setValue:self.startVB + (-panPoint.y / 30.0 / 10) animated:YES];
                }
                
            } else {
                //减少音量
                [self.volumeViewSlider setValue:self.startVB - (panPoint.y / 30.0 / 10) animated:YES];
            }
            
        } else if(!isSmall){
            
            //调节亮度
            if (panPoint.y < 0) {
                //增加亮度
                [[UIScreen mainScreen] setBrightness:self.startVB + (-panPoint.y / 30.0 / 10)];
            } else {
                //减少亮度
                [[UIScreen mainScreen] setBrightness:self.startVB - (panPoint.y / 30.0 / 10)];
            }
        }
    } else if (self.direction == LeftOrRight &&!isSmall) {
        //进度
        CGFloat rate = self.startVideoRate + (panPoint.x / 30.0 / 20.0);
        if (rate > 1) {
            rate = 1;
        } else if (rate < 0) {
            rate = 0;
        }
        self.currentRate = rate;
    }
}
- (void)tapGestureAction:(UITapGestureRecognizer *)tap
{
    if (tap.numberOfTapsRequired == 1) {
        [self showOrHidenMenuView];
    }else if (tap.numberOfTapsRequired == 2){
        [self playOrPauseAction];
    }
}



#pragma mark - TBloaderURLConnectionDelegate
- (void)loadURLConnection:(LoadURLConnection *)load finishLoadingWithTask:(VideoTask *)task
{
    isLoadFinished = task.isFinishLoad;
}

//网络中断：-1005
//无网络连接：-1009
//请求超时：-1001
//服务器内部错误：-1004
//找不到服务器：-1003
- (void)loadURLConnection:(LoadURLConnection *)load failLoadingWithTask:(VideoTask *)task WithError:(NSInteger)errorCode
{
    NSString *str = nil;
    switch (errorCode) {
        case -1001:
            str = @"请求超时";
            break;
        case -1003:
        case -1004:
            str = @"服务器错误";
            break;
        case -1005:
            str = @"网络中断";
            break;
        case -1009:
            str = @"无网络连接";
            break;
            
        default:
            str = [NSString stringWithFormat:@"%@", @"(_errorCode)"];
            break;
    }
    NSLog(@"%@",str);
}


#pragma mark - 外部接口
/**
 *  如果想自己写底部菜单，可以移除我写好的菜单；然后通过接口和代理来控制视屏;
 */
- (void)removePlayerBottomMenu{
    [self.bottomMenuView removeFromSuperview];
}
- (void)addPlayerAutoMovie{
    isAutoMovie = YES;
}
/**
 *  暂停
 */
- (void)pause{
    [self playOrPauseAction];
}
/**
 *  开始
 */
- (void)play{
    [self playOrPauseAction];
}
/**
 * 定位视频播放时间
 *
 * @param seconds 秒
 *
 *
 */
- (void)getTimeWithSeconds:(Float64)seconds {
    [self.abuPlayer seekToTime:CMTimeMakeWithSeconds(seconds, NSEC_PER_SEC )];
}
/**
 * 取得当前播放时间
 *
 */
- (Float64)currentTime {
    return CMTimeGetSeconds([self.abuPlayer currentTime]);
}
/**
 * 取得媒体总时长
 *
 */
- (Float64)totalTime {
    return CMTimeGetSeconds(self.abuPlayerItem.duration );
}

#pragma mark - 懒加载
- (void)setUrl:(NSString *)Url{
    _Url = Url;
    if (isFirstLoad) {
        if (!isHiddenBottomView) {
            self.bottomMenuView.hidden = YES;
            isHiddenBottomView = YES;
        }
        if (isPlaying) {
            [self.abuPlayer pause];
            [self.playOrPauseBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
            isPlaying = NO;
        }
        [self setUserInteractionEnabled:NO];
        [self.loadingView startAnimating];
    }
    [self initPlayer];
    if (!isFirstLoad) {
        [self addToolView];
        isFirstLoad = YES;
    }
}

- (UIView *)bottomMenuView{
    if (_bottomMenuView == nil) {
        _bottomMenuView = [[UIView alloc] init];
        //        _bottomMenuView.backgroundColor = [UIColor colorWithRed:50.0/255.0 green:50.0/255.0 blue:50.0/255.0 alpha:1.0];
        _bottomMenuView.backgroundColor = [UIColor clearColor];
        _bottomMenuView.hidden = YES;
        isHiddenBottomView = YES;
    }
    return _bottomMenuView;
}

- (UIButton *)playOrPauseBtn{
    if (_playOrPauseBtn == nil) {
        _playOrPauseBtn = [[UIButton alloc] init];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
        [_playOrPauseBtn addTarget:self action:@selector(playOrPauseAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playOrPauseBtn;
}

- (UIButton *)nextPlayerBtn{
    if (_nextPlayerBtn == nil) {
        _nextPlayerBtn = [[UIButton alloc] init];
        [_nextPlayerBtn setImage:[UIImage imageNamed:@"button_forward"] forState:UIControlStateNormal];
        [_nextPlayerBtn addTarget:self action:@selector(nextPlayerAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _nextPlayerBtn;
}

- (UIButton *)fullOrSmallBtn{
    if (_fullOrSmallBtn == nil) {
        _fullOrSmallBtn = [[UIButton alloc] init];
        [_fullOrSmallBtn setImage:[UIImage imageNamed:@"big"] forState:UIControlStateNormal];
        isFullScreen = NO;
        [_fullOrSmallBtn addTarget:self action:@selector(fullOrSmallAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullOrSmallBtn;
}

- (UILabel *)timeLabel{
    if (_timeLabel == nil) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textColor = [UIColor whiteColor];
        _timeLabel.font = [UIFont systemFontOfSize:11.0];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.text = @"00:00:00/00:00:00";
    }
    return _timeLabel;
}

- (UIProgressView *)loadProgressView{
    if (_loadProgressView == nil) {
        _loadProgressView = [[UIProgressView alloc] init];
    }
    return _loadProgressView;
}

- (UISlider *)playSlider{
    if (_playSlider == nil) {
        _playSlider = [[UISlider alloc] init];
        _playSlider.minimumValue = 0.0;
        
        UIGraphicsBeginImageContextWithOptions((CGSize){1,1}, NO, 0.0f);
        UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.playSlider setThumbImage:[UIImage imageNamed:@"scrubber_thumb"] forState:UIControlStateNormal];
        [self.playSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
        [self.playSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
        
        [_playSlider addTarget:self action:@selector(playSliderValueChanging:) forControlEvents:UIControlEventValueChanged];
        [_playSlider addTarget:self action:@selector(playSliderValueDidChanged:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playSlider;
}

- (UIActivityIndicatorView *)loadingView{
    if (_loadingView == nil) {
        _loadingView = [[UIActivityIndicatorView alloc] init];
        [_loadingView startAnimating];
    }
    return _loadingView;
}

- (MPVolumeView *)volumeView {
    if (_volumeView == nil) {
        _volumeView  = [[MPVolumeView alloc] init];
        [_volumeView sizeToFit];
        for (UIView *view in [_volumeView subviews]){
            if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
                self.volumeViewSlider = (UISlider*)view;
                break;
            }
        }
    }
    return _volumeView;
}

- (TapGesView *)gesView{
    if (_gesView == nil) {
        //添加自定义的Button到视频画面上
        _gesView = [[TapGesView alloc] initWithFrame:playerFrame];
        _gesView.tag = 1000;
        _gesView.tapDelegate = self;
    }
    return _gesView;
}

//布局
- (void)layoutSubviews{
    
    self.bottomMenuView.frame = CGRectMake(0, self.height-40, self.width, 40);
    self.playOrPauseBtn.frame = CGRectMake(self.bottomMenuView.left+5, 8, 36, 23);
    if (isFullScreen) {
        self.nextPlayerBtn.frame = CGRectMake(self.playOrPauseBtn.right, 5, 30, 30);
        self.bottomMenuView.frame = CGRectMake(0, self.height-40, self.width, 40);
        self.gesView.frame = self.window.bounds;
        self.volumeView.frame = CGRectMake(0, 0, self.frame.size.height, self.frame.size.height * 9.0 / 16.0);
    }else{
        self.nextPlayerBtn.frame = CGRectMake(self.playOrPauseBtn.right+5, 5, 0, 0);
        self.gesView.frame = CGRectMake(0, 0, playerFrame.size.width, playerFrame.size.height);
        self.volumeView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.width * 9.0 / 16.0);
    }
    self.fullOrSmallBtn.frame = CGRectMake(self.bottomMenuView.width-35, 0, 35, self.bottomMenuView.height);
    self.timeLabel.frame = CGRectMake(self.fullOrSmallBtn.left-108, 10, 108, 20);
    self.loadProgressView.frame = CGRectMake(self.playOrPauseBtn.right+self.nextPlayerBtn.width+7, 20,self.timeLabel.left-self.playOrPauseBtn.right-self.nextPlayerBtn.width-14, 31);
    self.playSlider.frame = CGRectMake(self.playOrPauseBtn.right+self.nextPlayerBtn.width+5, 5, self.loadProgressView.width+4, 31);
    
    self.loadingView.frame = CGRectMake(self.gesView.centerX, self.gesView.centerY-20, 20, 20);
}

- (void)dealloc{
    [self.abuPlayerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.abuPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.link removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.abuPlayer removeTimeObserver:self.playbackTimeObserver];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

@end
