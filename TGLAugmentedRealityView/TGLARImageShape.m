//
//  TGLARImageShape.m
//  TGLAugmentedRealityView
//
//  Created by Tim Gleue on 12.11.15.
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

#import "TGLARImageShape.h"

// GL data
//
typedef struct {
    
    float Position[3];
    float Texture[2];
    float Normal[3];
    
} Vertex;

static const Vertex Vertices[] = {
    
    { { 0, +1, -1 }, { 1, 1 }, { 1, 0, 0 } },
    { { 0, +1, +1 }, { 1, 0 }, { 1, 0, 0 } },
    { { 0, -1, +1 }, { 0, 0 }, { 1, 0, 0 } },
    { { 0, -1, -1 }, { 0, 1 }, { 1, 0, 0 } }
};

static const GLubyte Indices[] = { 0, 1, 2, 2, 3, 0 };

static GLuint indexBuffer = 0;
static NSUInteger bufferCount = 0;

@interface TGLARImageShape () {
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
};

@property (strong, nonatomic) GLKTextureInfo *textureInfo;

@end

@implementation TGLARImageShape

- (instancetype)initWithContext:(EAGLContext *)context size:(CGSize)size image:(UIImage *)image {
    
    self = [super initWithContext:context];
    
    if (self) {

        self.effect.constantColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
        
        self.image = image;
        
        float w2 = 0.5 * size.width;
        float h2 = 0.5 * size.height;
        
        static Vertex bgVertices[4];
        
        for (NSUInteger idx = 0; idx < 4; idx++) {
            
            bgVertices[idx].Position[0] = Vertices[idx].Position[0];
            bgVertices[idx].Position[1] = Vertices[idx].Position[1] * w2;
            bgVertices[idx].Position[2] = Vertices[idx].Position[2] * h2;
            
            bgVertices[idx].Texture[0] = Vertices[idx].Texture[0];
            bgVertices[idx].Texture[1] = Vertices[idx].Texture[1];
            
            bgVertices[idx].Normal[0] = Vertices[idx].Normal[0];
            bgVertices[idx].Normal[1] = Vertices[idx].Normal[1];
            bgVertices[idx].Normal[2] = Vertices[idx].Normal[2];
        }
        
        glGenBuffers(1, &_vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(bgVertices), bgVertices, GL_STATIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
        
        if (indexBuffer == 0) {
            
            glGenBuffers(1, &indexBuffer);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        }
        
        ++bufferCount;
    }
    
    return self;
}

- (void)dealloc {
    
    if (self.context) {
        
        [EAGLContext setCurrentContext:self.context];
        
        [self freeImage];

        glDeleteBuffers(1, &_vertexBuffer); _vertexBuffer = 0;
        
        if (bufferCount > 0) --bufferCount;
        
        if (bufferCount == 0) {
            
            glDeleteBuffers(1, &indexBuffer);
            indexBuffer = 0;
        }
    }
}

#pragma mark - Methods

- (BOOL)setImage:(UIImage *)image {
    
    [EAGLContext setCurrentContext:self.context];
    
    [self freeImage];
    
    if (image == nil) return YES;
    
    NSError *error = nil;
    
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
    
    if (textureInfo) {
        
        self.textureInfo = textureInfo;
        
        self.effect.texture2d0.name = self.textureInfo.name;
        self.effect.texture2d0.target = self.textureInfo.target;
        self.effect.texture2d0.envMode = GLKTextureEnvModeReplace;
        self.effect.texture2d0.enabled = GL_TRUE;
        
        return YES;
        
    } else {
        
        NSLog(@"%s Texture image could not be loaded: %@", __PRETTY_FUNCTION__, error.localizedDescription);
        
        self.effect.texture2d0.enabled = GL_FALSE;
        
        return NO;
    }
}

- (BOOL)draw {
    
    if (![super draw]) return NO;
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Position));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Texture));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Normal));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
    
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    glDisableVertexAttribArray(GLKVertexAttribNormal);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

    return YES;
}

- (BOOL)drawUsingConstantColor:(GLKVector4)color {

    GLKVector4 constantColor = self.effect.constantColor;
    GLboolean useConstantColor = self.effect.useConstantColor;
    GLboolean texture2d0Enabled = self.effect.texture2d0.enabled;
    
    self.effect.constantColor = color;
    self.effect.useConstantColor = GL_TRUE;
    self.effect.texture2d0.enabled = GL_FALSE;
    
    BOOL ok = [super drawUsingConstantColor:color];
    
    if (ok) {
        
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Position));
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *)offsetof(Vertex, Normal));
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        
        glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
        
        glDisableVertexAttribArray(GLKVertexAttribNormal);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    
    self.effect.texture2d0.enabled = texture2d0Enabled;
    self.effect.useConstantColor = useConstantColor;
    self.effect.constantColor = constantColor;
    
    return ok;
}

#pragma mark - Helpers

- (void)freeImage {
    
    if (self.textureInfo) {
        
        // KLUDGE: Get rid of previous texture memory,
        //         but there seems to be no official
        //         way to release a GLKTextureInfo
        //         allocated by GLKTextureLoader...
        //
        // See: http://stackoverflow.com/a/8720298
        //
        GLuint name = self.textureInfo.name;
        
        glDeleteTextures(1, &name);
        
        self.textureInfo = nil;
    }
    
    self.effect.texture2d0.enabled = GL_FALSE;
}

@end
