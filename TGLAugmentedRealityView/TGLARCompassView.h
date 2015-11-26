//
//  TGLARCompassView.h
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

#import <UIKit/UIKit.h>
#import <GLKit/GLKVector3.h>

#import "TGLARCompass.h"

IB_DESIGNABLE

@interface TGLARCompassView : UIView <TGLARCompass>

@property (nonatomic, copy) IBInspectable UIFont *labelFont;
@property (nonatomic, copy) IBInspectable UIColor *labelColor;

@property (nonatomic, copy) IBInspectable UIColor *northColor;
@property (nonatomic, assign) IBInspectable CGFloat northLineWidth;

@property (nonatomic, copy) IBInspectable UIColor *topScaleColor;
@property (nonatomic, assign) IBInspectable CGFloat topScaleLineWidth;

@property (nonatomic, copy) IBInspectable UIColor *bottomScaleColor;
@property (nonatomic, assign) IBInspectable CGFloat bottomScaleLineWidth;

@end
