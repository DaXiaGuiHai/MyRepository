//
//  VirtualButton.m
//  DemoSuspendBtn
//
//  Created by zhang on 2017/5/19.
//  Copyright © 2017年 爱贝. All rights reserved.
//

#import "VirtualButton.h"
#define AUTODOCKING_ANIMATE_DURATION    0.2f
#define SPACE_SIDE                      20.0f
#define SCREEN_WIDTH    CGRectGetWidth([VirtualButton screenBounds])
#define SCREEN_HEIGHT   CGRectGetHeight([VirtualButton screenBounds])

@interface VirtualButton ()

@property(nonatomic,assign)BOOL isDragging;
@property(nonatomic,assign)BOOL hadDragDone;
@property(nonatomic,assign)CGPoint beginLocation;

@property(nonatomic,assign)CGFloat percentX;
@property(nonatomic,assign)CGFloat percentY;

@end

@implementation VirtualButton

- (id)initInKeyWindowWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.percentX = frame.origin.x / (SCREEN_WIDTH - frame.size.width);
    self.percentY = frame.origin.y / (SCREEN_HEIGHT - frame.size.height);
    if (self) {
        [self performSelector:@selector(addButtonToKeyWindow) withObject:nil afterDelay:0.f];
        [self defaultSetting];
    }
    return self;
}

- (void)defaultSetting {
    [self.layer setCornerRadius:self.frame.size.height / 2];
    [self.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.layer setBorderWidth:0.5];
    [self.layer setMasksToBounds:YES];
    
    [self registerKeyboardNotification];
}

- (void)dealloc
{
    [self removeKeyboardNotification];
}

- (void)addButtonToKeyWindow {
    UIWindow *mainWindow = nil;
    mainWindow = [UIApplication sharedApplication].keyWindow;
    if (mainWindow == nil) {
        NSString *textWin = @"<UITextEffectsWindow:";
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for (UIWindow *window in [windows reverseObjectEnumerator])
        {
            BOOL windowIsVisible = (!window.hidden && window.alpha > 0);
            BOOL windowIsClass = (![[window description] hasPrefix:textWin]);
            BOOL windowOnMainScreen = (window.screen == UIScreen.mainScreen);
            if (windowOnMainScreen && windowIsVisible && windowIsClass) {
                mainWindow = window;
            }
            
            BOOL windowIsKeyType = [window isKeyWindow];
            if (windowOnMainScreen && windowIsVisible && windowIsKeyType) {
                mainWindow = window;
                break;
            }
        }
    }
    [mainWindow addSubview:self];
}

#pragma mark - Blocks
#pragma mark Touch Blocks
- (void)setTapBlock:(void (^)(VirtualButton *))tapBlock {
    _tapBlock = tapBlock;
    
    if (_tapBlock) {
        [self addTarget:self action:@selector(buttonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
}

#pragma mark - Touch
- (void)buttonTouched {
    [self performSelector:@selector(executeButtonTouchedBlock) withObject:nil afterDelay:0];
}

- (void)executeButtonTouchedBlock {
    if (self.tapBlock && !self.isDragging && !self.hadDragDone) {
        self.tapBlock(self);
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    self.isDragging = NO;
    self.hadDragDone = NO;
    [super touchesBegan:touches withEvent:event];
    self.beginLocation = [[touches anyObject] locationInView:self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    self.isDragging = YES;
    
    UITouch *touch = [touches anyObject];
    CGPoint currentLocation = [touch locationInView:self];
    
    float offsetX = currentLocation.x - self.beginLocation.x;
    float offsetY = currentLocation.y - self.beginLocation.y;
    self.center = CGPointMake(self.center.x + offsetX, self.center.y + offsetY);
    
    CGRect superviewFrame = self.superview.frame;
    CGRect frame = self.frame;
    CGFloat keyboardHeight = self.visibleKeyboardHeight;
    CGFloat leftLimitX = frame.size.width / 2;
    CGFloat rightLimitX = superviewFrame.size.width - leftLimitX;
    CGFloat topLimitY = frame.size.height / 2;
    CGFloat bottomLimitY = superviewFrame.size.height - topLimitY - keyboardHeight;
    
    if (self.center.x > rightLimitX) {
        self.center = CGPointMake(rightLimitX, self.center.y);
    }else if (self.center.x <= leftLimitX) {
        self.center = CGPointMake(leftLimitX, self.center.y);
    }
    
    if (self.center.y > bottomLimitY) {
        self.center = CGPointMake(self.center.x, bottomLimitY);
    }else if (self.center.y <= topLimitY){
        self.center = CGPointMake(self.center.x, topLimitY);
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded: touches withEvent: event];
    
    UITouch *touch = [touches anyObject];
    CGPoint currentLocation = [touch locationInView:self];
    float offsetX = currentLocation.x - self.beginLocation.x;
    float offsetY = currentLocation.y - self.beginLocation.y;
    if (offsetX != 0 || offsetY != 0) self.hadDragDone = YES;
    
    if (self.isDragging) {
        NSDictionary *dic = [self getBtnPosition:YES];
        CGFloat centerx = [dic[@"centerx"] floatValue];
        CGFloat centery = [dic[@"centery"] floatValue];
        
        [UIView animateWithDuration:AUTODOCKING_ANIMATE_DURATION animations:^{
            self.center = CGPointMake(centerx, centery);
        } completion:nil];
        
        CGRect superviewFrame = self.superview.frame;
        self.percentX = self.frame.origin.x / (superviewFrame.size.width - self.frame.size.width);
        self.percentY = self.frame.origin.y / (superviewFrame.size.height - self.frame.size.height);
    }
    
    self.isDragging = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.isDragging = NO;
    [super touchesCancelled:touches withEvent:event];
}


#pragma mark - remove
+ (void)removeAllFromKeyWindow {
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in [windows reverseObjectEnumerator])
    {
        for (id view in [window subviews]) {
            if ([view isKindOfClass:[VirtualButton class]]) {
                [view removeFromSuperview];
            }
        }
    }
}


#pragma mark - Keyboard Method Public Method
- (void)registerKeyboardNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationWillChange:)
                                                 name:UIApplicationWillChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deviceOrientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyBoardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyBoardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)removeKeyboardNotification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillChangeStatusBarOrientationNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)deviceOrientationWillChange:(NSNotification *)notification
{
    if ([self.superview isKindOfClass:[UIWindow class]])
    {
        [UIView animateWithDuration:0.1 animations:^{
            self.alpha = 0.0f;
        } completion:nil];
    }
}

- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    if ([self.superview isKindOfClass:[UIWindow class]])
    {
        [self setTransformForCurrentOrientation:notification];
    }
}


- (void)keyBoardWillShow:(NSNotification *)notification
{
    //获取键盘的高度
    NSDictionary *dic = [self getKeyBoardHeight:notification];
    CGFloat keyboardHeight = [dic[@"keyHeight"] floatValue];
    double animationDuration = [dic[@"animationDuration"] doubleValue];
    
    CGRect superviewFrame = self.superview.frame;
    
    CGFloat bottom = CGRectGetMaxY(self.frame);
    if (bottom < (superviewFrame.size.height-keyboardHeight)) {
        return;
    }
    
    [UIView animateWithDuration:animationDuration animations:^{
        CGRect rect = self.frame;
        rect.origin.y = superviewFrame.size.height - keyboardHeight - rect.size.height;
        self.frame = rect;
    }];
}

- (void)keyBoardWillHide:(NSNotification *)notification
{
    //获取键盘的高度
    NSDictionary *dic = [self getKeyBoardHeight:notification];
    double animationDuration = [dic[@"animationDuration"] doubleValue];
    
    CGRect superviewFrame = self.superview.frame;
    CGFloat x = self.percentX * (superviewFrame.size.width - self.frame.size.width);
    CGFloat y = self.percentY * (superviewFrame.size.height - self.frame.size.height);
    self.frame = CGRectMake(x, y, self.bounds.size.width, self.bounds.size.height);
    
    [UIView animateWithDuration:animationDuration animations:^{
        self.frame = CGRectMake(x, y, self.bounds.size.width, self.bounds.size.height);
    }];
}

- (NSDictionary*)getKeyBoardHeight:(NSNotification *)notification
{
    BOOL ignoreOrientation = NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
    SEL selector = @selector(operatingSystemVersion);
    if ([[NSProcessInfo processInfo] respondsToSelector:selector]) {
        ignoreOrientation = YES;
    }
#endif
    
    UIInterfaceOrientation orientation;
    orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    //获取键盘的高度
    CGFloat keyboardHeight = 0.0f;
    double animationDuration = 0.0;
    if (notification != nil)
    {
        NSDictionary *keyboardInfo = [notification userInfo];
        id boardValue = keyboardInfo[UIKeyboardFrameEndUserInfoKey];
        CGRect keyboardFrame = [boardValue CGRectValue];
        boardValue = keyboardInfo[UIKeyboardAnimationDurationUserInfoKey];
        animationDuration = [boardValue doubleValue];
        if (notification.name == UIKeyboardWillShowNotification ||
            notification.name == UIKeyboardDidShowNotification)
        {
            if ((ignoreOrientation == YES)||
                UIInterfaceOrientationIsPortrait(orientation))
            {
                keyboardHeight = CGRectGetHeight(keyboardFrame);
            }
            else
            {
                keyboardHeight = CGRectGetWidth(keyboardFrame);
            }
        }
    }
    NSDictionary *dic = @{@"keyHeight":[NSNumber numberWithFloat:keyboardHeight],
                          @"animationDuration":[NSNumber numberWithDouble:animationDuration]};
    
    return dic;
}

- (NSDictionary*)getBtnPosition:(BOOL)isHaveKeyboardHeight
{
    CGFloat keyboardHeight = 0;
    if (isHaveKeyboardHeight) keyboardHeight = self.visibleKeyboardHeight;
    
    CGRect superviewFrame = self.superview.frame;
    CGRect frame = self.frame;
    
    CGFloat leftLimitX = frame.size.width / 2;
    CGFloat rightLimitX = superviewFrame.size.width - leftLimitX;
    CGFloat middleX = superviewFrame.size.width / 2;
    CGFloat middleY = (superviewFrame.size.height - keyboardHeight) / 2;
    CGFloat topLimitY = frame.size.height / 2;
    CGFloat bottomLimitY = superviewFrame.size.height - topLimitY - keyboardHeight;
    
    CGFloat centerx = leftLimitX,centery = topLimitY;
    if (self.center.x < middleX){
        if (self.center.y < middleY){
            if (self.center.x < self.center.y){
                centerx = leftLimitX;
                centery = self.center.y;
            }else{
                centerx = self.center.x;
                centery = topLimitY;
            }
        }else{
            CGFloat bottomSpace = superviewFrame.size.height - keyboardHeight - self.center.y;
            if (self.center.x < bottomSpace){
                centerx = leftLimitX;
                centery = self.center.y;
            }else{
                centerx = self.center.x;
                centery = bottomLimitY;
                if (keyboardHeight) centery = self.center.y;
            }
            
            if (keyboardHeight) centerx = leftLimitX;
        }
    }else{
        if (self.center.y < middleY){
            CGFloat rightSpace = superviewFrame.size.width - self.center.x;
            if (rightSpace < self.center.y){
                centerx = rightLimitX;
                centery = self.center.y;
            }else{
                centerx = self.center.x;
                centery = topLimitY;
            }
        }else{
            CGFloat rightSpace = superviewFrame.size.width - self.center.x;
            CGFloat bottomSpace = superviewFrame.size.height - keyboardHeight - self.center.y;
            if (rightSpace < bottomSpace){
                centerx = rightLimitX;
                centery = self.center.y;
            }else{
                centerx = self.center.x;
                centery = bottomLimitY;
                if (keyboardHeight) centery = self.center.y;
            }
            if (keyboardHeight) centerx = rightLimitX;
        }
    }
    
    if (centerx - leftLimitX <= SPACE_SIDE)   centerx = leftLimitX;
    if (rightLimitX - centerx <= SPACE_SIDE)  centerx = rightLimitX;
    if (centery - topLimitY <= SPACE_SIDE)    centery = topLimitY;
    if (bottomLimitY - centery <= SPACE_SIDE && keyboardHeight == 0) centery = bottomLimitY;
    
    NSDictionary *dic = @{@"centerx":[NSNumber numberWithFloat:centerx],
                          @"centery":[NSNumber numberWithFloat:centery]};
    return dic;
}

- (void)setTransformForCurrentOrientation:(NSNotification*)notification {
    CGRect superviewFrame = self.superview.frame;
    CGFloat x = self.percentX * (superviewFrame.size.width - self.frame.size.width);
    CGFloat y = self.percentY * (superviewFrame.size.height - self.frame.size.height);
    self.frame = CGRectMake(x, y, self.bounds.size.width, self.bounds.size.height);
    
    NSDictionary *dic = [self getBtnPosition:NO];
    CGFloat centerx = [dic[@"centerx"] floatValue];
    CGFloat centery = [dic[@"centery"] floatValue];
    self.center = CGPointMake(centerx, centery);
    
    [UIView animateWithDuration:0.5 delay:0.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.alpha = 1.0f;
    } completion:nil];
    
}

- (CGFloat)visibleKeyboardHeight
{
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows])
    {
        if(![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    for (__strong UIView *keyboard in [keyboardWindow subviews])
    {
        if ([[keyboard description] hasPrefix:@"<UIPeripheralHostView:"]
            || [[keyboard description] hasPrefix:@"<UIKeyboard:"])
        {
            return CGRectGetHeight(keyboard.bounds);
        }
        else if ([[keyboard description ] hasPrefix:@"<UIInputSetContainerView:"])
        {
            for (__strong UIView *keyboardSubview in [keyboard subviews])
            {
                if ([[keyboardSubview description] hasPrefix:@"<UIInputSetHostView:"])
                {
                    return CGRectGetHeight(keyboardSubview.bounds);
                }
            }
        }
    }
    return 0;
}

+ (CGRect)screenBounds
{
    CGFloat screenWidth = CGRectGetWidth([[UIScreen mainScreen] bounds]);
    CGFloat screenHeight = CGRectGetHeight([[UIScreen mainScreen] bounds]);
    UIApplication *application = nil;
    UIInterfaceOrientation interfaceOrientation;
    application = [UIApplication sharedApplication];
    interfaceOrientation = [application statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation) && screenWidth < screenHeight) {
        CGFloat tmp = screenWidth;
        screenWidth = screenHeight;
        screenHeight = tmp;
    }
    
    return CGRectMake(0, 0, screenWidth, screenHeight);
}

@end
