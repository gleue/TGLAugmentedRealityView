//
//  TGLARShapeOverlay.h
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
#import <GLKit/GLKit.h>

#import "TGLAROverlay.h"

/** An object to present 3D content in a @p TGLARView.
 *
 * The containing @p TGLARView sets the projection and
 * modelview matrices depending on the current device
 * orientation and attitude.
 *
 * A custom @p -transform is pre-multipled to the modelview
 * matrix to allow for individual shape tranformations before
 * the viewing transformations are applied.
 */
@interface TGLARShapeOverlay : NSObject

/// The overlay this shape belongs to.
@property (nonatomic, weak, nullable) id<TGLAROverlay> overlay;

/// The shape's OpenGL ES rendering context.
@property (nonatomic, weak, nullable) EAGLContext * context;
/// The shape transformation matrix pre-multiplied to @p -viewMatrix.
@property (nonatomic, assign) GLKMatrix4 transform;
/// The shape's GLKKit rendering effect. @sa GLKBaseEffect for details.
@property (nonatomic, readonly, nonnull) GLKBaseEffect *effect;

/// The OpenGL ES view transformation to be applied. Set by the containing @p TGLARView.
@property (nonatomic, assign) GLKMatrix4 viewMatrix;
/// The OpenGL ES projection transformation to be applied. Set by the containing @p TGLARView.
@property (nonatomic, assign) GLKMatrix4 projectionMatrix;

/// Initialize an instance using the given OpenGL ES context.
- (nullable instancetype)initWithContext:(nonnull EAGLContext *)context;

/** Draws the shape using OpenGL ES.
 *
 * The method implementation initializes the transform property
 * of the @p -effect and calls its @p -prepareToDraw method.
 *
 * Override this method in subclasses to customize the shape.
 * Unless the subclass takes care of setting up the effect as
 * described above, the subcalls implementation @a must call
 * @p [super draw].
 *
 * @return YES if drawing succeeds. NO otherwise, e.g. if -context is no longer valid.
 */
- (BOOL)draw;

/** Draws the shape using OpenGL ES without any shading and texturing.
 *
 * The base class implementation simply calls @[self -draw].
 *
 * This method is used internally to implement picking shapes
 * on an @p TGLARView.
 *
 * @sa @p TGLARView
 */
- (BOOL)drawUsingConstantColor:(GLKVector4)color;

@end
