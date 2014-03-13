//
//  ThrDReViewController.h
//  MedinSight
//
//  Created by Liang Zisheng on 2/28/14.
//  Copyright (c) 2014 United-Imaging. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

typedef struct
{
    int Length;
    int Width;
    int Height;
} VolumeSidesLength;

@interface ThrDReViewController : GLKViewController
{
    GLuint vertexBufferID;
    int volume3DLengths[3];
    VolumeSidesLength volumeSidesLength;
}

@property (strong, nonatomic) GLKBaseEffect *baseEffect;
@property (nonatomic) Byte ***images256Volume;

- (void)setVolumeSidesLengthWithHeight:(int)z Width:(int)y Length:(int)x;
@end
