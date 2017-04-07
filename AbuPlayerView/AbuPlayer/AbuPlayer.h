//
//  AbuPlayer.h
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TapGesView;
@protocol AbuPlayDelegate <NSObject>

@optional
/**
 *  点击视频全屏按钮
 *
 *  @param flag YES：全屏，NO：不是全屏；
 */
- (void)didPlayerFullOrSmall:(BOOL)flag;
/**
 *  点击视屏播放按钮
 *
 *  @param flag flag YES：暂停，NO：播放；
 */
- (void)didPlayerPlayOrPause:(BOOL)flag;
/**
 *  点击下一个视屏按钮（全屏的时候才有）
 */
- (void)didNextPlayer;

@end
@interface AbuPlayer : UIView

@property (nonatomic, weak) id<AbuPlayDelegate>   delegate;
/**
 *  视屏URL
 */
@property (nonatomic, strong) NSString          * Url;
/**
 *  palyer暂停
 */
- (void)pause;
/**
 *  player开始
 */
- (void)play;
/**
 * 定位视频播放时间(根据上次存储的时间来定位播放)
 *
 * @param seconds 秒
 *
 *
 */
- (void)getTimeWithSeconds:(Float64)seconds;
/**
 * 获取当前播放时间
 *
 */
- (Float64)currentTime;
/**
 * 获取媒体总时长
 *
 */
- (Float64)totalTime;


/**
 *  如果想自定义底部菜单，可以移除写好的菜单；通过接口和代理来控制视屏；
 */
- (void)removePlayerBottomMenu;
/**
 *  添加菜单，添加到这个View上；
 */
@property (strong, nonatomic) TapGesView  * gesView;
/**
 *  添加,视屏view位置超出屏幕时，位置移到右下角；（慎用）
 */
- (void)addPlayerAutoMovie;
/**
 *  如果使用了addPlayerAutoMovie，就可以获得view最开始的位置
 */
@property (nonatomic, assign) CGRect        originalFrame;//初始位置
/**
 *  移到最开始的位置
 */
- (void)moviePlayeToOriginalPosition;

@end
