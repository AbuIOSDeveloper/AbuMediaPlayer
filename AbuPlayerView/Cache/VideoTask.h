//
//  VideoTask.h
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define Player @"player"

@class VideoTask;
@protocol VideoRequestTaskDelegate <NSObject>

@optional
/**
 * 接收数据
 */
- (void)task:(VideoTask *)task didReceiveVideoLength:(NSUInteger)ideoLength mimeType:(NSString *)mimeType;
- (void)receiveVideoDataWithTask:(VideoTask *)task;
/**
 * 完成Media加载
 */
- (void)finishLoadingWithTask:(VideoTask *)task;
/**
 * 下载数据失败
 */
- (void)failLoadingWithTask:(VideoTask *)task WithError:(NSInteger )errorCode;

@end

@interface VideoTask : NSObject
@property (nonatomic, strong) NSURL                         * url;//多媒体url
@property (nonatomic, assign) NSUInteger                      offset;//偏移量(下载量)
@property (nonatomic, assign) NSUInteger                      videoLength;//
@property (nonatomic, assign) NSUInteger                      downLoadingOffset;//下载的量
@property (nonatomic, strong) NSString                      * mimeType;//类型
@property (nonatomic, assign) BOOL                            isFinishLoad;// 是否完成下载
@property (nonatomic, strong) NSString                      * mediaPath;//多媒体路径

@property (nonatomic, weak)   id <VideoRequestTaskDelegate>   delegate;

/**
 根据url计算当前下载的起始位置

 @param url 多媒体链接
 @param offset 下载起始位置
 */
- (void)mediaUrl:(NSURL *)url offset:(NSUInteger)offset;
/**
 * 取消加载
 */
- (void)cancel;
/**
 * 继续加载
 */
- (void)continueLoading;
/**
 * 清理数据
 */
- (void)clearData;

@end
