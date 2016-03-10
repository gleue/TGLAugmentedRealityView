//
//  TGLARCompassView.m
//  TGLAugmentedRealityView
//
//  Created by Tim Gleue on 19.11.15.
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

#import <GLKit/GLKMathUtils.h>

#import "TGLARCompassView.h"

@interface TGLARCompassView ()

@property (nonatomic, assign) CGFloat fieldOfView;
@property (nonatomic, assign) CGFloat headingAngle;

@property (nonatomic, readonly) NSDictionary<NSNumber *, NSString *> *compassLabels;

@end

@implementation TGLARCompassView

@synthesize compassLabels = _compassLabels;

#pragma mark - Accessors

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];
    
    if (self) [self initCompass];
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) [self initCompass];
    
    return self;
}

- (void)initCompass {

#if TARGET_IPHONE_SIMULATOR
    _fieldOfView = 50.0;
#endif
    
    _labelFont = [UIFont boldSystemFontOfSize:24.0];
    _labelColor = [UIColor whiteColor];
    
    _northColor = [UIColor redColor];
    _northLineWidth = 4.0;
    
    _topScaleColor = [UIColor whiteColor];
    _topScaleLineWidth = 2.0;
    
    _bottomScaleColor = [UIColor whiteColor];
    _bottomScaleLineWidth = 2.0;
}

#pragma mark - Accessors

- (void)setHeadingAngle:(CGFloat)headingAngle {

    _headingAngle = headingAngle;
    
    [self setNeedsDisplay];
}

- (void)setFieldOfView:(CGFloat)fieldOfView {
    
    _fieldOfView = fieldOfView;
    
    [self setNeedsDisplay];
}

- (void)setLabelFont:(UIFont *)labelFont {
    
    _labelFont = [labelFont copy];
    
    [self setNeedsDisplay];
}

- (void)setLabelColor:(UIColor *)labelColor {
    
    _labelColor = [labelColor copy];
    
    [self setNeedsDisplay];
}

- (void)setNorthColor:(UIColor *)northColor {
    
    _northColor = [northColor copy];
    
    [self setNeedsDisplay];
}

- (void)setNorthLineWidth:(CGFloat)northLineWidth {
    
    _northLineWidth = northLineWidth;
    
    [self setNeedsDisplay];
}

- (void)setTopScaleColor:(UIColor *)topScaleColor {

    _topScaleColor = [topScaleColor copy];
    
    [self setNeedsDisplay];
}

- (void)setTopScaleLineWidth:(CGFloat)topScaleLineWidth {
    
    _topScaleLineWidth = topScaleLineWidth;
    
    [self setNeedsDisplay];
}

- (void)setBottomScaleColor:(UIColor *)bottomScaleColor {
    
    _bottomScaleColor = [bottomScaleColor copy];
    
    [self setNeedsDisplay];
}

- (void)setBottomScaleLineWidth:(CGFloat)bottomScaleLineWidth {
    
    _bottomScaleLineWidth = bottomScaleLineWidth;
    
    [self setNeedsDisplay];
}

- (NSDictionary<NSNumber *, NSString *> *)compassLabels {

    if (_compassLabels == nil) {
    
        _compassLabels = @{ @(000.0): NSLocalizedString(@"N", nil), @(045.0): NSLocalizedString(@"NE", nil),
                            @(090.0): NSLocalizedString(@"E", nil), @(135.0): NSLocalizedString(@"SE", nil),
                            @(180.0): NSLocalizedString(@"S", nil), @(225.0): NSLocalizedString(@"SW", nil),
                            @(270.0): NSLocalizedString(@"W", nil), @(315.0): NSLocalizedString(@"NW", nil) };
    }
    
    return _compassLabels;
}

#pragma mark - Drawing

#define TOPSCALE 16
#define LABELSCALE 8
#define BOTTOMSCALE 72

- (void)drawRect:(CGRect)rect {
    
    [self.backgroundColor setFill];
    UIRectFill(self.bounds);
    
    UIBezierPath *line = [UIBezierPath bezierPath];
    
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat width_2 = 0.5 * width;
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat height_2 = 0.5 * height;
    
    [line moveToPoint:CGPointMake(width_2, 0.0)];
    [line addLineToPoint:CGPointMake(width_2, height)];

    CGFloat fov_2 = 0.5 * self.fieldOfView;
    CGFloat factor = CGRectGetWidth(self.bounds) / tanf(GLKMathDegreesToRadians(fov_2));
    CGFloat startAngle = self.headingAngle - fov_2;
    CGFloat endAngle = self.headingAngle + fov_2 + 2.0;
    
    if (startAngle < 0.0) {
        
        startAngle += 360.0;
        endAngle += 360.0;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();

    // |(-fov/2)         |         (+fov/2)|
    // |<----------------+---------------->|
    // |-w/2             0             +w/2|
    //

    // Top scale
    {
        [self.topScaleColor setStroke];

        CGFloat incr = 360.0 / TOPSCALE;
        NSInteger index = floorf(startAngle / incr);

        for (CGFloat angle = incr * index; angle <= endAngle; angle += incr, index++) {
            
            CGContextSaveGState(context);

            if (index % TOPSCALE) {
                
                line.lineWidth = self.topScaleLineWidth;
                
            } else {
                
                [self.northColor setStroke];
                line.lineWidth = self.northLineWidth;
            }

            CGFloat delta = GLKMathDegreesToRadians(angle - self.headingAngle);
            CGFloat xoffset = factor * tanf(0.5 * delta);
            CGFloat yscale = 0.25;
            
            CGContextScaleCTM(context, 1.0, yscale);
            CGContextTranslateCTM(context, xoffset, 0.0);
            
            [line stroke];
            
            CGContextRestoreGState(context);
        }
    }
    
    // Label scale
    {
        CGFloat incr = 360.0 / LABELSCALE;
        NSInteger index = floorf(startAngle / incr);
        
        for (CGFloat angle = incr * index; angle <= endAngle; angle += incr, index++) {
            
            NSString *label = self.compassLabels[@(incr * (index % LABELSCALE))];
            
            if (label) {
                
                CGContextSaveGState(context);
                
                CGFloat delta = GLKMathDegreesToRadians(angle - self.headingAngle);
                CGFloat xoffset = factor * tanf(0.5 * delta);

                CGContextTranslateCTM(context, xoffset, 0.0);
                
                UIColor *labelColor = (index % LABELSCALE) ? self.labelColor : self.northColor;
                NSDictionary *labelAttributes = @{ NSFontAttributeName: self.labelFont, NSForegroundColorAttributeName: labelColor };
                CGSize labelSize = [label sizeWithAttributes:labelAttributes];
                
                [label drawAtPoint:CGPointMake(round(width_2 - 0.5 * labelSize.width), round(height_2 - 0.5 * labelSize.height)) withAttributes:labelAttributes];
                
                CGContextRestoreGState(context);
            }
        }
    }

    // Bottom scale
    {
        [self.bottomScaleColor setStroke];

        CGFloat incr = 360.0 / BOTTOMSCALE;
        NSInteger index = floorf(startAngle / incr);

        for (CGFloat angle = incr * index; angle <= endAngle; angle += incr, index++) {
            
            CGContextSaveGState(context);
            
            if (index % BOTTOMSCALE) {
                
                line.lineWidth = self.bottomScaleLineWidth;
                
            } else {
                
                [self.northColor setStroke];
                line.lineWidth = self.northLineWidth;
            }
            
            CGFloat delta = GLKMathDegreesToRadians(angle - self.headingAngle);
            CGFloat xoffset = factor * tanf(0.5 * delta);
            CGFloat yscale = 0.25;

            CGContextScaleCTM(context, 1.0, yscale);
            CGContextTranslateCTM(context, xoffset, 0.75 * height / yscale);
            
            [line stroke];
            
            CGContextRestoreGState(context);
        }
    }
}

#pragma mark - Interface Builder

- (void)prepareForInterfaceBuilder {
    
    [super prepareForInterfaceBuilder];
    
    self.headingAngle = 0;
    self.fieldOfView = 50;
}

@end
