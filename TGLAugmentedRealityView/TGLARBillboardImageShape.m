//
//  TGLARBillboardImageShape.m
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

#import "TGLARBillboardImageShape.h"

@implementation TGLARBillboardImageShape

- (BOOL)draw {

    if (self.locked) return [super draw];

    // Compute billboard transform
    //
    // see http://nehe.gamedev.net/article/billboarding_how_to/18011/
    //
    GLKVector3 pos = self.overlay.targetPosition;
    GLKVector3 look = GLKVector3Normalize(GLKVector3Negate(pos));
    GLKVector3 right = GLKVector3CrossProduct(GLKVector3Make(0, 0, 1), look);
    GLKVector3 up = GLKVector3CrossProduct(look, right);
    
    GLKMatrix4 billboard = GLKMatrix4Make(look.x, look.y, look.z, 0.0, right.x, right.y, right.z, 0.0, up.x, up.y, up.z, 0.0, pos.x, pos.y, pos.z, 1.0);
    GLKMatrix4 transform = self.transform;

    self.transform = GLKMatrix4Multiply(billboard, transform);

    BOOL ok = [super draw];

    self.transform = transform;

    return ok;
}

@end
