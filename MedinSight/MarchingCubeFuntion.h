//
//  MarchingCubeFuntion.h
//  MedinSight
//
//  Created by Liang Zisheng on 2/28/14.
//  Copyright (c) 2014 United-Imaging. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

// This data type is used to store information for each vertex
typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
} Vertex3D;

typedef struct {
    GLfloat x;
    GLfloat y;
    GLfloat z;
} Vector3D;

typedef struct {
    GLfloat r;
    GLfloat g;
    GLfloat b;
    GLfloat a;
} Color3D;

typedef struct {
    Vertex3D    vertex;
    Vector3D    normal;
    Color3D     color;
} ColoredVertexData3D;

@interface MarchingCubeFuntion : NSObject
{
    
}

- (id)initWithData:(Byte ***)images256Volume Height:(int)nz Length:(int)nx andWidth:(int)ny;
- (ColoredVertexData3D *)callvMarchingCubes;
- (int)getNumOfVertexs;

@end
