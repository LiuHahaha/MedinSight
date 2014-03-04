//
//  MarchingCubeFuntion.m
//  MedinSight
//
//  Created by Liang Zisheng on 2/28/14.
//  Copyright (c) 2014 United-Imaging. All rights reserved.
//

#import "MarchingCubeFuntion.h"
#import "MCLookUpTable.h"


#define STEP 1
#define UNIT_CUBE_LENGTH 1.0

//向量
typedef struct
{
    GLfloat fX;
    GLfloat fY;
    GLfloat fZ;
}GLvector;

//These tables are used so that everything can be done in little loops that you can look at all at once
// rather than in pages and pages of unrolled code.

//a2fVertexCoordinate lists the positions, relative to vertex0, of each of the 8 vertices of a cube      立方体8个顶点
//  立方体8个顶点
static const GLfloat a2fVertexCoordinate[8][3] =
{
    {0.0, 0.0, 0.0},{UNIT_CUBE_LENGTH, 0.0, 0.0},{UNIT_CUBE_LENGTH, UNIT_CUBE_LENGTH, 0.0},{0.0, UNIT_CUBE_LENGTH, 0.0},
    {0.0, 0.0, UNIT_CUBE_LENGTH},{UNIT_CUBE_LENGTH, 0.0, UNIT_CUBE_LENGTH},{UNIT_CUBE_LENGTH, UNIT_CUBE_LENGTH, UNIT_CUBE_LENGTH},{0.0, UNIT_CUBE_LENGTH, UNIT_CUBE_LENGTH}
};

//a2iEdgeConnection lists the index of the endpoint vertices for each of the 12 edges of the cube    立方体12个边

static const GLint a2iEdgeConnection[12][2] =
{
    {0,1}, {1,2}, {2,3}, {3,0},
    {4,5}, {5,6}, {6,7}, {7,4},
    {0,4}, {1,5}, {2,6}, {3,7}
};

//a2fEdgeDirection lists the direction vector (vertex1-vertex0) for each edge in the cube    立方体 12个边的方向向量
static const GLfloat a2fEdgeDirection[12][3] =
{
    {1.0, 0.0, 0.0},{0.0, 1.0, 0.0},{-1.0, 0.0, 0.0},{0.0, -1.0, 0.0},
    {1.0, 0.0, 0.0},{0.0, 1.0, 0.0},{-1.0, 0.0, 0.0},{0.0, -1.0, 0.0},
    {0.0, 0.0, 1.0},{0.0, 0.0, 1.0},{ 0.0, 0.0, 1.0},{0.0,  0.0, 1.0}
};


GLfloat fTargetValue = 100.0;
Byte ***data;
int NX;
int NY;
int NZ;

ColoredVertexData3D vertexData;
ColoredVertexData3D *vertexsDataArrayPtr;

int numOfVertexs;


NSMutableArray *vertexsDataArray;

@interface MarchingCubeFuntion()
{
}

GLfloat fGetOffset(GLfloat fValue1, GLfloat fValue2, GLfloat fValueDesired);
GLvoid vGetColor(GLvector &rfColor, GLvector &rfPosition, GLvector &rfNormal);
GLvoid vNormalizeVector(GLvector &rfVectorResult, GLvector &rfVectorSource);    // 向量标准化
GLvoid vGetNormal(GLvector &rfNormal, GLfloat fX, GLfloat fY, GLfloat fZ);      // 计算 一点相对于iso的梯度
GLvoid vMarchCube1(GLfloat fX, GLfloat fY, GLfloat fZ, GLfloat fScale);         // Marching Cubes 算法对于一个 单个立方体
GLvoid vMarchingCubes();

void setVertexInVertexData(GLfloat x, GLfloat y, GLfloat z);
void setNormalInVertexData(GLfloat x, GLfloat y, GLfloat z);
void setColorInVertexData(GLfloat x, GLfloat y, GLfloat z);

@end

GLvoid (*vMarchCube)(GLfloat fX, GLfloat fY, GLfloat fZ, GLfloat fScale) = vMarchCube1;

@implementation MarchingCubeFuntion

- (ColoredVertexData3D *)callvMarchingCubes
{
    vMarchingCubes();
    getDataValuesRange();
    return vertexsDataArrayPtr;
}

- (int)getNumOfVertexs
{
    return numOfVertexs;
}

void setVertexInVertexData(GLfloat x, GLfloat y, GLfloat z)
{
    vertexData.vertex.x = x;
    vertexData.vertex.y = y;
    vertexData.vertex.z = z;
}

void setNormalInVertexData(GLfloat x, GLfloat y, GLfloat z)
{
    vertexData.normal.x = x;
    vertexData.normal.y = y;
    vertexData.normal.z = z;
}

void setColorInVertexData(GLfloat r, GLfloat g, GLfloat b)
{
    vertexData.color.r = r;
    vertexData.color.g = g;
    vertexData.color.b = b;
    vertexData.color.a = 1.0f;
}


- (id)initWithData:(Byte ***)images256Volume Height:(int)nz Length:(int)nx andWidth:(int)ny
{
    self = [super init];
    if (self) {
        data = images256Volume;
        NX = nx;
        NY = ny;
        NZ = nz;

    }
    return self;
}

void getDataValuesRange();
void getDataValuesRange()
{
    int min = 255, max = 0;
    for (int z = 0; z < 247; z++) {
        for (int x = 0; x < 512; x++) {
            for (int y = 0; y < 512; y ++) {
                if (min > data[z][x][y]) {
                    min = data[z][x][y];
                }
                if (max < data[z][x][y]) {
                    max = data[z][x][y];
                }
            }
        }
    }
    NSLog(@"range from %d to %d", min, max);
}


#pragma mark Marching Cube 计算相关函数
//************************************************************************************************************************************************
/*                                                             Marching Cube 计算相关函数                                                       */
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//fGetOffset finds the approximate point of intersection of the surface
// between two points with the values fValue1 and fValue2 插值找到边与iso的交点
GLfloat fGetOffset(GLfloat fValue1, GLfloat fValue2, GLfloat fValueDesired)
{
    double fDelta = fValue2 - fValue1;
    
    if(fDelta == 0.0)
    {
        return 0.5;
    }
    return (fValueDesired - fValue1)/fDelta;
}

// 根据 位置 以及 法向量 产生颜色
GLvoid vGetColor(GLvector &rfColor, GLvector &rfPosition, GLvector &rfNormal)
{
    GLfloat fX = rfNormal.fX;
    GLfloat fY = rfNormal.fY;
    GLfloat fZ = rfNormal.fZ;
    rfColor.fX = (fX > 0.0 ? fX : 0.0) + (fY < 0.0 ? -0.5*fY : 0.0) + (fZ < 0.0 ? -0.5*fZ : 0.0);
    rfColor.fY = (fY > 0.0 ? fY : 0.0) + (fZ < 0.0 ? -0.5*fZ : 0.0) + (fX < 0.0 ? -0.5*fX : 0.0);
    rfColor.fZ = (fZ > 0.0 ? fZ : 0.0) + (fX < 0.0 ? -0.5*fX : 0.0) + (fY < 0.0 ? -0.5*fY : 0.0);
}

//向量标准化
GLvoid vNormalizeVector(GLvector &rfVectorResult, GLvector &rfVectorSource)
{
    GLfloat fOldLength;
    GLfloat fScale;
    
    fOldLength = sqrtf( (rfVectorSource.fX * rfVectorSource.fX) +
                       (rfVectorSource.fY * rfVectorSource.fY) +
                       (rfVectorSource.fZ * rfVectorSource.fZ) );
    
    if(fOldLength == 0.0)
    {
        rfVectorResult.fX = rfVectorSource.fX;
        rfVectorResult.fY = rfVectorSource.fY;
        rfVectorResult.fZ = rfVectorSource.fZ;
    }
    else
    {
        fScale = 1.0/fOldLength;
        rfVectorResult.fX = rfVectorSource.fX*fScale;
        rfVectorResult.fY = rfVectorSource.fY*fScale;
        rfVectorResult.fZ = rfVectorSource.fZ*fScale;
    }
}


//vGetNormal() finds the gradient of the scalar field at a point
//This gradient can be used as a very accurate vertx normal for lighting calculations
GLvoid vGetNormal(GLvector &rfNormal, GLfloat fX, GLfloat fY, GLfloat fZ)                   // 计算 一点相对于iso的梯度
{
    if (  fZ>STEP && fZ<NZ-STEP  &&  fX>STEP && fX<NX-STEP  &&  fY>STEP && fY<NY-STEP  )
    {
	    rfNormal.fX = (GLfloat)data[(int)fZ-STEP][(int)fX][(int)fY] - (GLfloat)data[(int)fZ+STEP][(int)fX][(int)fX];
        rfNormal.fY = (GLfloat)data[(int)fZ][(int)fX-STEP][(int)fY] - (GLfloat)data[(int)fZ][(int)fX+STEP][(int)fX];
        rfNormal.fZ = (GLfloat)data[(int)fZ][(int)fX][(int)fY-STEP] - (GLfloat)data[(int)fZ][(int)fX][(int)fX+STEP];
        vNormalizeVector(rfNormal, rfNormal);
    }
}


GLfloat cubeVertexsValue[8]; //存放指定cube的顶点值
GLvector asEdgeVertex[12];   //存放交点的位置
GLvector asEdgeVertexNorm[12];     //存放交点的法向量
//vMarchCube1 performs the Marching Cubes algorithm on a single cube, Marching Cubes 算法对于一个 单个立方体
GLvoid vMarchCube1(GLfloat fX, GLfloat fY, GLfloat fZ, GLfloat fScale)
{
    //查找表
    extern GLint aiCubeEdgeFlags[256];  //用于标记与iso有交点的边
    extern GLint a2iTriangleConnectionTable[256][16];  //根据被标记的边，按照交点组成三角形的顺序，列出交点所在的边
    
    GLint iCorner, iVertex, iEdge, iTriangle, iVertexsFlag, iEdgesFlag;
    GLfloat fOffset;
    GLvector sColor;
    

    
    //Make a local copy of the values at the cube's corners  复制一个Cube 的顶点值
    for(iVertex = 0; iVertex < 8; iVertex++)
    {
        cubeVertexsValue[iVertex] =(GLfloat)data[(int)(fZ + a2fVertexCoordinate[iVertex][0])]
                                                [(int)(fX + a2fVertexCoordinate[iVertex][1])]
                                                [(int)(fY + a2fVertexCoordinate[iVertex][2])] ;
    }
    
    //Find which vertices are inside of the surface and which are outside，如果顶点的值小于iso值，其bit位被置1
    iVertexsFlag = 0;
    for(iVertex = 0; iVertex < 8; iVertex++)
    {
        if(cubeVertexsValue[iVertex] <= fTargetValue)
            iVertexsFlag |= 1<<iVertex;
    }
    
    //Find which edges are intersected by the surface，根据 顶点相对iso的位置 在查找表中找到 表示 cube各边与iso的相交关系
    iEdgesFlag = aiCubeEdgeFlags[iVertexsFlag];
    
    //If the cube is entirely inside or outside of the surface, then there will be no intersections
    if(iEdgesFlag == 0)
    {
        return;
    }
    //Find the point of intersection of the surface with each edge，找到各个交点
    //Then find the normal to the surface at those points，计算各个交点的法向量
    for(iEdge = 0; iEdge < 12; iEdge++)
    {
        //if there is an intersection on this edge
        if(iEdgesFlag & (1<<iEdge))
        {
            int EdgeEndVertex0 = a2iEdgeConnection[iEdge][0];
            int EdgeEndVertex1 = a2iEdgeConnection[iEdge][1];
            
            fOffset = fGetOffset(cubeVertexsValue[EdgeEndVertex0], cubeVertexsValue[EdgeEndVertex1], fTargetValue);
            
            asEdgeVertex[iEdge].fX = fX + (a2fVertexCoordinate[EdgeEndVertex0][0] + fOffset * a2fEdgeDirection[iEdge][0]) ;//* fScale;
            asEdgeVertex[iEdge].fY = fY + (a2fVertexCoordinate[EdgeEndVertex0][1] + fOffset * a2fEdgeDirection[iEdge][1]) ;//* fScale;
            asEdgeVertex[iEdge].fZ = fZ + (a2fVertexCoordinate[EdgeEndVertex0][2] + fOffset * a2fEdgeDirection[iEdge][2]) ;//* fScale;
            
            vGetNormal(asEdgeVertexNorm[iEdge], asEdgeVertex[iEdge].fX, asEdgeVertex[iEdge].fY, asEdgeVertex[iEdge].fZ);
        }
    }
    
   
    //generate the triangles vertexs data that were found.  There can be up to five per cube
    for(iTriangle = 0; iTriangle < 5; iTriangle++)
    {
        if(a2iTriangleConnectionTable[iVertexsFlag][3*iTriangle] < 0)
            break;
        for(iCorner = 0; iCorner < 3; iCorner++)
        {
            iEdge = a2iTriangleConnectionTable[iVertexsFlag][3*iTriangle+iCorner];
            
            vGetColor(sColor, asEdgeVertex[iEdge], asEdgeVertexNorm[iEdge]);
            
            setVertexInVertexData(asEdgeVertex[iEdge].fX, asEdgeVertex[iEdge].fY, asEdgeVertex[iEdge].fZ);
            setNormalInVertexData(asEdgeVertexNorm[iEdge].fX, asEdgeVertexNorm[iEdge].fY, asEdgeVertexNorm[iEdge].fZ);
            setColorInVertexData(sColor.fX, sColor.fY, sColor.fZ);
            
            [vertexsDataArray addObject:[NSValue value:&vertexData withObjCType:@encode(ColoredVertexData3D)]];
            
            
            
//            glColor3f(sColor.fX, sColor.fY, sColor.fZ);
//            glNormal3f(asEdgeVertexNorm[iEdge].fX, asEdgeVertexNorm[iEdge].fY, asEdgeVertexNorm[iEdge].fZ);
//            glVertex3f(asEdgeVertex[iEdge].fX, asEdgeVertex[iEdge].fY, asEdgeVertex[iEdge].fZ);
        }
    }
}

//vMarchingCubes iterates over the entire dataset, calling vMarchCube on each cube

#define THRESHOLD 1
#define RANGE 1
GLvoid vMarchingCubes()
{
    vertexsDataArray = [[NSMutableArray alloc] init];
    GLint iX, iY, iZ;
    for(iZ = 0; iZ < NZ-STEP; iZ++)
        for(iX = 0; iX < NX-STEP; iX++)
            for(iY = 0; iY < NY-STEP; iY++)
            {

                
                vMarchCube(iX, iY, iZ, 1);
            }
    

    
    numOfVertexs = [vertexsDataArray count];
    NSLog(@"num of vertexs: %d", numOfVertexs);
    
    ColoredVertexData3D vertexsData[numOfVertexs];
    for (int i = 0; i < numOfVertexs - 1; i++) {
        [[vertexsDataArray objectAtIndex:i] getValue:&vertexsData[i]];
        [vertexsDataArray removeObject:[vertexsDataArray objectAtIndex:i]];
    }
    
    vertexsDataArrayPtr = vertexsData;
}





@end
