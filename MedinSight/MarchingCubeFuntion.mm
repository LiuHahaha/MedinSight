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
#define UNIT_CUBE_LENGTH 1.0f

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

//阈值，iso的值
GLfloat fTargetValue = 100.0;

//IN, 存放需要重建的数据体
Byte ***data;

//IN, 存放data的边长
int NX;
int NY;
int NZ;


//DEBUG, 顶点个数
int numberOfVertices;

//存放生成的顶点
NSMutableArray *vertexsDataArray;
NSMutableArray *normalsDataArray;

@interface MarchingCubeFuntion()
{
    //OUT，指向顶点数组
    GLfloat *vertexsDataArrayPtr;
    GLfloat *normalsDataArrayPtr;
}

GLfloat fGetOffset(GLfloat fValue1, GLfloat fValue2, GLfloat fValueDesired);    // 线性插值找交点，也可以直接使用中点
GLvoid vGetColor(GLvector &rfColor, GLvector &rfPosition, GLvector &rfNormal);  // 计算一点的颜色，有问题
GLvoid vNormalizeVector(GLvector &rfVectorResult, GLvector &rfVectorSource);    // 向量标准化
GLvoid vGetNormal(GLvector &rfNormal, GLfloat fX, GLfloat fY, GLfloat fZ);      // 计算iso在一点的梯度
GLvoid vMarchCube1(GLfloat fX, GLfloat fY, GLfloat fZ, GLfloat fScale);         // Marching Cubes 算法对于一个 单个立方体
- (GLvoid) vMarchingCubes;



void getDataValuesRange();

@end

GLvoid (*vMarchCube)(GLfloat fX, GLfloat fY, GLfloat fZ, GLfloat fScale) = vMarchCube1;

@implementation MarchingCubeFuntion

- (int)callvMarchingCubesWith:(GLfloat **)aVertexsDataArrayPtr And:(GLfloat **)aNormalsDataArrayPtr
{
    [self vMarchingCubes];
    getDataValuesRange();
    
    *aVertexsDataArrayPtr = vertexsDataArrayPtr;
    *aNormalsDataArrayPtr = normalsDataArrayPtr;
    
    return numberOfVertices;
}



void getDataValuesRange()
{
    int min = 255, max = 0;
    for (int z = 0; z < NZ; z++) {
        for (int y = 0; y < NY; y ++) {
            for (int x = 0; x < NX; x++) {
                if (min > data[z][y][x]) {
                    min = data[z][y][x];
                }
                if (max < data[z][y][x]) {
                    max = data[z][y][x];
                }
            }
        }
    }
    NSLog(@"range from %d to %d", min, max);
}


- (id)initWithData:(Byte ***)images256Volume Height:(int)nz Width:(int)ny andLength:(int)nx
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


//向量标准化
GLvoid vNormalizeVector(GLvector &rfVectorResult, GLvector &rfVectorSource)
{
    GLfloat fOldLength;
    GLfloat fScale;
    
    fOldLength = sqrtf(
                       (rfVectorSource.fX * rfVectorSource.fX) +
                       (rfVectorSource.fY * rfVectorSource.fY) +
                       (rfVectorSource.fZ * rfVectorSource.fZ)
                       );
    
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
    if (  fZ>STEP && fZ<NZ-STEP  &&  fY>STEP && fY<NY-STEP  &&  fX>STEP && fX<NX-STEP  )
    {
        rfNormal.fX = (GLfloat)data[(int)fZ][(int)fY][(int)fX-STEP] - (GLfloat)data[(int)fZ][(int)fY][(int)fX+STEP];
        rfNormal.fY = (GLfloat)data[(int)fZ][(int)fY-STEP][(int)fX] - (GLfloat)data[(int)fZ][(int)fY+STEP][(int)fX];
        rfNormal.fZ = (GLfloat)data[(int)fZ-STEP][(int)fY][(int)fX] - (GLfloat)data[(int)fZ+STEP][(int)fY][(int)fX];

        vNormalizeVector(rfNormal, rfNormal);
    }
}


//vMarchCube1 performs the Marching Cubes algorithm on a single cube, Marching Cubes 算法对于一个 单个立方体
GLvoid vMarchCube1(GLfloat fX, GLfloat fY, GLfloat fZ, GLfloat fScale)
{
    //查找表
    extern GLint aiCubeEdgeFlags[256];  //用于标记与iso有交点的边
    extern GLint a2iTriangleConnectionTable[256][16];  //根据被标记的边，按照交点组成三角形的顺序，列出交点所在的边
    
    GLint iCorner, iVertex, iEdge, iTriangle, iVertexsFlag, iEdgesFlag;
    GLfloat fOffset;
    
    GLfloat cubeVertexsValue[8]; //存放指定cube的顶点值
    GLvector asEdgeVertex[12];   //存放交点的位置
    GLvector asEdgeVertexNorm[12];     //存放交点的法向量
    
    //获取一个Cube的8个顶点值
    for(iVertex = 0; iVertex < 8; iVertex++)
    {
        cubeVertexsValue[iVertex] =(GLfloat)data[(int)(fZ + a2fVertexCoordinate[iVertex][2])]
                                                [(int)(fY + a2fVertexCoordinate[iVertex][1])]
                                                [(int)(fX + a2fVertexCoordinate[iVertex][0])] ;
    }

    
    //判断与iso的关系，如果顶点的值小于iso值(fTargetValue)，其bit位被置1
    iVertexsFlag = 0;
    for(iVertex = 0; iVertex < 8; iVertex++)
    {
        if(cubeVertexsValue[iVertex] <= fTargetValue)
            iVertexsFlag |= 1<<iVertex;
    }
    
    //根据顶点标记情况 在查找表中获得一个值（表示cube各边与iso的相交关系，有交点的边所在bit位被置1）
    iEdgesFlag = aiCubeEdgeFlags[iVertexsFlag];
    
    //If the cube is entirely inside or outside of the surface, then there will be no intersections
    if(iEdgesFlag == 0)
    {
        return;
    }
    //计算iso与各个边的交点座标（计算offset，也可以直接近似为中点）
    //然后计算iso在各个交点处的法向量
    for(iEdge = 0; iEdge < 12; iEdge++)
    {
        //if there is an intersection on this edge
        if(iEdgesFlag & (1<<iEdge))
        {
            int EdgeEndVertex0 = a2iEdgeConnection[iEdge][0];
            int EdgeEndVertex1 = a2iEdgeConnection[iEdge][1];
            
            fOffset = fGetOffset(cubeVertexsValue[EdgeEndVertex0], cubeVertexsValue[EdgeEndVertex1], fTargetValue);

            asEdgeVertex[iEdge].fX = fX + (a2fVertexCoordinate[EdgeEndVertex0][0] + fOffset * a2fEdgeDirection[iEdge][0]) -(float)(NX/2);//* fScale;
            asEdgeVertex[iEdge].fY = fY + (a2fVertexCoordinate[EdgeEndVertex0][1] + fOffset * a2fEdgeDirection[iEdge][1]) -(float)(NY/2);//* fScale;
            asEdgeVertex[iEdge].fZ = fZ + (a2fVertexCoordinate[EdgeEndVertex0][2] + fOffset * a2fEdgeDirection[iEdge][2]) -(float)(NZ/2);//* fScale;
            
            vGetNormal(asEdgeVertexNorm[iEdge],
                       asEdgeVertex[iEdge].fX + (float)(NX/2),
                       asEdgeVertex[iEdge].fY + (float)(NY/2),
                       asEdgeVertex[iEdge].fZ + (float)(NZ/2));
        }
    }
    
   
    //generate the triangles vertexs data that were found.  There can be up to five per cube
    //按照查找表获得交点组成三角形的顺序，每个cube最多有5个三角形
    for(iTriangle = 0; iTriangle < 5; iTriangle++)
    {
        if(a2iTriangleConnectionTable[iVertexsFlag][3*iTriangle] < 0)
            break;

        for(iCorner = 0; iCorner < 3; iCorner++)
        {
            iEdge = a2iTriangleConnectionTable[iVertexsFlag][3*iTriangle+iCorner];
          
            [vertexsDataArray addObject:[NSNumber numberWithFloat:asEdgeVertex[iEdge].fX]];
            [vertexsDataArray addObject:[NSNumber numberWithFloat:asEdgeVertex[iEdge].fY]];
            [vertexsDataArray addObject:[NSNumber numberWithFloat:asEdgeVertex[iEdge].fZ]];
            
            [normalsDataArray addObject:[NSNumber numberWithFloat:asEdgeVertexNorm[iEdge].fX]];
            [normalsDataArray addObject:[NSNumber numberWithFloat:asEdgeVertexNorm[iEdge].fY]];
            [normalsDataArray addObject:[NSNumber numberWithFloat:asEdgeVertexNorm[iEdge].fZ]];

        }

    }
}

//vMarchingCubes iterates over the entire dataset, calling vMarchCube on each cube

#define THRESHOLD 100000
#define RANGE 2
- (GLvoid) vMarchingCubes
{
    vertexsDataArray = [[NSMutableArray alloc] init];
    normalsDataArray = [[NSMutableArray alloc] init];
    GLint iX, iY, iZ;
    for(iZ = 0; iZ < NZ-STEP; iZ++)
        for(iY = 0; iY < NY-STEP; iY++)
            for(iX = 0; iX < NX-STEP; iX++)
            {
                vMarchCube(iX, iY, iZ, 1);
            }
    
    
    numberOfVertices = [vertexsDataArray count] / 3;
    NSLog(@"num of vertexs: %d", numberOfVertices);
    
    if ([vertexsDataArray writeToFile:@"vertexsData" atomically:YES] == NO) {
        NSLog(@"Save to file failed!");
    }
    
    vertexsDataArrayPtr = (GLfloat *)calloc(numberOfVertices, 3 * sizeof(GLfloat));
    normalsDataArrayPtr = (GLfloat *)calloc(numberOfVertices, 3 * sizeof(GLfloat));
    for (int i = 0; i < numberOfVertices * 3; i++) {
        [[vertexsDataArray objectAtIndex:i] getValue:&vertexsDataArrayPtr[i]];
        [[normalsDataArray objectAtIndex:i] getValue:&normalsDataArrayPtr[i]];
    }

}





@end
