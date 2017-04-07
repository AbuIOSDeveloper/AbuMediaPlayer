//
//  UIDevice+Extension.m
//  AbuPlayer
//
//  Created by 阿布 on 17/4/4.
//  Copyright © 2017年 阿布. All rights reserved.
//

#import "UIDevice+Extension.h"

@implementation UIDevice (Extension)

+(void)middfyOrientation:(UIInterfaceOrientation)orientation
{
    SEL selector = NSSelectorFromString(@"setOrientation:");
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self instanceMethodSignatureForSelector:selector]];
    [invocation setSelector:selector];
    [invocation setTarget:[self currentDevice]];
    int orienttationValue = orientation;
    [invocation setArgument:&orienttationValue atIndex:2];
    [invocation invoke];
}

@end
