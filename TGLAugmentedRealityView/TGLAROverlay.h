//
//  TGLAROverlay.h
//  TGLAugmentedRealityView
//
//  Created by Tim Gleue on 09.11.15.
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

#import <Foundation/Foundation.h>
#import <GLKit/GLKVector3.h>

@class TGLARViewOverlay;
@class TGLARShapeOverlay;

/// An object returned by a @p TGLARViewDataSource must adopt this protocol.
@protocol TGLAROverlay <NSObject>

/** Returns the X/Y/Z position this overlay is attached to.
 *
 * The position is defined relative to the camera, which is
 * located at the coordinate system origin. The distance
 * values are given in meters.
 *
 * The coordinate system is right-handed with positive X axis
 * pointing north, the postive Y axis pointing east and the
 * positive Z axis pointing upwards.
 *
 * @return The X/Y/Z position of the overlay target.
 */
- (GLKVector3)targetPosition;

/** Set the X/Y/Z position this overlay should be attached to.
 *
 * The distance values have to be given in meters.
 *
 * @param position The the overlay target X/Y/Z position.
 *
 * @sa -targetPosition
 */
- (void)setTargetPosition:(GLKVector3)position;

@optional;

/** Returns the view to show for this overlay.
 *
 * If the receiver does not respond to this selector
 * no view is shown for the overlay.
 *
 * @return A TGLARViewOverlay instance.
 *
 * @sa TGLARViewOverlay
 */
- (nullable TGLARViewOverlay *)overlayView;

/** Set the view to show for this overlay.
 *
 * @param overlayView A TGLARViewOverlay instance to show for this overlay.
 */
- (void)setOverlayView:(nullable TGLARViewOverlay *)overlayView;

/** Returns the 3D shape to show for this overlay.
 *
 * If the receiver does not respond to this selector
 * no shape is shown for the overlay.
 *
 * @return A TGLARShapeOverlay instance.
 *
 * @sa TGLARShapeOverlay
 */
- (nullable TGLARShapeOverlay *)overlayShape;

/** Set the 3D shape to show for this overlay.
 *
 * @param overlayView A TGLARShapeOverlay instance to show for this overlay.
 */
- (void)setOverlayShape:(nullable TGLARShapeOverlay *)overlayShape;

@end
