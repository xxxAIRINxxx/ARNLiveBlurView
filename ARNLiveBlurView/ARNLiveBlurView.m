//
//  ARNLiveBlurView.m
//  ARNLiveBlurView
//
//  Created by Airin on 2014/05/22.
//  Copyright (c) 2014 Airin. All rights reserved.
//

#import "ARNLiveBlurView.h"

@import Accelerate;

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

static NSString *const ARNBlurViewImageKey       = @"ARNBlurViewImageKey";
static NSString *const ARNObservingScrollViewKey = @"contentOffset";

@interface ARNLiveBlurView ()

@property (nonatomic, weak) UIScrollView               *observingScrollView;
@property (nonatomic, copy) ARNObservingScrollViewBlock observingBlock;
@property (nonatomic, strong) dispatch_queue_t          serialQueue;

@end

@implementation ARNLiveBlurView

- (void)dealloc
{
    if (_observingScrollView) {
        [_observingScrollView removeObserver:self forKeyPath:ARNObservingScrollViewKey];
    }
}

- (void)commonInit
{
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds   = YES;
    
    self.blurRadius      = 20;
    self.saturationDelta = 1.5f;
    self.tintColor       = nil;
    self.viewToBlur      = nil;
    self.serialQueue     = dispatch_queue_create("ARNLiveBlurViewQueue", DISPATCH_QUEUE_SERIAL);
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (!(self = [super initWithFrame:frame])) { return nil; }
    
    [self commonInit];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (!(self = [super initWithCoder:aDecoder])) { return nil; }
    
    [self commonInit];
    
    return self;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:[UIImage imageWithCGImage:(CGImageRef)self.layer.contents] forKey:ARNBlurViewImageKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    self.layer.contents = (__bridge id)[[coder decodeObjectForKey:ARNBlurViewImageKey] CGImage];
}

- (UIView *)viewToBlur
{
    if (_viewToBlur) {
        return _viewToBlur;
    }
    return self.superview;
}

// -------------------------------------------------------------------------------------------------------------------------------//
#pragma mark - Blur Effect

- (UIImage *)captureImageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0f);
    // TODO : こっち使うと同じ階層の前方に居るTableViewとか表示されなくなる....
    //[view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *captureViewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return captureViewImage;
}

- (void)updateBlur
{
    UIImage *captureImage = [self captureImageWithView:self.viewToBlur];
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(self.serialQueue, ^{
        if (!weakSelf) { return; }
        
        NSData *imageData = UIImageJPEGRepresentation(captureImage, 0.01);
        UIImage *lowQualityImage = [UIImage imageWithData:imageData];
        
        CGRect translationRect      = [weakSelf convertRect:weakSelf.bounds toView:weakSelf.viewToBlur];
        CGRect scaledSuperviewFrame = CGRectApplyAffineTransform(translationRect, CGAffineTransformMakeScale([UIScreen mainScreen].scale, [UIScreen mainScreen].scale));
        CGImageRef croppedImageRef  = CGImageCreateWithImageInRect(lowQualityImage.CGImage, scaledSuperviewFrame);
        UIImage   *croppedImage     = [UIImage imageWithCGImage:croppedImageRef scale:captureImage.scale orientation:captureImage.imageOrientation];
        
        UIImage *blurredImage = [weakSelf applyBlurOnImage:croppedImage blurRadius:weakSelf.blurRadius tintColor:weakSelf.tintColor saturationDeltaFactor:self.saturationDelta];
        CGImageRelease(croppedImageRef);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.layer.contents = nil;
            weakSelf.layer.contents = (__bridge id)blurredImage.CGImage;
        });
    });
}

- (void)didMoveToSuperview
{
    if (self.superview) {
        [self updateBlur];
    }
}

// @see : UIImage+ImageEffects

- (UIImage *)applyBlurOnImage:(UIImage *)imageToBlur blurRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor
{
    if (imageToBlur.size.width < 1 || imageToBlur.size.height < 1) { return nil; }
    
    CGRect imageRect = { CGPointZero, imageToBlur.size };
    
    BOOL hasBlur             = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange) {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -imageToBlur.size.height);
        CGContextDrawImage(effectInContext, imageRect, imageToBlur.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(imageToBlur.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef  effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur) {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat    inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius      = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1) {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (CGFloat)radius, (CGFloat)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, (CGFloat)radius, (CGFloat)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (CGFloat)radius, (CGFloat)radius, 0, kvImageEdgeExtend);
        }
        BOOL effectImageBuffersAreSwapped = NO;
        if (hasSaturationChange) {
            CGFloat       s                               = saturationDeltaFactor;
            CGFloat       floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s, 0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s, 0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s, 0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                   0,                    0,                    1,
            };
            const int32_t divisor    = 256;
            NSUInteger    matrixSize = sizeof(floatingPointSaturationMatrix) / sizeof(floatingPointSaturationMatrix[0]);
            int16_t       saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i) {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            if (hasBlur) {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            } else   {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        if (!effectImageBuffersAreSwapped) {
            imageToBlur = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped) {
            imageToBlur = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
    }
    
    UIGraphicsBeginImageContextWithOptions(imageToBlur.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -imageToBlur.size.height);
    
    CGContextDrawImage(outputContext, imageRect, imageToBlur.CGImage);
    
    if (hasBlur) {
        CGContextSaveGState(outputContext);
        CGContextDrawImage(outputContext, imageRect, imageToBlur.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    if (tintColor) {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

// -------------------------------------------------------------------------------------------------------------------------------//
#pragma mark - Observe ScrollView

- (void)setObservingScrollView:(UIScrollView *)observingScrollView observingBlock:(ARNObservingScrollViewBlock)observingBlock
{
    if (!observingScrollView) { return; }
    
    if (self.observingScrollView) {
        [self.observingScrollView removeObserver:self forKeyPath:ARNObservingScrollViewKey];
        self.observingBlock = nil;
    }
    
    self.observingScrollView = observingScrollView;
    self.observingBlock      = observingBlock;
    [self.observingScrollView addObserver:self forKeyPath:ARNObservingScrollViewKey options:0 context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (self.observingBlock && self.observingScrollView) {
        self.observingBlock(self, self.observingScrollView);
    }
}

@end
