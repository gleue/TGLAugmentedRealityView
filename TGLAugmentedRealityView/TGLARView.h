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

@protocol TGLARViewDataSource <NSObject>

- (NSInteger)numberOfOverlaysInARView:(TGLARView *)arview;
- (id<TGLAROverlay>)arView:(TGLARView *)arview overlayAtIndex:(NSInteger)index;

@end

@protocol TGLARViewDelegate <NSObject>

@optional

- (void)arViewWillBeginUpdatingOffsets:(TGLARView *)arview;
- (void)arViewDidUpdateOffsets:(TGLARView *)arview;
- (void)arViewDidEndUpdatingOffsets:(TGLARView *)arview;

- (void)arViewWillBeginZooming:(TGLARView *)arview;
- (void)arViewDidZoom:(TGLARView *)arview;
- (void)arViewDidEndZooming:(TGLARView *)arview atFactor:(CGFloat)zoomFactor;

- (void)arView:(TGLARView *)arview didTapViewOverlay:(TGLARViewOverlay *)view;
- (void)arView:(TGLARView *)arview didTapShapeOverlay:(TGLARShapeOverlay *)shape;

@end

@interface TGLARView : UIView  <GLKViewDelegate>

@property (nonatomic, weak) IBOutlet id<TGLARCompass> compass;
@property (nonatomic, weak) IBOutlet id<TGLARViewDelegate> delegate;
@property (nonatomic, weak) IBOutlet id<TGLARViewDataSource> dataSource;

@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

@property (nonatomic, assign) CGFloat zoomFactor;
@property (nonatomic, readonly) CGFloat maxZoomFactor;

@property (nonatomic, assign) CGFloat heightOffset;
@property (nonatomic, assign) CGFloat headingOffset;
@property (nonatomic, assign) CGSize  positionOffset;

- (EAGLContext *)renderContext;

- (void)start;
- (void)stop;

- (void)reloadData;

@end
