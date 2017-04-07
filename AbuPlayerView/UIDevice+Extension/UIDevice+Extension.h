//
//  UIDevice+Extension.h
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (Extension )

/**
 *  强制旋转设备
 *  @orientation  旋转方向
 */
+ (void)middfyOrientation:(UIInterfaceOrientation)orientation;

@end
