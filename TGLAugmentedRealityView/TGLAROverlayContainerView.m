//
//  TGLAROverlayContainerView.m
//  TGLAugmentedRealityView
//
//  Created by Tim Gleue on 17.11.15.
//  Copyright (c) 2015 Tim Gleue ( http://gleue-interactive.com )
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "TGLAROverlayContainerView.h"

#import <GLKit/GLKVector2.h>

@implementation TGLAROverlayContainerView

- (instancetype)initWithFrame:(CGRect)frame {

    self = [super initWithFrame:frame];

    if (self) [self initContainer];

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];

    if (self) [self initContainer];

    return self;
}

- (void)initContainer {

    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.opaque = NO;

    [self addSubview:_contentView];
}

#pragma mark - Accessors

- (void)setOverlayViews:(NSArray<TGLARViewOverlay *> *)overlayViews {
    
    for (TGLARViewOverlay *view in self.overlayViews) {
        
        [view removeFromSuperview];
    }
    
    _overlayViews = overlayViews;
    
    [self setNeedsLayout];
}

- (void)setOverlayTransformation:(GLKMatrix4)overlayTransformation {
    
    _overlayTransformation = overlayTransformation;
    
    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews {

    [super layoutSubviews];

    CGRect bounds = self.bounds;
    CGSize offset = CGSizeZero;

    if (@available(iOS 11, *)) {

        CGRect safeBounds = CGRectMake(bounds.origin.x + self.safeAreaInsets.left, bounds.origin.y + self.safeAreaInsets.top, bounds.size.width - self.safeAreaInsets.left - self.safeAreaInsets.right, bounds.size.height - self.safeAreaInsets.top - self.safeAreaInsets.bottom);;

        self.contentView.frame = safeBounds;

        offset.width -= 0.5 * self.safeAreaInsets.left;
        offset.width += 0.5 * self.safeAreaInsets.right;

        offset.height -= 0.5 * self.safeAreaInsets.top;
        offset.height += 0.5 * self.safeAreaInsets.bottom;

    } else {

        self.contentView.frame = bounds;
    }

    // Perform 3D viewing transformation and clip invisible overlays
    //
    NSMutableArray<TGLARViewOverlay *> *visibleViews = [NSMutableArray array];

    for (TGLARViewOverlay *view in self.overlayViews) {
        
        GLKVector3 targetPosition = [view.overlay targetPosition];
        GLKVector4 positionVector = GLKVector4MakeWithVector3(targetPosition, 1.0);
        GLKVector4 homoVector = GLKMatrix4MultiplyVector4(self.overlayTransformation, positionVector);

        view.viewPosition = GLKVector3Make(homoVector.x / homoVector.w, homoVector.y / homoVector.w, homoVector.z / homoVector.w);
        
        GLKVector2 unitPosition = GLKVector2Make(view.viewPosition.x, view.viewPosition.y);
        float unitLength = GLKVector2Length(unitPosition);
        
        if (unitLength < 2.0 && view.viewPosition.z <= 1.0) {
            
            [visibleViews addObject:view];
            
        } else {
            
            view.hidden = YES;
            view.calloutLength = 0.0;
        }

        [view removeFromSuperview];
    }
    
    // Arrange n visible overlays from back (0) to front (n-1)
    //
    [visibleViews sortUsingComparator:^NSComparisonResult (TGLARViewOverlay *view1, TGLARViewOverlay *view2) {

        if (view1.viewPosition.z > view2.viewPosition.z) return (NSComparisonResult)NSOrderedAscending;
        if (view1.viewPosition.z < view2.viewPosition.z) return (NSComparisonResult)NSOrderedDescending;
        
        return (NSComparisonResult)NSOrderedSame;
    }];

    for (NSInteger idx = 0; idx < visibleViews.count; idx++) {
        
        TGLARViewOverlay *view = visibleViews[idx];
        
        [self insertSubview:view atIndex:idx];
    }

    // Position overlays in container and minimize overlap
    //
    CGFloat calloutLength = 0.0;
    CGFloat calloutOffset = 30.0;
    CGFloat calloutDefault = 120.0;

    for (NSInteger idx = visibleViews.count - 1; idx >= 0; idx--) {

        TGLARViewOverlay *view = visibleViews[idx];

        GLKVector2 unitPosition = GLKVector2Make(view.viewPosition.x, view.viewPosition.y);
        float unitLength = GLKVector2Length(unitPosition);

        CGPoint screenPosition;
        
        screenPosition.x = round(0.5 * (unitPosition.x + 1.0) * CGRectGetWidth(self.contentView.bounds)) + offset.width;
        screenPosition.y = round(0.5 * (1.0 - unitPosition.y) * CGRectGetHeight(self.contentView.bounds)) + offset.height;

        if (view.hidden) {

            // Newly appearing view needs length
            //
            if (calloutLength > 0.0) {
                
                view.calloutLength = ++calloutLength;

            } else {

                view.calloutLength = calloutLength = calloutDefault;
            }

            view.rightAligned = (unitPosition.x > 0.0);
            view.hidden = NO;

        } else {
            
            if (calloutLength == 0.0) {
                
                if (view.calloutLength > calloutDefault) {
                    
                    view.calloutLength--;
                    
                } else if (view.calloutLength < calloutDefault) {
                    
                    view.calloutLength++;
                }

            } else if ((view.calloutLength - calloutLength) > calloutOffset) {
                
                view.calloutLength--;
                
            } else if ((view.calloutLength - calloutLength) < calloutOffset) {
            
                view.calloutLength++;
            }
            
            calloutLength = view.calloutLength;
        }

        [view sizeToFit];
        
        CGRect frame = view.bounds;

        frame.origin.x = screenPosition.x;

        if (view.rightAligned) frame.origin.x -= CGRectGetWidth(frame);
        
        frame.origin.y = screenPosition.y;

        if (!view.upsideDown) frame.origin.y -= CGRectGetHeight(frame);

        view.frame = frame;
        view.alpha = (unitLength > 1.0) ? MAX(2.0 - unitLength, 0.0) : 1.0;

        [view setNeedsDisplay];
    }
}

#pragma mark - Interaction

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if ([self pointInside:point withEvent:event] && self.isUserInteractionEnabled && !self.isHidden && self.alpha > 0.01) {
        
        for (UIView *subview in [self.contentView.subviews reverseObjectEnumerator]) {
            
            CGPoint convertedPoint = [subview convertPoint:point fromView:self];
            UIView *hitTestView = [subview hitTest:convertedPoint withEvent:event];
            
            if (hitTestView) return hitTestView;
        }
        
        return self;
    }

    return nil;
}

@end
