//
//  UIView+Extension.m
//  XiangYi
//
//  Created by mac on 16/12/29.
//  Copyright © 2016年 阿布. All rights reserved.
//

#import "UIView+Extension.h"

@implementation UIView (Extension)

- (CGFloat)left {
    return self.frame.origin.x;
}

- (void)setLeft:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (CGFloat)top {
    return self.frame.origin.y;
}

- (void)setTop:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (CGFloat)right {
    return self.frame.origin.x + self.frame.size.width;
}

- (void)setRight:(CGFloat)right {
    CGRect frame = self.frame;
    frame.origin.x = right - frame.size.width;
    self.frame = frame;
}

- (CGFloat)bottom {
    return self.frame.origin.y + self.frame.size.height;
}

- (void)setBottom:(CGFloat)bottom {
    CGRect frame = self.frame;
    frame.origin.y = bottom - frame.size.height;
    self.frame = frame;
}

- (CGPoint)leftTop {
    return CGPointMake(self.left, self.top);
}

- (void)setLeftTop:(CGPoint)leftTop {
    self.left = leftTop.x;
    self.top = leftTop.y;
}

- (CGPoint)leftBottom {
    return CGPointMake(self.left, self.bottom);
}

- (void)setLeftBottom:(CGPoint)leftBottom {
    self.left = leftBottom.x;
    self.bottom = leftBottom.y;
}

- (CGPoint)rightTop {
    return CGPointMake(self.right, self.top);
}

- (void)setRightTop:(CGPoint)rightTop {
    self.right = rightTop.x;
    self.top = rightTop.y;
}

- (CGPoint)rightBottom {
    return CGPointMake(self.right, self.bottom);
}

- (void)setRightBottom:(CGPoint)rightBottom {
    self.right = rightBottom.x;
    self.bottom = rightBottom.y;
}

- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)centerX {
    self.center = CGPointMake(centerX, self.center.y);
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)centerY {
    self.center = CGPointMake(self.center.x, centerY);
}

- (CGFloat)width {
    return self.frame.size.width;
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)height {
    return self.frame.size.height;
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGPoint)origin {
    return self.frame.origin;
}

- (void)setOrigin:(CGPoint)origin {
    CGRect frame = self.frame;
    frame.origin = origin;
    self.frame = frame;
}

- (CGSize)size {
    return self.frame.size;
}

- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}
@end
