//
//  ViewController.m
//  VirtualButtonDemo
//
//  Created by zhang on 2018/2/1.
//  Copyright © 2018年 QQ:1604973856. All rights reserved.
//

#import "ViewController.h"
#import "VirtualButton.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self loadVirtualButtonToWindow];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadVirtualButtonToWindow
{
    VirtualButton *avatar = [[VirtualButton alloc] initInKeyWindowWithFrame:CGRectMake(0, 100, 60, 60)];
//    [avatar setBackgroundImage:[UIImage imageNamed:@"avatar"] forState:UIControlStateNormal];
    avatar.backgroundColor = [UIColor blueColor];
    
    [avatar setTapBlock:^(VirtualButton *avatar) {
        NSLog(@"setTapBlock keyWindow ===  Tap!!! ===");
        
    }];
}

@end
