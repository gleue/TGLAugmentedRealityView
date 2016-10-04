//
//  TGLARView.h
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

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "TGLARCompass.h"
#import "TGLAROverlay.h"

@class TGLARView;

/// The @pTGLARView data source must adopt the @p TGLARViewDataSource protocol.
@protocol TGLARViewDataSource <NSObject>

/** Asks the data source to return the number of overlays to be shown on the AR view.
 *
 * @param arview The AR view asking for the overlay count.
 *
 * @return The number of overlays to be shown on this particular AR view.
 */
- (NSInteger)numberOfOverlaysInARView:(nonnull TGLARView *)arview;

/** Asks the data source for the overlay to be shown at a particular index.
 *
 * @param arview The AR view asking for an overlay.
 *
 * @return An object adopting the @p TGLAROverlay protocol.
 *
 * @sa @p TGLAROverlay
 */
- (nullable id<TGLAROverlay>)arView:(nonnull TGLARView *)arview overlayAtIndex:(NSInteger)index;

@end

/// The @pTGLARView delegate must adopt the @p TGLARViewDelegate protocol.
@protocol TGLARViewDelegate <NSObject>

@optional

/** Tells the delegate that the user is about to change the offsets by a pan gesture on the AR view.
 *
 * @param arview The AR view informing the delegate about the beginning updates.
 *
 * @sa @p -heightOffset
 * @sa @p -headingOffset
 * @sa @p -positionOffset
 */
- (void)arViewWillBeginUpdatingOffsets:(nonnull TGLARView *)arview;

/** Tells the delegate that the offset values properties have been updated during a pan gesture.
 *
 * @param arview The AR view informing the delegate about the offset value update.
 *
 * @sa @p -heightOffset
 * @sa @p -headingOffset
 * @sa @p -positionOffset
 */
- (void)arViewDidUpdateOffsets:(nonnull TGLARView *)arview;

/** Tells the delegate that the user ended the pan gesture.
 *
 * @param arview The AR view informing the delegate about the end of the updates.
 *
 * @sa @p -heightOffset
 * @sa @p -headingOffset
 * @sa @p -positionOffset
 */
- (void)arViewDidEndUpdatingOffsets:(nonnull TGLARView *)arview;

/** Tells the delegate that the user is about to change to video zoom by a pinch gesture on the AR view.
 *
 * @param arview The AR view informing the delegate about the beginning updates.
 *
 * @sa @p -zoomFactor
 */
- (void)arViewWillBeginZooming:(nonnull TGLARView *)arview;

/** Tells the delegate that the video zoom factore has been updated during a pinch gesture.
 *
 * @param arview The AR view informing the delegate about the zoom factor update.
 *
 * @sa @p -zoomFactor
 */
- (void)arViewDidZoom:(nonnull TGLARView *)arview;

/** Tells the delegate that the user ended the pinch gesture.
 *
 * @param arview The AR view informing the delegate about the end of the updates.
 * @param zoomFactor The final video zoom factor.
 *
 * @sa @p -zoomFactor
 */
- (void)arViewDidEndZooming:(nonnull TGLARView *)arview atFactor:(CGFloat)zoomFactor;

/** Tells the delegate that the user tapped a particular overlay view.
 *
 * @param arview The AR view informing the delegate about the tap.
 * @param overlayView The view tapped by the user.
 */
- (void)arView:(nonnull TGLARView *)arview didTapViewOverlay:(nonnull TGLARViewOverlay *)overlayView;

/** Tells the delegate that the user tapped a particular overlay shape.
 *
 * @param arview The AR view informing the delegate about the tap.
 * @param overlayShape The shape tapped by the user.
 */
- (void)arView:(nonnull TGLARView *)arview didTapShapeOverlay:(nonnull TGLARShapeOverlay *)overlayShape;

/** Asks the delegate for the far clipping of overlay shapes.
 *
 * If this method is not implemented by the delegate, the value
 * defaults to 10000.0.
 *
 * @param arview The AR view requesting the distance value.
 *
 * @return A non-negative value for the far clipping distance.
 */
- (CGFloat)arViewShapeOverlayFarClippingDistance:(nonnull TGLARView *)arview;

/** Asks the delegate for the near clipping of overlay shapes.
 *
 * If this method is not implemented by the delegate, the value
 * defaults to 1.0.
 *
 * @param arview The AR view requesting the distance value.
 *
 * @return A non-negative value for the near clipping distance.
 */
- (CGFloat)arViewShapeOverlayNearClippingDistance:(nonnull TGLARView *)arview;

@end

/** The @p TGLARView presents 2D view-based overlays and 3D shape overlays on top of a camera preview.
 *
 * Overlays are virtually attached to their @p -targetPosition. They are positioned in the @p TGLARView
 * depending on the current device attitude as if seen through the device's back-facing camera.
 *
 * @p TGLARView uses @p CoreMotion to get the device orientation in X/Y/Z space, where positive X is north,
 * positive Y west and Z points up. If supported by the device the X axis is aligned to magnetic north.
 *
 * The user may use a horizontal pan gesture to adjust the X/Y plane alignment, e.g. when magnetic north
 * is not available on the device. A vertical pan is used to adjust virtual camera height. By default, the
 * camera is located at the origin @p (0,0,0).
 *
 * If video zoom is suppoted for the current video format, a pinch gesture may be used to adjust the
 * zoom factor. The virtual camera field of view is adjusted automatically when zooming.
 */
@interface TGLARView : UIView  <GLKViewDelegate>

/// An object conforming to @p TGLARCompass protocol receiving heading updates while the device moves. Default is @p nil.
@property (nonatomic, weak, nullable) IBOutlet id<TGLARCompass> compass;
/// The object that acts as the delegate of this AR view. Default is @p nil.
@property (nonatomic, weak, nullable) IBOutlet id<TGLARViewDelegate> delegate;
/// The object that acts as the data source of this AR view. Default is @p nil.
@property (nonatomic, weak, nullable) IBOutlet id<TGLARViewDataSource> dataSource;

/// Tells the AR view which device orientation to assume. Controls the selection of the virtual camera's field of view.
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

/// Current video zoom factor from @p 1.0 to @p -maxZoomFactor. Default is @p 1.0.
@property (nonatomic, assign) CGFloat zoomFactor;
/// Maximum video zoom factor. @p 1.0 means no zoom.
@property (nonatomic, readonly) CGFloat maxZoomFactor;

/// Indicates whether CoreMotion can use compass on the current device
@property (nonatomic, readonly, getter=isMagenticNorthAvailable) BOOL magneticNorthAvailable;
/// If compass and location are available use true north heading. Default is @p NO.
@property (nonatomic, assign, getter=isUsingTrueNorth) BOOL useTrueNorth;

/** Camera height above X/Y plane in meters. Default is @p 0.0.
 *
 * The user may change this value by a vertical pan gesture.
 *
 * @sa @p TGLARViewDelegate
 */
@property (nonatomic, assign) CGFloat heightOffset;

/** Camera heading angle in degrees added to device attitude. Default is @p 0.0.
 *
 * Positive angles result in a clockwise camera rotation.
 * The user may change this value by a horizontal pan gesture.
 *
 * @sa @p TGLARViewDelegate
 */
@property (nonatomic, assign) CGFloat headingOffset;

/** Camera position offset in meters in the X/Y plane.
 *
 * @param positionOffset.width X axis offset
 * @param positionOffset.height Y axis offset
 *
 * Positive X values move the camera north, negative ones south.
 * Positive Y values move the camera west, negative ones east.
 */
@property (nonatomic, assign) CGSize positionOffset;

/// Returns the OpenGL ES context used to draw overlay shapes.
- (nonnull EAGLContext *)renderContext;

/// Starts the video preview and rendering of the overlays.
- (void)start;
/// Stops the video preview and rendering of the overlays.
- (void)stop;

/** Reloads the overlays from the current data source.
 *
 * @sa @p -dataSource
 */
- (void)reloadData;

@end
