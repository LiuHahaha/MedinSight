//
//  ThrDReViewController.m
//  MedinSight
//
//  Created by Liang Zisheng on 2/28/14.
//  Copyright (c) 2014 United-Imaging. All rights reserved.
//

#import "ThrDReViewController.h"
#import "MarchingCubeFuntion.h"

/////////////////////////////////////////////////////////////////
// This data type is used to store information for each vertex
//typedef struct {
//    GLKVector3  positionCoords;
//}
//SceneVertex;
//
///////////////////////////////////////////////////////////////////
//// Define vertex data for a triangle to use in example
//static const SceneVertex vertices[] =
//{
//    {{-0.5f, -0.5f, 0.0}}, // lower left corner
//    {{ 0.5f, -0.5f, 0.0}}, // lower right corner
//    {{-0.5f,  0.5f, 0.0}}  // upper left corner
//};

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



ColoredVertexData3D testDataArray[3];

@interface ThrDReViewController()
{
    ColoredVertexData3D *vertexsDataArrayPtr;
    int numOfVertexs;
}

@end
@implementation ThrDReViewController

@synthesize baseEffect;

- (void)setVolumeSidesLengthWithHeight:(int)z Length:(int)x Width:(int)y
{
    volumeSidesLength.Length = x;
    volumeSidesLength.Width = y;
    volumeSidesLength.Height = z;
    
    NSLog(@"%d,%d,%d", z, x, y);

}

#pragma mark View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //testArray
//    testDataArray[0].vertex.x = -0.5f;
//    testDataArray[0].vertex.y = -0.5f;
//    testDataArray[0].vertex.z = 0.0;
//    
//    testDataArray[1].vertex.x = 0.5f;
//    testDataArray[1].vertex.y = -0.5f;
//    testDataArray[1].vertex.z = 0.0;
//    
//    testDataArray[2].vertex.x = -0.5f;
//    testDataArray[2].vertex.y = 0.5f;
//    testDataArray[2].vertex.z = 0.0;
    
    //init the MarchingCube
    MarchingCubeFuntion *marchingCubeMachine = [[MarchingCubeFuntion alloc] initWithData:self.images256Volume
                                                                                  Height:volumeSidesLength.Height
                                                                                   Length:volumeSidesLength.Length
                                                                               andWidth:volumeSidesLength.Width];
    vertexsDataArrayPtr = [marchingCubeMachine callvMarchingCubes];
    numOfVertexs = [marchingCubeMachine getNumOfVertexs];
    
  
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
//    self.baseEffect.useConstantColor = GL_TRUE;
//    self.baseEffect.constantColor = GLKVector4Make(
//                                                   0.0f, // Red
//                                                   0.0f, // Green
//                                                   0.0f, // Blue
//                                                   1.0f);// Alpha
    //灯光
    self.baseEffect.light0.enabled = GL_TRUE;
//    self.baseEffect.lightModelTwoSided = GL_TRUE;
    self.baseEffect.light0.ambientColor = GLKVector4Make(0.25f, 0.25f, 0.25f, 1.00f);
    self.baseEffect.light0.diffuseColor = GLKVector4Make(0.75f, 0.75f, 0.75f, 1.00f);
    self.baseEffect.light0.specularColor = GLKVector4Make(1.00, 0.25, 0.25, 1.00);
    self.baseEffect.light0.position = GLKVector4Make(1.0f, 1.0f, 0.5f, 0.0f);
    
    //材质
    self.baseEffect.material.ambientColor = GLKVector4Make(0.25, 0.25, 0.25, 1.00);
    self.baseEffect.material.diffuseColor = GLKVector4Make(0.75, 0.75, 0.75, 1.00);
    self.baseEffect.material.specularColor = GLKVector4Make(1.00, 1.00, 1.00, 1.00);
    self.baseEffect.material.shininess = 10.0f;

    
    // Set the background color stored in the current context
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // background color
    
    // Generate, bind, and initialize contents of a buffer to be
    // stored in GPU memory
    glGenBuffers(1,                // STEP 1
                 &vertexBufferID);
    glBindBuffer(GL_ARRAY_BUFFER,  // STEP 2
                 vertexBufferID);
    glBufferData(                  // STEP 3
                 GL_ARRAY_BUFFER,  // Initialize buffer contents
                 numOfVertexs * sizeof(ColoredVertexData3D), // Number of bytes to copy
                 vertexsDataArrayPtr,         // Address of bytes to copy
                 GL_STATIC_DRAW);  // Hint: cache in GPU memory
    
    glEnable(GL_DEPTH_TEST);
}


/////////////////////////////////////////////////////////////////
// GLKView delegate method: Called by the view controller's view
// whenever Cocoa Touch asks the view controller's view to
// draw itself. (In this case, render into a frame buffer that
// shares memory with a Core Animation Layer)
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // STEP 4
    // Enable use of positions from bound vertex buffer
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glEnableVertexAttribArray(GLKVertexAttribColor);

    
    // STEP 5
    glVertexAttribPointer(GLKVertexAttribPosition,
                          3,                   // three components per vertex
                          GL_FLOAT,            // data is floating point
                          GL_FALSE,            // no fixed point scaling
                          sizeof(ColoredVertexData3D), // no gaps in data
                          NULL
                          );               // NULL tells GPU to start at beginning of bound buffer
    
    
    glVertexAttribPointer(GLKVertexAttribNormal,
                          3,                   // three components per vertex
                          GL_FLOAT,            // data is floating point
                          GL_FALSE,            // no fixed point scaling
                          sizeof(ColoredVertexData3D), //
                          (GLvoid*) (3*sizeof(Vertex3D))
                          );
    
    
    glVertexAttribPointer(GLKVertexAttribColor,
                          4,                   // three components per vertex
                          GL_FLOAT,            // data is floating point
                          GL_FALSE,            // no fixed point scaling
                          sizeof(ColoredVertexData3D), //
                          (GLvoid*) (3*sizeof(Vertex3D) + 3*sizeof(Vector3D))
                          );
    
    [self.baseEffect prepareToDraw];
    
    // Clear Frame Buffer (erase previous drawing)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    
    // Scale the Y coordinate based on the aspect ratio of the
    // view's Layer which matches the screen aspect ratio for
    // this example
    const GLfloat  aspectRatio =
    (GLfloat)view.drawableWidth / (GLfloat)view.drawableHeight;
    
    GLKMatrix4 scaleProjectionMatrix = GLKMatrix4MakeScale(1.0f, aspectRatio, 1.0f);
//
    self.baseEffect.transform.projectionMatrix = scaleProjectionMatrix;
    
    //scale
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(1.0f / (volumeSidesLength.Length/2),
                                                 1.0f / (volumeSidesLength.Length/2),
                                                 1.0f / (volumeSidesLength.Length/2));
    //transform
    GLKMatrix4 transformMatrix = GLKMatrix4MakeTranslation(-volumeSidesLength.Length/2, -volumeSidesLength.Width/2, -volumeSidesLength.Height/2);
    //rotate
    GLKMatrix4 rotateMatrixAboutX = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(-90.0f), 1.0, 0.0, 0.0);
    GLKMatrix4 rotateMatrixAboutY = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(90.0f), 0.0, 1.0, 0.0);
    GLKMatrix4 rotateMatrix = GLKMatrix4Multiply(rotateMatrixAboutY, rotateMatrixAboutX);
//    self.baseEffect.transform.modelviewMatrix = GLKMatrix4Multiply(rotateMatrixAboutX, rotateMatrixAboutY);
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4Multiply(GLKMatrix4Multiply(rotateMatrix, scaleMatrix), transformMatrix);
    
    
    // Draw triangles using the first three vertices in the
    // currently bound vertex buffer
    glDrawArrays(GL_TRIANGLES,      // STEP 6
                 0,  // Start with first vertex in currently bound buffer
                 numOfVertexs); // Use three vertices from currently bound buffer
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribNormal);
    glDisableVertexAttribArray(GLKVertexAttribColor);
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
    if (0 != vertexBufferID)
    {
        glDeleteBuffers (1,          // STEP 7 
                         &vertexBufferID);  
        vertexBufferID = 0;
    }
    
    // Stop using the context created in -viewDidLoad
    ((GLKView *)self.view).context = nil;
    [EAGLContext setCurrentContext:nil];
}




@end
