//
//  TapGesView.m
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import "TapGesView.h"

@interface TapGesView()
/**
 * 单机手势
 */
@property (nonatomic, strong) UITapGestureRecognizer * singleTap;

/**
 * 双击手势
 */
@property (nonatomic, strong) UITapGestureRecognizer * doubleTap;

@end

@implementation TapGesView


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setTap];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setTap];
    }
    return self;
}

- (void)setTap{
    [self addGestureRecognizer:self.singleTap];
    [self addGestureRecognizer:self.doubleTap];
}

#pragma mark ---------------------------------手势点击方法---------------------------------
//单机事件
- (void)singleTapClick:(UITapGestureRecognizer*)tap{
    [self tapDidClick:tap];
}
//双击事件
- (void)doubleTapClick:(UITapGestureRecognizer*)tap{
    [self tapDidClick:tap];
}

- (void)tapDidClick:(UITapGestureRecognizer*)tap
{
    if (self.tapDelegate && [self.tapDelegate respondsToSelector:@selector(tapGestureAction:)]) {
        [self.tapDelegate tapGestureAction:tap];
    }
}

#pragma mark ---------------------------------触摸事件------------------------------------
//开始触摸
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    CGPoint currentPoint = [self getTocuhPoint:touches];
    if (self.tapDelegate && [self.tapDelegate respondsToSelector:@selector(touchesBeganInPoint:)]) {
        [self.tapDelegate touchesBeganInPoint:currentPoint];
    }
}

//触摸结束
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    CGPoint currentPoint = [self getTocuhPoint:touches];
    if (self.tapDelegate && [self.tapDelegate respondsToSelector:@selector(touchesEndInPoint:)]) {
        [self.tapDelegate touchesEndInPoint:currentPoint];
    }
}

//移动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    CGPoint currentPoint = [self getTocuhPoint:touches];
    if (self.tapDelegate && [self.tapDelegate respondsToSelector:@selector(touchesMoveInPoint:)]) {
        [self.tapDelegate touchesMoveInPoint:currentPoint];
    }
}

//获取触摸的点
- (CGPoint)getTocuhPoint:(NSSet<UITouch *> *)touches
{
    UITouch * touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self];
    return currentPoint;
}

#pragma mark ---------------------------------懒加载--------------------------------------
- (UITapGestureRecognizer *)singleTap
{
    if (!_singleTap) {
       _singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapClick:)];
        _singleTap.numberOfTapsRequired = 1;
        _singleTap.cancelsTouchesInView = NO;
    }
    return _singleTap;
}

- (UITapGestureRecognizer *)doubleTap
{
    if (!_doubleTap) {
        _doubleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapClick:)];
        _doubleTap.numberOfTapsRequired = 1;
        _doubleTap.cancelsTouchesInView = NO;
    }
    return _doubleTap;
}

@end
