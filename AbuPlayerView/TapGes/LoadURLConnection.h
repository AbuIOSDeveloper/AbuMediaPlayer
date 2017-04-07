//
//  LoadURLConnection.h
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoTask.h"

@class VideoTask;
@class LoadURLConnection;
@protocol LoadURLConnectionDelegate <NSObject>

@optional

- (void)loadURLConnection:(LoadURLConnection *)load finishLoadingWithTask:(VideoTask *)task;

- (void)loadURLConnection:(LoadURLConnection *)load failLoadingWithTask:(VideoTask *)task WithError:(NSInteger )errorCode;

@end

@interface LoadURLConnection : NSURLConnection <AVAssetResourceLoaderDelegate>

@property (nonatomic, weak) id<LoadURLConnectionDelegate>   delegate;

@property (nonatomic, strong) VideoTask                   * task;

@property (nonatomic, strong) NSString                    * mediaPath;

- (NSURL *)getSchemeVideoURL:(NSURL *)url;

@end
