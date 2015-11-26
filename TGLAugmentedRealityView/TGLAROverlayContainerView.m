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

#pragma mark - Accessors

- (void)setOverlayViews:(NSArray<TGLARViewOverlay *> *)overlayViews {
    
    for (TGLARViewOverlay *view in self.subviews) {
        
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
    }
    
    // Sort n visible overlays from back (0) to front (n-1)
    //
    [visibleViews sortUsingComparator:^NSComparisonResult (TGLARViewOverlay *view1, TGLARViewOverlay *view2) {

        if (view1.viewPosition.z > view2.viewPosition.z) return (NSComparisonResult)NSOrderedAscending;
        if (view1.viewPosition.z < view2.viewPosition.z) return (NSComparisonResult)NSOrderedDescending;
        
        return (NSComparisonResult)NSOrderedSame;
    }];
    
    for (TGLARViewOverlay *view in self.subviews) {
        
        if ([visibleViews indexOfObject:view] == NSNotFound) {
            
            [view removeFromSuperview];
        }
    }

    for (NSInteger idx = 0; idx < visibleViews.count; idx++) {
        
        TGLARViewOverlay *view = visibleViews[idx];
        
        [self insertSubview:view atIndex:idx];
    }

    // Position overlays in container and minimize overlap
    //
    CGFloat calloutLength = 0.0;
    CGFloat calloutOffset = 30.0;
    CGFloat calloutDefault = 120.0;
    
    for (NSInteger idx = self.subviews.count - 1; idx >= 0; idx--) {

        TGLARViewOverlay *view = self.subviews[idx];

        GLKVector2 unitPosition = GLKVector2Make(view.viewPosition.x, view.viewPosition.y);
        float unitLength = GLKVector2Length(unitPosition);

        CGPoint screenPosition;
        
        screenPosition.x = round(0.5 * (unitPosition.x + 1.0) * CGRectGetWidth(self.bounds));
        screenPosition.y = round(0.5 * (1.0 - unitPosition.y) * CGRectGetHeight(self.bounds));

        if (view.hidden) {

            // Newly appearing view needs length
            //
            if (calloutLength > 0.0) {
                
                view.calloutLength = ++calloutLength;

            } else {

                view.calloutLength = calloutLength = calloutDefault;
            }

            view.rightAligned = (unitPosition.x > 0.0);

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

        if (unitLength > 1.0) {
            
            view.alpha = 2.0 - unitLength;

        } else {
        
            view.alpha = 1.0;
        }
        
        view.frame = frame;
        view.hidden = NO;
        
        [view setNeedsDisplay];
    }
}

#pragma mark - Interaction

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    
    if ([self pointInside:point withEvent:event] && self.isUserInteractionEnabled && !self.isHidden && self.alpha > 0.01) {
        
        for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
            
            CGPoint convertedPoint = [subview convertPoint:point fromView:self];
            UIView *hitTestView = [subview hitTest:convertedPoint withEvent:event];
            
            if (hitTestView) return hitTestView;
        }
        
        return self;
    }

    return nil;
}

#pragma mark - Drawing

//- (void)drawRect:(CGRect)rect {
//    
//    [[UIColor greenColor] setFill];
//    
//    for (TGLARViewOverlay *view in self.subviews) {
//
//        GLKVector3 targetPosition = [view.overlay targetPosition];
//        GLKVector4 shapeVector = GLKVector4MakeWithVector3(targetPosition, 1.0);
//        GLKVector4 homoVector = GLKMatrix4MultiplyVector4(self.overlayTransformation, shapeVector);
//        GLKVector4 unitVector = GLKVector4DivideScalar(homoVector, homoVector.w);
//        
//        if (fabs(unitVector.x) <= 1.0 && fabs(unitVector.y) <= 1.0 && unitVector.z <= 1.0) {
//
//            // On screen
//            //
//            CGPoint screenPosition;
//            
//            screenPosition.x = 0.5 * (unitVector.x + 1.0) * CGRectGetWidth(self.bounds);
//            screenPosition.y = 0.5 * (1.0 - unitVector.y) * CGRectGetHeight(self.bounds);
//            
//            CGRect frame = CGRectMake(screenPosition.x - 4, screenPosition.y - 4, 8, 8);
//            
//            UIRectFill(frame);
//        }
//    }
//}

@end
