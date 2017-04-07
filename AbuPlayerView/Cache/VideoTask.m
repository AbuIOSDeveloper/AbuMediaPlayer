//
//  VideoTask.m
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import "VideoTask.h"



@interface VideoTask()<NSURLConnectionDataDelegate, AVAssetResourceLoaderDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableArray  *taskArr;
@property (nonatomic, assign) BOOL            once;
@property (nonatomic, strong) NSFileHandle    *fileHandle;
@property (nonatomic, strong) NSString        *tempPath;

@end

@implementation VideoTask

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setMediaPath];
    }
    return self;
}

- (void)setMediaPath
{
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *tempMV =  [document stringByAppendingPathComponent:Player];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempMV]) {
        _tempPath = [tempMV stringByAppendingPathComponent:@"temp.mp4"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:_tempPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:nil];
            [[NSFileManager defaultManager] createFileAtPath:_tempPath contents:nil attributes:nil];
        }else{
            [[NSFileManager defaultManager] createFileAtPath:_tempPath contents:nil attributes:nil];
        }
        
    } else {
        [[NSFileManager defaultManager] createDirectoryAtPath:tempMV withIntermediateDirectories:YES attributes:nil error:nil];
        _tempPath= [tempMV stringByAppendingPathComponent:@"temp.mp4"];
        [[NSFileManager defaultManager] createFileAtPath:_tempPath contents:nil attributes:nil];
    }
}

- (void)mediaUrl:(NSURL *)url offset:(NSUInteger)offset
{
    _url = url;
    _offset = offset;
    //假如发出第二次请求，则移除第一次请求的数据
    if (self.taskArr.count >= 1) {
        [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:nil];
        [[NSFileManager defaultManager] createFileAtPath:_tempPath contents:nil attributes:nil];
    }
    //计算下载起始
    _downLoadingOffset = 0;
    
    NSURLComponents * urlCompontents = [[NSURLComponents alloc]initWithURL:url resolvingAgainstBaseURL:NO];
    urlCompontents.scheme = @"http";
    //请求的最大值为20.0s
    NSMutableURLRequest * mutableRequest = [NSMutableURLRequest requestWithURL:[urlCompontents URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    //数据拼接
    if (offset > 0 && self.videoLength > 0) {
        [mutableRequest addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)offset, (unsigned long)self.videoLength - 1] forHTTPHeaderField:@"Range"];
    }
    
    [self.connection cancel];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:mutableRequest delegate:self startImmediately:NO];
    
    [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
    [self.connection start];
}

- (void)cancel
{
    [self.connection cancel];
    
}

- (void)continueLoading
{
    _once = YES;
    NSURLComponents *actualURLComponents = [[NSURLComponents alloc] initWithURL:_url resolvingAgainstBaseURL:NO];
    actualURLComponents.scheme = @"http";
    
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[actualURLComponents URL] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:20.0];
    
    [mutableRequest addValue:[NSString stringWithFormat:@"bytes=%ld-%ld",(unsigned long)_downLoadingOffset, (unsigned long)self.videoLength - 1] forHTTPHeaderField:@"Range"];
    
    
    [self.connection cancel];
    self.connection = [[NSURLConnection alloc] initWithRequest:mutableRequest delegate:self startImmediately:NO];
    [self.connection setDelegateQueue:[NSOperationQueue mainQueue]];
    [self.connection start];
}

- (void)clearData
{
    [self.connection cancel];
    //移除文件
    [[NSFileManager defaultManager] removeItemAtPath:_tempPath error:nil];
    
}

#pragma mark -  NSURLConnection Delegate Methods
//开始相应接收数据
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    _isFinishLoad = NO;
    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
    
    NSDictionary * responseDic = (NSDictionary *)[httpResponse allHeaderFields];
    
    //内容
    NSString * content = [responseDic objectForKey:@"Content-Range"];
    //分割
    NSArray * contentArray = [content componentsSeparatedByString:@"/"];
    //获取长度
    NSString * length = [contentArray lastObject];
    
    NSUInteger videoLength;
    
    if ([length integerValue] == 0) {
         videoLength = (NSUInteger)httpResponse.expectedContentLength;
    }
    else
    {
        videoLength =  [length integerValue];
    }
    
    self.videoLength = videoLength;
    self.mimeType = @"video/mp4";
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(task:didReceiveVideoLength:mimeType:)]) {
        [self.delegate task:self didReceiveVideoLength:self.videoLength mimeType:self.mimeType];
    }
    
    [self.taskArr addObject:connection];
    
    self.fileHandle = [NSFileHandle fileHandleForWritingAtPath:_tempPath];
}

//接收数据

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.fileHandle seekToEndOfFile];
    
    [self.fileHandle writeData:data];
    
    _downLoadingOffset += data.length;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(receiveVideoDataWithTask:)]) {
        [self.delegate receiveVideoDataWithTask:self];
    }
}

//下载完成
-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.taskArr.count < 2) {
        _isFinishLoad = YES;
        //这里自己写需要保存数据的路径
        NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *mediaPath =  [document stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/%@",Player,self.mediaPath]];
        
        BOOL isSuccess = [[NSFileManager defaultManager] copyItemAtPath:_tempPath toPath:mediaPath error:nil];
        if (isSuccess) {
            
        }else{
            
        }
        NSLog(@"缓存成功----%@",mediaPath);
    }
}
//下载失败
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (error.code == -1001 && !_once) {      //网络超时，重连一次
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self continueLoading];
        });
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(failLoadingWithTask:WithError:)]) {
        [self.delegate failLoadingWithTask:self WithError:error.code];
    }
    if (error.code == -1009) {
        //        NSLog(@"无网络连接");
    }
}

- (NSMutableArray *)taskArr
{
    if (!_taskArr) {
        _taskArr = [NSMutableArray array];
    }
    return _taskArr;
}

@end
