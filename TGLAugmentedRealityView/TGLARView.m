//
//  TGLARView.m
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

#import "TGLARView.h"
#import "TGLAROverlay.h"
#import "TGLARViewOverlay.h"
#import "TGLARShapeOverlay.h"
#import "TGLAROverlayContainerView.h"
#import "TGLARCompassView.h"

#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/glext.h>

static char FOVARViewKVOContext;

static const CGFloat kFOVARViewLensAdjustmentFactor = 0.05;

@interface TGLARView () <UIGestureRecognizerDelegate> {

    GLKMatrix4 _deviceTransform;
    GLKMatrix4 _cameraTransform;
    GLKMatrix4 _userTransformation;
    
    GLKMatrix4 _viewMatrix;
    GLKMatrix4 _projectionMatrix;
}

@property (nonatomic, strong) CMMotionManager *motionManager;

@property (nonatomic, strong) UIView *captureView;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *captureLayer;

@property (nonatomic, strong) GLKView *renderView;
@property (nonatomic, strong) EAGLContext *renderContext;

@property (nonatomic, strong) TGLAROverlayContainerView *containerView;

@property (nonatomic, strong) CADisplayLink *displayLink;

@property (nonatomic, assign) CGFloat fovScalePortrait;
@property (nonatomic, assign) CGFloat fovScaleLandscape;

@property (nonatomic, assign) CGFloat verticalFovPortrait;
@property (nonatomic, assign) CGFloat verticalFovLandscape;

@property (nonatomic, strong) NSArray<TGLARShapeOverlay *> *overlayShapes;

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;

@end

#pragma mark - ARView implementation

@implementation TGLARView

@dynamic maxZoomFactor;

- (instancetype)initWithFrame:(CGRect)frame {
    
	self = [super initWithFrame:frame];
    
	if (self) [self initARView];
    
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
	self = [super initWithCoder:aDecoder];
	
    if (self) [self initARView];
    
	return self;
}

- (void)initARView {

    _magneticNorthAvailable = [CMMotionManager availableAttitudeReferenceFrames] & CMAttitudeReferenceFrameXMagneticNorthZVertical;
    _useTrueNorth = NO;

    _deviceTransform = GLKMatrix4Identity;
    _cameraTransform = GLKMatrix4Identity;
    _userTransformation = GLKMatrix4Identity;

    self.fovScalePortrait = 1.0;
    self.fovScaleLandscape = 1.0;

    // Make camera preview in background
    //
    self.captureView = [[UIView alloc] initWithFrame:self.bounds];

    [self addSubview:self.captureView];
	[self sendSubviewToBack:self.captureView];
    
    // Make transparent GL view above preview
    //
    self.renderContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.renderView = [[GLKView alloc] initWithFrame:self.bounds context:self.renderContext];
    self.renderView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.renderView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    self.renderView.delegate = self;

    CAEAGLLayer *renderLayer = (CAEAGLLayer *)self.renderView.layer;
    
    renderLayer.opaque = NO;
    
    self.renderView.backgroundColor = [UIColor clearColor];
    self.renderView.opaque = NO;

    [self insertSubview:self.renderView aboveSubview:self.captureView];
    
    // Make transparent overlay container above GL view
    //
    self.containerView = [[TGLAROverlayContainerView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = [UIColor clearColor];
    self.containerView.opaque = NO;
    
    [self insertSubview:self.containerView aboveSubview:self.renderView];

    // Add gesture recognizers
    //
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    self.tapRecognizer.delegate = self;

    [self addGestureRecognizer:self.tapRecognizer];
    
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    self.panRecognizer.delegate = self;
    
    [self addGestureRecognizer:self.panRecognizer];
    
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    self.pinchRecognizer.delegate = self;
    
    [self addGestureRecognizer:self.pinchRecognizer];
}

- (void)dealloc {
    
	[self stop];

    self.overlayShapes = nil;

	[self.captureView removeFromSuperview];
	[self.renderView removeFromSuperview];
    
    if ([EAGLContext currentContext] == self.renderContext) {

        [EAGLContext setCurrentContext:nil];
    }
    
    self.renderContext = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    
    CGRect bounds = self.bounds;

    self.captureLayer.frame = bounds;
    self.renderView.frame = bounds;
    self.containerView.frame = bounds;
    
    [self computeFovFromCameraFormat];
    [self updateProjectionMatrix];

    [super layoutSubviews];
}

#pragma mark - Accessors

- (void)setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {

    _interfaceOrientation = interfaceOrientation;
    
    switch (self.interfaceOrientation) {
            
        case UIInterfaceOrientationPortrait:
            
            _deviceTransform = GLKMatrix4Identity;
            if (self.captureLayer.connection.isVideoOrientationSupported) [self.captureLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
            break;
            
        case UIInterfaceOrientationPortraitUpsideDown:
            
            _deviceTransform = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(180.0), 0, 0, 1);
            if (self.captureLayer.connection.isVideoOrientationSupported) [self.captureLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            
            _deviceTransform = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(-90.0), 0, 0, 1);
            if (self.captureLayer.connection.isVideoOrientationSupported) [self.captureLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            
            _deviceTransform = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(+90.0), 0, 0, 1);
            if (self.captureLayer.connection.isVideoOrientationSupported) [self.captureLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
            break;
            
        default:

            break;
    }
    
    [self updateProjectionMatrix];
}

- (void)setZoomFactor:(CGFloat)zoomFactor {
    
    if (self.captureDevice) {
        
        NSError *error = nil;
        
        if ([self.captureDevice lockForConfiguration:&error]) {
            
            self.captureDevice.videoZoomFactor = MAX(1.0, MIN(zoomFactor, self.maxZoomFactor));
            
            [self.captureDevice unlockForConfiguration];
            
        } else {
            
            NSLog(@"%s ERROR: %@", __PRETTY_FUNCTION__, error.localizedDescription);
        }
        
        _zoomFactor = self.captureDevice.videoZoomFactor;
        
    } else {
        
        _zoomFactor = zoomFactor;
    }
    
    [self computeFovFromCameraFormat];
    [self updateProjectionMatrix];
}

- (CGFloat)maxZoomFactor {
    
    return self.captureDevice.activeFormat.videoMaxZoomFactor;
}

- (void)setUseTrueNorth:(BOOL)useTrueNorth {

    if (useTrueNorth != _useTrueNorth && self.isMagenticNorthAvailable) {

        if (useTrueNorth && [CMMotionManager availableAttitudeReferenceFrames] & CMAttitudeReferenceFrameXTrueNorthZVertical) {
            
            _useTrueNorth = YES;
            
            [self restartDeviceMotionIfNecessary];

        } else if (!useTrueNorth) {
            
            _useTrueNorth = NO;
            
            [self restartDeviceMotionIfNecessary];
        }
    }
}

- (void)setHeightOffset:(CGFloat)offset {
    
    if (offset != _heightOffset) {
        
        _heightOffset = offset;
        
        [self updateUserTransformation];
    }
}

- (void)setHeadingOffset:(CGFloat)offset {
    
    if (offset != _headingOffset) {
        
        _headingOffset = offset;
        
        [self updateUserTransformation];
    }
}

- (void)setPositionOffset:(CGSize)offset {
    
    if (!CGSizeEqualToSize(offset, _positionOffset)) {
        
        _positionOffset = offset;
        
        [self updateUserTransformation];
    }
}

#pragma mark - Actions

- (IBAction)handleTapGesture:(UITapGestureRecognizer *)recognizer {

    CGPoint containerTap = [recognizer locationInView:self.containerView];

    UIView *view = [self.containerView hitTest:containerTap withEvent:nil];
    
    if (view && view != self.containerView) {
        
        if ([self.delegate respondsToSelector:@selector(arView:didTapViewOverlay:)]) {

            [self.delegate arView:self didTapViewOverlay:(TGLARViewOverlay *)view];
        }

    } else {
        
        CGPoint renderTap = [recognizer locationInView:self.renderView];
        TGLARShapeOverlay *shape = [self findShapeAtPoint:renderTap];
        
        if (shape && [self.delegate respondsToSelector:@selector(arView:didTapShapeOverlay:)]) {
                
            [self.delegate arView:self didTapShapeOverlay:shape];
        }
    }
}

#define PAN_UNLOCKED 0
#define PAN_LOCK_H 1
#define PAN_LOCK_V 2

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    
    static CGPoint start;
    static short lock;
    static float heightOffset;
    static float headingOffset;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        start = [recognizer locationInView:self];
        lock = PAN_UNLOCKED;
        heightOffset = self.heightOffset;
        headingOffset = self.headingOffset;

        if ([self.delegate respondsToSelector:@selector(arViewWillBeginUpdatingOffsets:)]) {
            
            [self.delegate arViewWillBeginUpdatingOffsets:self];
        }

    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        CGPoint touch = [recognizer locationInView:self];
        
        float deltaX = (touch.x - start.x);
        float deltaY = (touch.y - start.y);
        
        if (lock == PAN_UNLOCKED) {
            
            lock = (fabs(deltaX) > fabs(deltaY)) ? PAN_LOCK_H : PAN_LOCK_V;
        }
        
        if (lock == PAN_LOCK_H) {
            
            float deltaHeading = deltaX / self.bounds.size.width;
            
            self.headingOffset = headingOffset - deltaHeading * [self effectiveHorizontalFov];
         
            [self updateUserTransformation];

        } else if (lock == PAN_LOCK_V) {
            
            float deltaHeight = 0.01 * deltaY;
            float newHeightOffset = heightOffset + deltaHeight;

            self.heightOffset = newHeightOffset;
            
            [self updateUserTransformation];
        }
        
        if ([self.delegate respondsToSelector:@selector(arViewDidUpdateOffsets:)]) {
            
            [self.delegate arViewDidUpdateOffsets:self];
        }
        
    } else if (recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateEnded) {
        
        if ([self.delegate respondsToSelector:@selector(arViewDidEndUpdatingOffsets:)]) {
            
            [self.delegate arViewDidEndUpdatingOffsets:self];
        }
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer {

    static CGFloat start;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
    
        start = self.zoomFactor;
        
        if ([self.delegate respondsToSelector:@selector(arViewWillBeginZooming:)]) {
            
            [self.delegate arViewWillBeginZooming:self];
        }

    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        self.zoomFactor = start * recognizer.scale;
        
        if ([self.delegate respondsToSelector:@selector(arViewDidZoom:)]) {
            
            [self.delegate arViewDidZoom:self];
        }

    } else if (recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateEnded) {
        
        if ([self.delegate respondsToSelector:@selector(arViewDidEndZooming:atFactor:)]) {
            
            [self.delegate arViewDidEndZooming:self atFactor:self.zoomFactor];
        }
    }
}

#pragma mark - Methods

- (void)start {

	[self startCameraPreview];
    [self startDeviceMotion];
	[self startDisplayLink];
    
    [self setNeedsLayout];
}

- (void)stop {

	[self stopDisplayLink];
    [self stopDeviceMotion];
	[self stopCameraPreview];
}

- (void)reloadData {

    NSMutableArray<TGLARViewOverlay *> *overlayViews = [NSMutableArray array];
    NSMutableArray<TGLARShapeOverlay *> *overlayShapes = [NSMutableArray array];

    NSInteger count = [self.dataSource numberOfOverlaysInARView:self];
    
    for (NSInteger index = 0; index < count; index++) {
        
        id<TGLAROverlay> overlay = [self.dataSource arView:self overlayAtIndex:index];
        
        if ([overlay respondsToSelector:@selector(overlayView)]) {
            
            TGLARViewOverlay *view = overlay.overlayView;

            if (view) [overlayViews addObject:view];
        }
        
        if ([overlay respondsToSelector:@selector(overlayShape)]) {

            TGLARShapeOverlay *shape = overlay.overlayShape;
            
            if (shape) [overlayShapes addObject:shape];
        }
    }
    
    self.overlayShapes = overlayShapes;
    self.containerView.overlayViews = overlayViews;
}

#pragma mark - Camera handling

- (void)startCameraPreview {
    
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (camera == nil) return;
    
    self.captureDevice = camera;
    
    // Apply zoom factor to new camera
    //
    self.zoomFactor = self.zoomFactor;

    // Register for focus changes to adjust field of view
    //
    [self.captureDevice addObserver:self forKeyPath:@"lensPosition" options:NSKeyValueObservingOptionInitial context:&FOVARViewKVOContext];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:nil];
    
    [self.captureSession addInput:newVideoInput];
    
    self.captureLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    self.captureLayer.frame = self.captureView.bounds;
    self.captureLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.captureView.layer addSublayer:self.captureLayer];
    
    // Start the session.
    //
    // This is done asychronously since -startRunning
    // doesn't return until the session is running.
    //
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self.captureSession startRunning];
    });
}

- (void)stopCameraPreview {
    
    [self.captureSession stopRunning];
    [self.captureLayer removeFromSuperlayer];
    
    self.captureLayer = nil;
    self.captureSession = nil;
    
    [self.captureDevice removeObserver:self forKeyPath:@"lensPosition"];
    
    self.captureDevice = nil;
}

#pragma mark - Motion handling

- (void)startDeviceMotion {
    
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.showsDeviceMovementDisplay = YES;
    self.motionManager.deviceMotionUpdateInterval = 1.0 / 60.0;

    // When available use compass to have x axis pointing to magnetic north
    //
    CMAttitudeReferenceFrame referenceFrame;
    
    if (self.isMagenticNorthAvailable) {
        
        referenceFrame = self.isUsingTrueNorth ? CMAttitudeReferenceFrameXTrueNorthZVertical : CMAttitudeReferenceFrameXMagneticNorthZVertical;

    } else {

        referenceFrame = CMAttitudeReferenceFrameXArbitraryZVertical;
    }
    
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:referenceFrame];
}

- (void)stopDeviceMotion {
    
    [self.motionManager stopDeviceMotionUpdates];
    
    self.motionManager = nil;
}

- (void)restartDeviceMotionIfNecessary {

    if (self.motionManager) {
        
        [self stopDeviceMotion];
        [self startDeviceMotion];
    }
}

#pragma mark - Redraw handling

- (void)startDisplayLink {
    
	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onDisplayLink:)];

	[self.displayLink setFrameInterval:1];
	[self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)stopDisplayLink {
    
    [self.displayLink invalidate];
    
    self.displayLink = nil;
}

- (void)onDisplayLink:(id)sender {
    
    CMDeviceMotion *d = self.motionManager.deviceMotion;
    
    if (d != nil) {
        
        CMRotationMatrix r = d.attitude.rotationMatrix;

        _cameraTransform = GLKMatrix4MakeAndTranspose(r.m11, r.m12, r.m13, 0.0, r.m21, r.m22, r.m23, 0.0, r.m31, r.m32, r.m33, 0.0, 0.0, 0.0, 0.0, 1.0);
    }

    // Trigger -glkView:drawInRect:
    //
    [self.renderView setNeedsDisplay];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    // Compute modelview and projection matrices
    // and use them to transform overlay views
    // as well as GL overlay shapes
    //
    GLKMatrix4 cameraMatrix = GLKMatrix4Multiply(_cameraTransform, _userTransformation);

    _viewMatrix = GLKMatrix4Multiply(_deviceTransform, cameraMatrix);
    
    self.containerView.overlayTransformation = GLKMatrix4Multiply(_projectionMatrix, _viewMatrix);

    bool inverted;

    GLKMatrix4 inverseView = GLKMatrix4Invert(_viewMatrix, &inverted);
    
    if (inverted) {
        
        GLKVector3 xAxis = GLKVector3Make(1, 0, 0);
        GLKVector3 northAxis = GLKMatrix4MultiplyVector3(inverseView, xAxis);
        
        northAxis.z = 0.0;
        northAxis = GLKVector3Normalize(northAxis);

        float northDot = GLKVector3DotProduct(northAxis, xAxis);
        float northAngle = GLKMathRadiansToDegrees(acosf(northDot));
        
        if (northAxis.y > 0.0) northAngle = 360.0 - northAngle;

        northAngle -= 90.0;

        if (northAngle < 0.0) northAngle += 360.0;
        
        [self.compass setHeadingAngle:northAngle];
    }
    
    // Trigger container's -drawRect:
    //
    [self.containerView setNeedsDisplay];
    
    [self drawShapes:NO];
}

- (void)drawShapes:(BOOL)picking {
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
   
    if (picking) {

        glClearColor(1.0f, 1.0f, 1.0f, picking ? 1.0f : 0.0f);
        
    } else {
        
        glClearColor(0.0f, 0.0f, 0.0f, picking ? 1.0f : 0.0f);
    }

    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    for (NSInteger idx = 0; idx < self.overlayShapes.count; idx++) {
        
        TGLARShapeOverlay *shape = self.overlayShapes[idx];
        
        shape.viewMatrix = _viewMatrix;
        shape.projectionMatrix = _projectionMatrix;
        
        if (picking) {

            // TODO: idx > 254
            //
            [shape drawUsingConstantColor:GLKVector4Make((idx + 1) / 255.0f, 0.0f, 0.0f, 0.0f)];

        } else {
            
            [shape draw];
        }
    }
}

#pragma mark - Pick handling

// See http://stackoverflow.com/a/10784181

- (TGLARShapeOverlay *)findShapeAtPoint:(CGPoint)point {
    
    [EAGLContext setCurrentContext:self.renderContext];

    NSInteger height = self.renderView.drawableHeight;
    NSInteger width = self.renderView.drawableWidth;

    GLuint framebuffer;

    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

    GLuint colorRenderbuffer;

    glGenRenderbuffers(1, &colorRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, (GLsizei)width, (GLsizei)height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
    
    GLuint depthRenderbuffer;

    glGenRenderbuffers(1, &depthRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, (GLsizei)width, (GLsizei)height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);

    if (status != GL_FRAMEBUFFER_COMPLETE) {

        NSLog(@"Framebuffer status: %x", (int)status);
        return nil;
    }
    
    [self drawShapes:YES];
    
    Byte pixelColor[4] = {0,};
    CGFloat scale = UIScreen.mainScreen.scale;

    glReadPixels(point.x * scale, (height - (point.y * scale)), 1, 1, GL_RGBA, GL_UNSIGNED_BYTE, pixelColor);

    //NSLog(@"%s Pixel color @ %@: %x %x %x %x", __PRETTY_FUNCTION__, NSStringFromCGPoint(point), pixelColor[0], pixelColor[1], pixelColor[2], pixelColor[3]);
    
    glDeleteRenderbuffers(1, &depthRenderbuffer);
    glDeleteRenderbuffers(1, &colorRenderbuffer);
    glDeleteFramebuffers(1, &framebuffer);
    
    [self.renderView bindDrawable];

    NSInteger idx = pixelColor[0];
    
    return (idx > 0 && idx <= self.overlayShapes.count) ? self.overlayShapes[idx-1] : nil;
}

#pragma mark - Projection matrix handling

- (void)computeFovFromCameraFormat {
    
    if (self.captureDevice) {
        
        CGFloat aspectRatio = self.bounds.size.width / self.bounds.size.height;
        
        if (aspectRatio > 1.0) aspectRatio = 1.0 / aspectRatio;
        
        AVCaptureDeviceFormat *activeFormat = self.captureDevice.activeFormat;
        CGFloat activeFOV = GLKMathRadiansToDegrees(2.0 * atan(tan(0.5 * GLKMathDegreesToRadians(activeFormat.videoFieldOfView)) / self.captureDevice.videoZoomFactor));
        
        CMFormatDescriptionRef description = activeFormat.formatDescription;
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(description);

        CGFloat aspectWidth = (CGFloat)dimensions.height / aspectRatio;
        CGFloat aspectHeight = (CGFloat)dimensions.width * aspectRatio;
        
        CGFloat aspectFOV;
        
        if (aspectWidth < dimensions.width) {
            
            aspectFOV = GLKMathRadiansToDegrees(2.0 * atan(aspectWidth / (CGFloat)dimensions.width * tan(0.5 * GLKMathDegreesToRadians(activeFOV))));
            
        } else if (aspectHeight < dimensions.height) {
            
            aspectFOV = activeFOV;
            
        } else {
            
            aspectFOV = activeFOV;
        }
        
        self.verticalFovPortrait = aspectFOV;
        self.verticalFovLandscape = GLKMathRadiansToDegrees(2.0 * atan(tan(0.5 * GLKMathDegreesToRadians(aspectFOV)) * aspectRatio));
        
        if ([self.compass respondsToSelector:@selector(setFieldOfView:)]) {
            
            [self.compass setFieldOfView:self.effectiveHorizontalFov];
        }
    }
}

- (void)updateProjectionMatrix {
    
    // Initialize camera & projection matrix
    //
    CGFloat fovy = self.effectiveVerticalFov;
    CGFloat aspect = self.bounds.size.width / self.bounds.size.height;
    
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fovy), aspect, 1.0f, 10000.0f);
}

- (void)updateUserTransformation {
    
    GLKMatrix4 rotation = GLKMatrix4MakeRotation(self.headingOffset / 180.0 * M_PI, 0.0, 0.0, 1.0);
    GLKMatrix4 translation = GLKMatrix4MakeTranslation(-self.positionOffset.width, -self.positionOffset.height, -self.heightOffset);
    
    _userTransformation = GLKMatrix4Multiply(rotation, translation);
}

#pragma mark - Key-value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {

    if (context == &FOVARViewKVOContext && [keyPath isEqualToString:@"lensPosition"]) {
            
        CGFloat scale = 1.0 + self.captureDevice.lensPosition * kFOVARViewLensAdjustmentFactor;
        
        self.fovScalePortrait = self.fovScaleLandscape = scale;

    } else if ([super respondsToSelector:@selector(observeValueForKeyPath:ofObject:change:context:)]) {
        
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Helpers

- (CGFloat)effectiveVerticalFov {
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        
        return self.fovScalePortrait * self.verticalFovPortrait;
        
    } else {
        
        return self.fovScaleLandscape * self.verticalFovLandscape;
    }
}

- (CGFloat)effectiveHorizontalFov {
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        
        return self.fovScalePortrait * self.verticalFovLandscape;
        
    } else {
        
        return self.fovScaleLandscape * self.verticalFovPortrait;
    }
}

@end
