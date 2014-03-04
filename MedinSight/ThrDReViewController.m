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


@interface ThrDReViewController()
{
    ColoredVertexData3D *vertexsDataArrayPtr;
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
    
    //init the MarchingCube
    MarchingCubeFuntion *marchingCubeMachine = [[MarchingCubeFuntion alloc] initWithData:self.images256Volume
                                                                                  Height:volumeSidesLength.Height
                                                                                   Length:volumeSidesLength.Length
                                                                               andWidth:volumeSidesLength.Width];
    vertexsDataArrayPtr = [marchingCubeMachine callvMarchingCubes];
    int numOfVertexs = [marchingCubeMachine getNumOfVertexs];
    
    
    // Verify the type of view created automatically by the
    // Interface Builder storyboard
    GLKView *view = (GLKView *)self.view;
    NSAssert([view isKindOfClass:[GLKView class]],
             @"View controller's view is not a GLKView");
    
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
    self.baseEffect.useConstantColor = GL_TRUE;
    self.baseEffect.constantColor = GLKVector4Make(
                                                   0.0f, // Red
                                                   0.0f, // Green
                                                   0.0f, // Blue
                                                   1.0f);// Alpha
    
    // Set the background color stored in the current context
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f); // background color
    
    // Generate, bind, and initialize contents of a buffer to be
    // stored in GPU memory
    glGenBuffers(1,                // STEP 1
                 &vertexBufferID);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER,  // STEP 2
                 vertexBufferID);
    glBufferData(                  // STEP 3
                 GL_ELEMENT_ARRAY_BUFFER,  // Initialize buffer contents
                 numOfVertexs * sizeof(ColoredVertexData3D), // Number of bytes to copy
                 vertexsDataArrayPtr,         // Address of bytes to copy
                 GL_STATIC_DRAW);  // Hint: cache in GPU memory
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
    //glEnableVertexAttribArray(GLKVertexAttribColor);

    
    // STEP 5
    glVertexAttribPointer(GLKVertexAttribPosition,
                          3,                   // three components per vertex
                          GL_FLOAT,            // data is floating point
                          GL_FALSE,            // no fixed point scaling
                          sizeof(ColoredVertexData3D), //
                          &vertexsDataArrayPtr[0].vertex);               // NULL tells GPU to start at beginning of bound buffer
    
    
    glVertexAttribPointer(GLKVertexAttribNormal,
                          3,                   // three components per vertex
                          GL_FLOAT,            // data is floating point
                          GL_FALSE,            // no fixed point scaling
                          sizeof(ColoredVertexData3D), //
                          &vertexsDataArrayPtr[0].normal);
    
    
//    glVertexAttribPointer(GLKVertexAttribColor,
//                          4,                   // three components per vertex
//                          GL_FLOAT,            // data is floating point
//                          GL_FALSE,            // no fixed point scaling
//                          sizeof(ColoredVertexData3D), //
//                          &vertexsDataArrayPtr[0].color);
    
    [self.baseEffect prepareToDraw];
    
    // Clear Frame Buffer (erase previous drawing)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Draw triangles using the first three vertices in the
    // currently bound vertex buffer
    glDrawArrays(GL_TRIANGLES,      // STEP 6
                 0,  // Start with first vertex in currently bound buffer
                 3); // Use three vertices from currently bound buffer
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    glDisableVertexAttribArray(GLKVertexAttribNormal);
    //glDisableVertexAttribArray(GLKVertexAttribColor);
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
