//
//  TapGesView.h
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TapGesViewDelegate <NSObject>

@optional
/**
 * 开始触摸
 */
- (void)touchesBeganInPoint:(CGPoint)point;

/**
 * 结束触摸
 */
- (void)touchesEndInPoint:(CGPoint)point;

/**
 * 移动手指
 */
- (void)touchesMoveInPoint:(CGPoint)point;

/**
 *  单击时/双击时,判断tap的numberOfTapsRequired
 */
- (void)tapGestureAction:(UITapGestureRecognizer*)tap;

@end

@interface TapGesView : UIView

@property (nonatomic, weak) id<TapGesViewDelegate> tapDelegate;

@end
