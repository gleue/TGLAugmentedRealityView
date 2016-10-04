//
//  TGLARViewOverlay.h
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

#import <UIKit/UIKit.h>

#import "TGLAROverlay.h"

/** A @p UIView subclass to present 2D content in a @p TGLARView.
 *
 * Any subviews to this overlay @a must be placed inside @p -contentView.
 *
 * The overlay draws a callout line from the overlay's @p -targetPosition
 * and places the content view at the other end of the callout line.
 *
 * The content view background is transparent by default and is @a not
 * the same as the @p -calloutColor.
 */
@interface TGLARViewOverlay : UIView

/// The overlay this view belongs to.
@property (nonatomic, weak, nullable) id<TGLAROverlay> overlay;

/// The view containing the all of the overlays content-related views.
@property (nonatomic, readonly, nonnull) UIView *contentView;

/** If set to @YES place the callout and the @p -contentView below the
 * overlay @-targetPosition, above otherwise. Default is @p NO. */
@property (nonatomic, assign) BOOL upsideDown;
/** If set to @YES place the callout and the @p -contentView to the
 * left of @-targetPosition, to the right otherwise. Default is @p NO. */
@property (nonatomic, assign) BOOL rightAligned;

/** The vertical distance in points between the overlay @p -targetPosition
 * on screen and the top/bottom edge of the @p -contentView. Default is @p 100.0. */
@property (nonatomic, assign) CGFloat calloutLength;
/// The callout line width in points. Default is 2.0.
@property (nonatomic, assign) CGFloat calloutLineWidth;
/// The callout line color. Default is @p [UIColor whiteColor].
@property (nonatomic, copy, nullable) UIColor *calloutLineColor;

/// Private property. For internal use only
@property (nonatomic, assign) GLKVector3 viewPosition;

@end
