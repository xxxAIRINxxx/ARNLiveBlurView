//
//  ARNLiveBlurView.h
//  ARNLiveBlurView
//
//  Created by Airin on 2014/05/22.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ARNLiveBlurView;

typedef void (^ARNObservingScrollViewBlock) (ARNLiveBlurView *blurredView, UIScrollView *observingView);

@interface ARNLiveBlurView : UIView

@property (nonatomic, assign) CGFloat blurRadius;
@property (nonatomic, assign) CGFloat saturationDelta;
@property (nonatomic, copy) UIColor  *tintColor;
@property (nonatomic, weak) UIView   *viewToBlur;

- (void)updateBlur;

- (void)setObservingScrollView:(UIScrollView *)observingScrollView observingBlock:(ARNObservingScrollViewBlock)observingBlock;

@end
