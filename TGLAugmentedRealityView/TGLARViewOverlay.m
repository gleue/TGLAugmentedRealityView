//
//  TGLARViewOverlay.m
//  TGLAugmentedRealityView
//
//  Created by Tim Gleue on 13.11.15.
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

#import "TGLARViewOverlay.h"

@implementation TGLARViewOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) [self initOverlay];
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    
    if (self) [self initOverlay];
    
    return self;
}

- (void)initOverlay {

    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowRadius = 3.0;

    _contentView = [[UIView alloc] init];
    _contentView.backgroundColor = [UIColor clearColor];
    _contentView.opaque = NO;
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:_contentView];

    _calloutLineWidth = 2.0;
    _calloutLineColor = [UIColor whiteColor];
    
    _calloutLength = 100.0;
}

#pragma mark - Accessors

- (void)setUpsideDown:(BOOL)upsideDown {

    _upsideDown = upsideDown;
    
    [self setNeedsLayout];
}

- (void)setRightAligned:(BOOL)rightAligned {

    _rightAligned = rightAligned;
    
    [self setNeedsLayout];
}

- (void)setCalloutLength:(CGFloat)calloutLength {
    
    _calloutLength = calloutLength;
    
    [self setNeedsLayout];
}

- (void)setCalloutLineWidth:(CGFloat)calloutLineWidth {

    _calloutLineWidth = calloutLineWidth;
    
    [self setNeedsDisplay];
}

- (void)setCalloutLineColor:(UIColor *)calloutLineColor {

    _calloutLineColor = [calloutLineColor copy];

    [self setNeedsDisplay];
}

#pragma mark - Layout

- (CGSize)sizeThatFits:(CGSize)size {

    CGSize contentSize = [self.contentView sizeThatFits:size];
    
    contentSize.height = MAX(self.calloutLength, contentSize.height);
    
    return contentSize;
}

- (void)layoutSubviews {

    [super layoutSubviews];

    CGRect frame = self.contentView.frame;
    
    frame.origin.x = 0.0;
    frame.origin.y = self.upsideDown ? CGRectGetHeight(self.bounds) - CGRectGetHeight(frame) : 0.0;

    self.contentView.frame = frame;
}

#pragma mark - Interaction

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    CGPoint contentPoint = [self.contentView convertPoint:point fromView:self];
    
    if ([self.contentView pointInside:contentPoint withEvent:event] && self.isUserInteractionEnabled && !self.isHidden && self.alpha > 0.01) {
        
        for (UIView *subview in [self.contentView.subviews reverseObjectEnumerator]) {
            
            CGPoint subviewPoint = [subview convertPoint:point fromView:self];
            UIView *hitView = [subview hitTest:subviewPoint withEvent:event];
            
            if (hitView) return hitView;
        }
        
        return self;
    }
    
    return nil;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect {

    CGFloat x = self.rightAligned ? CGRectGetWidth(self.bounds) : 0.0;
    
    CGPoint originPoint = CGPointMake(x, 0.0);
    CGPoint targetPoint = CGPointMake(x, CGRectGetHeight(self.bounds));
    
    [self.calloutLineColor setStroke];
    
    UIBezierPath *calloutLine = [UIBezierPath bezierPath];

    [calloutLine moveToPoint:originPoint];
    [calloutLine addLineToPoint:targetPoint];
    
    calloutLine.lineWidth = self.calloutLineWidth;
    [calloutLine stroke];
}

@end
