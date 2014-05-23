//
//  ALBFirstViewController.m
//  ARNLiveBlurViewDemo
//
//  Created by Airin on 2014/05/23.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import "ALBFirstViewController.h"
#import "ARNLiveBlurView.h"

@interface ALBFirstViewController ()

@end

@implementation ALBFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    backgroundView.frame = self.view.bounds;
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:backgroundView];
    
    ARNLiveBlurView *blurView = [[ARNLiveBlurView alloc] initWithFrame:CGRectMake(60, 100, 200, 200)];
    blurView.layer.cornerRadius = 100;
    [backgroundView addSubview:blurView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:blurView.bounds];
    label.text = @"Blur";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = NSTextAlignmentCenter;
    [blurView addSubview:label];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
