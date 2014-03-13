//
//  ThrDReViewController.m
//  MedinSight
//
//  Created by Liang Zisheng on 2/28/14.
//  Copyright (c) 2014 United-Imaging. All rights reserved.
//

#import "ThrDReViewController.h"
#import "MarchingCubeFuntion.h"
#import "AGLKVertexAttribArrayBuffer.h"


static const GLfloat afAmbientWhite [] = {0.25, 0.25, 0.25, 1.00};   // 周围 环绕 白
static const GLfloat afAmbientRed   [] = {0.25, 0.00, 0.00, 1.00};   // 周围 环绕 红
static const GLfloat afAmbientGreen [] = {0.00, 0.25, 0.00, 1.00};   // 周围 环绕 绿
static const GLfloat afAmbientBlue  [] = {0.00, 0.00, 0.25, 1.00};   // 周围 环绕 蓝
static const GLfloat afDiffuseWhite [] = {0.75, 0.75, 0.75, 1.00};   // 漫射 白
static const GLfloat afDiffuseRed   [] = {0.75, 0.00, 0.00, 1.00};   // 漫射 红
static const GLfloat afDiffuseGreen [] = {0.00, 0.75, 0.00, 1.00};   // 漫射 绿
static const GLfloat afDiffuseBlue  [] = {0.00, 0.00, 0.75, 1.00};   // 漫射 蓝
static const GLfloat afSpecularWhite[] = {1.00, 1.00, 1.00, 1.00};   // 反射 白
static const GLfloat afSpecularRed  [] = {1.00, 0.25, 0.25, 1.00};   // 反射 红
static const GLfloat afSpecularGreen[] = {0.25, 1.00, 0.25, 1.00};   // 反射 绿
static const GLfloat afSpecularBlue [] = {0.25, 0.25, 1.00, 1.00};   // 反射 蓝



@interface ThrDReViewController()
{
    GLfloat *vertexsDataArrayPtr;
    GLfloat *normalsDataArrayPtr;
    
    int numberOfVertices;
    
    float _rotation;
}
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexPositionBuffer;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer *vertexNormalBuffer;
@property (nonatomic) GLKMatrixStackRef modelviewMatrixStack;

- (void)initDataEntrance;

@end



@implementation ThrDReViewController

@synthesize baseEffect;
@synthesize vertexPositionBuffer;
@synthesize vertexNormalBuffer;
@synthesize modelviewMatrixStack;

#pragma mark initDataInfo
//设置接受的数据体的边长
- (void)setVolumeSidesLengthWithHeight:(int)z Width:(int)y Length:(int)x
{
    volumeSidesLength.Length = x;
    volumeSidesLength.Width = y;
    volumeSidesLength.Height = z;
    
    NSLog(@"%d,%d,%d", z, x, y);

}
- (void)initDataEntrance
{
    //init the MarchingCube
    MarchingCubeFuntion *marchingCubeMachine = [[MarchingCubeFuntion alloc] initWithData:self.images256Volume
                                                                                  Height:volumeSidesLength.Height
                                                                                   Width:volumeSidesLength.Width
                                                                               andLength:volumeSidesLength.Length];
    
    numberOfVertices = [marchingCubeMachine callvMarchingCubesWith:&vertexsDataArrayPtr
                                                               And:&normalsDataArrayPtr];
}


#pragma mark OpenGL ES function
// Setup a light to simulate the Sun
- (void)configureLight
{
    self.baseEffect.light0.enabled = GL_TRUE;
    self.baseEffect.light0.diffuseColor = GLKVector4Make(
                                                         1.0f, // Red
                                                         1.0f, // Green
                                                         1.0f, // Blue
                                                         1.0f);// Alpha
    self.baseEffect.light0.position = GLKVector4Make(
                                                     1.0f,  
                                                     0.0f,  
                                                     0.8f,  
                                                     0.0f);
    self.baseEffect.light0.ambientColor = GLKVector4Make(
                                                         0.2f, // Red 
                                                         0.2f, // Green 
                                                         0.2f, // Blue 
                                                         1.0f);// Alpha
    
//    //灯光
//    self.baseEffect.light0.enabled = GL_TRUE;
//    //    self.baseEffect.lightModelTwoSided = GL_TRUE;
//    self.baseEffect.light0.position = GLKVector4Make(1.0f, 1.0f, 0.5f, 0.0f);
//    
//    //灯光属性
//    //    self.baseEffect.light0.ambientColor = GLKVector4Make(0.25f, 0.25f, 0.25f, 1.00f);
//    //    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.00f);
//    //    self.baseEffect.light0.specularColor = GLKVector4Make(1.00, 0.25, 0.25, 1.00);
//    
//    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.7f, 0.7f, 0.7f, 1.0f);
//    
//    //材质
//    //    self.baseEffect.colorMaterialEnabled = GL_TRUE;
//    //    self.baseEffect.material.ambientColor = GLKVector4Make(0.25, 0.25, 0.25, 1.00);
//    //    self.baseEffect.material.diffuseColor = GLKVector4Make(0.75, 0.75, 0.75, 1.00);
//    //    self.baseEffect.material.specularColor = GLKVector4Make(1.00, 1.00, 1.00, 1.00);
//    //    self.baseEffect.material.shininess = 10.0f;

}


- (void)takeShouldUsePerspectiveFrom:(BOOL)aControl;
{
    GLfloat   aspectRatio =
    (float)((GLKView *)self.view).drawableWidth /
    (float)((GLKView *)self.view).drawableHeight;
    
    if(aControl)
    {
//        self.baseEffect.transform.projectionMatrix =
//        GLKMatrix4MakeFrustum(
//                              -1.0 * aspectRatio,
//                              1.0 * aspectRatio,
//                              -1.0,
//                              1.0,
//                              1.0,
//                              120.0);

        GLfloat size = .01 * tanf(GLKMathDegreesToRadians(45.0) / 2.0);
        self.baseEffect.transform.projectionMatrix =
        GLKMatrix4MakeFrustum(
                              -size *aspectRatio,                           // Left
                              size *aspectRatio,                            // Right
                              -size,                                        // Bottom
                              size,                                         // Top
                              .01,                                          // Near
                              1000.0);                                      // Far
    }
    else
    {
        self.baseEffect.transform.projectionMatrix =
        GLKMatrix4MakeOrtho(
                            -1.0 * aspectRatio,
                            1.0 * aspectRatio, 
                            -1.0, 
                            1.0, 
                            1.0,
                            120.0);  
    }
}

#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
   
    [self initDataEntrance];
    
    self.modelviewMatrixStack = GLKMatrixStackCreate(kCFAllocatorDefault);
  
    // Verify the type of view created automatically by the
    // Interface Builder storyboard
    GLKView *view = (GLKView *)self.view;
    NSAssert([view isKindOfClass:[GLKView class]],
             @"View controller's view is not a GLKView");
    
    
    // 使用深度缓存
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    // Create an OpenGL ES 2.0 context and provide it to the
    // view
    view.context = [[EAGLContext alloc]
                    initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    // Make the new context current
    [EAGLContext setCurrentContext:view.context];
    
    // Create a base effect that provides standard OpenGL ES 2.0
    // Shading Language programs and set constants to be used for
    // all subsequent rendering
    self.baseEffect = [[GLKBaseEffect alloc] init];

    // Setup a light to simulate the Sun
    [self configureLight];
    
    // Set a reasonable initial projection
    self.baseEffect.transform.projectionMatrix =
    GLKMatrix4MakeOrtho(
                        -1.0 * 4.0 / 3.0,
                        1.0 * 4.0 / 3.0,
                        -1.0,
                        1.0,
                        1.0,
                        120.0);
    
    // Position scene with Earth near center of viewing volume
    self.baseEffect.transform.modelviewMatrix = 
    GLKMatrix4MakeTranslation(0.0f, 0.0f, -5.0);
    
    // Set the background color stored in the current context
    glClearColor(0.7f, 0.7f, 0.7f, 10.7f); // background color
    
    // Create vertex buffers containing vertices to draw
    self.vertexPositionBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                                 initWithAttribStride:(3 * sizeof(GLfloat))
                                 numberOfVertices:numberOfVertices
                                 bytes:vertexsDataArrayPtr
                                 usage:GL_STATIC_DRAW];
    self.vertexNormalBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                               initWithAttribStride:(3 * sizeof(GLfloat))
                               numberOfVertices:numberOfVertices
                               bytes:normalsDataArrayPtr
                               usage:GL_STATIC_DRAW];
    
    
    // Initialize the matrix stack
    GLKMatrixStackLoadMatrix4(
                              self.modelviewMatrixStack,
                              self.baseEffect.transform.modelviewMatrix);
    
}

/////////////////////////////////////////////////////////////////
// Draw the Rebuild image
- (void)drawReconstructedImage
{
    [self takeShouldUsePerspectiveFrom:YES];
    
    GLKMatrixStackPush(self.modelviewMatrixStack);
    
    GLKMatrixStackRotate(   // Rotate the thing to face forward
                         self.modelviewMatrixStack,
                         GLKMathDegreesToRadians(-90),
                         1.0, 0.0, 0.0);
    GLKMatrixStackTranslate(// Translate to distance from Earth
                            self.modelviewMatrixStack,
                            0.0, 0.0, 0.0);
    GLKMatrixStackScale(    // Scale to size of Moon
                        self.modelviewMatrixStack,
                        1.0f / (volumeSidesLength.Length/2),
                        1.0f / (volumeSidesLength.Length/2),
                        1.0f / (volumeSidesLength.Length/2));
    GLKMatrixStackRotate(   // Rotate the thing on its own axis
                         self.modelviewMatrixStack,
                         GLKMathDegreesToRadians(_rotation),
                         0.0, 0.0, 1.0);
    
    self.baseEffect.transform.modelviewMatrix =
    GLKMatrixStackGetMatrix4(self.modelviewMatrixStack);
    
    [self.baseEffect prepareToDraw];
    
    // Draw triangles using vertices in the prepared vertex
    // buffers
    [AGLKVertexAttribArrayBuffer
     drawPreparedArraysWithMode:GL_TRIANGLES
     startVertexIndex:0
     numberOfVertices:numberOfVertices];
    
    GLKMatrixStackPop(self.modelviewMatrixStack);
    
    self.baseEffect.transform.modelviewMatrix = 
    GLKMatrixStackGetMatrix4(self.modelviewMatrixStack);
}

/////////////////////////////////////////////////////////////////
// GLKView delegate method: Called by the view controller's view
// whenever Cocoa Touch asks the view controller's view to
// draw itself. (In this case, render into a frame buffer that
// shares memory with a Core Animation Layer)
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    _rotation += 1;
    // Clear Frame Buffer (erase previous drawing)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.vertexPositionBuffer
     prepareToDrawWithAttrib:GLKVertexAttribPosition
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];
    [self.vertexNormalBuffer
     prepareToDrawWithAttrib:GLKVertexAttribNormal
     numberOfCoordinates:3
     attribOffset:0
     shouldEnable:YES];
    
    
    [self drawReconstructedImage];

    glEnable(GL_DEPTH_TEST);
}


/////////////////////////////////////////////////////////////////
// Called when the view controller's view has been unloaded
// Perform clean-up that is possible when you know the view
// controller's view won't be asked to draw again soon.
- (void)viewDidUnload
{
    [super viewDidUnload];
    
    // Make the view's context current
    GLKView *view = (GLKView *)self.view;
    [EAGLContext setCurrentContext:view.context];
    
    // Delete buffers that aren't needed when view is unloaded
    self.vertexPositionBuffer = nil;
    self.vertexNormalBuffer = nil;
    
    // Stop using the context created in -viewDidLoad
    ((GLKView *)self.view).context = nil;
    [EAGLContext setCurrentContext:nil];
    
    CFRelease(self.modelviewMatrixStack);
    self.modelviewMatrixStack = NULL;
}

//- (void)update
//{
//    _rotation += 15 * self.timeSinceLastUpdate;
//
//}

@end
