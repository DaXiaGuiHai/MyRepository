//
//  VirtualButton.m
//  DemoSuspendBtn
//
//  Created by zhang on 2017/5/19.
//  Copyright © 2017年 爱贝. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VirtualButton : UIButton

@property (nonatomic, copy) void(^tapBlock)(VirtualButton *button);

- (id)initInKeyWindowWithFrame:(CGRect)frame;

+ (void)removeAllFromKeyWindow;

@end
