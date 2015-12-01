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

/** A @p UIView subclass presenting the current heading angle as a horizontal HUD.
 *
 * The HUD has an upper scale with 16 lines at 22.5 degrees, a lower scale with
 * 72 lines at 5 degrees and centered labels for the 8 main directions of the 
 * compass rose.
 */
@interface TGLARCompassView : UIView <TGLARCompass>

/// The compass label font. Default is bold system font at 24 points.
@property (nonatomic, copy, nullable) IBInspectable UIFont *labelFont;
/// The compass label color. Default is @p [UIColor whiteColor].
@property (nonatomic, copy, nullable) IBInspectable UIColor *labelColor;

/// The north direction color. Default is @p [UIColor redColor].
@property (nonatomic, copy, nullable) IBInspectable UIColor *northColor;
/// The north scale line width. Default is @p 4.0.
@property (nonatomic, assign) IBInspectable CGFloat northLineWidth;

/// The upper compass scale color. Default is @p [UIColor whiteColor].
@property (nonatomic, copy, nullable) IBInspectable UIColor *topScaleColor;
/// The upper scale line width. Default is @p 2.0.
@property (nonatomic, assign) IBInspectable CGFloat topScaleLineWidth;

/// The lower compass scale color. Default is @p [UIColor whiteColor].
@property (nonatomic, copy, nullable) IBInspectable UIColor *bottomScaleColor;
/// The lower scale line width. Default is @p 2.0.
@property (nonatomic, assign) IBInspectable CGFloat bottomScaleLineWidth;

@end
