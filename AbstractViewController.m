//
//  AbstractViewController.m
//  plugin slideshow
//
//  Created by Sébastien Vitard on 23/12/2015.
//  Copyright © 2015 Cobaltians. All rights reserved.
//

#import "AbstractViewController.h"

@interface AbstractViewController () {
    NSString *pageName;
}
@end

@implementation AbstractViewController

static __weak id<MenuEnableDelegate> menuEnableDelegate;

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark LIFECYCLE

////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];
    // set status bar text-color to white
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    // Do any additional setup after loading the view.
    [self setDelegate:self];
    [self configureBars];
    // basic bar setup
    if ([self respondsToSelector: @selector(setAutomaticallyAdjustsScrollViewInsets:)])
        self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbar.translucent = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark MENU ENABLE DELEGATE

////////////////////////////////////////////////////////////////////////////////////////////////////

+ (id<MenuEnableDelegate>)menuEnableDelegate {
    return menuEnableDelegate;
}

+ (void)setMenuEnableDelegate:(id<MenuEnableDelegate>)delegate {
    menuEnableDelegate = delegate;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark COBALT

////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)onUnhandledMessage:(NSDictionary *)message {
    NSLog(@"View Controller %@ received Cobalt message %@", NSStringFromClass([self class]), message);
    return false;
}

- (BOOL)onUnhandledEvent:(NSString *)event
                withData:(NSDictionary *)data
             andCallback:(NSString *)callback {
    NSLog(@"View Controller %@ received Cobalt event %@", NSStringFromClass([self class]), event);
    return false;
}

- (BOOL)onUnhandledCallback:(NSString *)callback
                   withData:(NSDictionary *)data {
    NSLog(@"Received callback %@", callback);
    return false;
}

@end
