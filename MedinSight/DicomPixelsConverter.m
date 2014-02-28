//
//  DicomPixelsConverter.m
//  MedinSight
//
//  Created by Liang Zisheng on 2/28/14.
//  Copyright (c) 2014 United-Imaging. All rights reserved.
//

#import "DicomPixelsConverter.h"
@interface DicomPixelsConverter()
{
    // For Window Level
    //
    NSInteger winMin;
    NSInteger winMax;
    NSInteger winCenter;
    NSInteger winWidth;
    
    // For image data convert
    NSInteger imgWidth;
    NSInteger imgHeight;

    //the dicom data source
    ushort * pix16;
    
    //the look up table
    Byte * lut16;
}


- (void) resetValues;
- (void) computeLookUpTable16;
- (Byte *) createImageData16;

@end

@implementation DicomPixelsConverter

- (Byte *)setPixels16:(ushort *)pixel
              width:(NSInteger)width
             height:(NSInteger)height
        windowWidth:(double)winW
       windowCenter:(double)winC
{
    Byte *imageData;
    
    winMin = 0;
    winMax = 65535;
    
    imgWidth    = width;
    imgHeight   = height;
    winWidth    = winW;
    winCenter   = winC;
    
    pix16 = pixel;
    
    //根据参数重置winMax, winMin
    [self resetValues];
    
    //建立查找表，把 winMin ~ winMax 灰度 映射到 0 ~ 255
    [self computeLookUpTable16];
    
    //把灰阶数据转成bitmap图像
    imageData = [self createImageData16];
    
    return imageData;
}

- (void) resetValues
{
    winMax = (winCenter + 0.5 * winWidth);
    winMin = winMax - winWidth;
}


- (void) computeLookUpTable16
{
    if (lut16 == NULL) {
        lut16 = (Byte *)calloc(65536, sizeof(Byte));
    }
    
    if (winMax == 0)
        winMax = 65535;
    
    long range = winMax - winMin;
    if (range < 1)
        range = 1;
    
    double factor = 255.0 / range;
    for (NSInteger i = 0; i < 65536; ++i)
    {
        if (i <= winMin)
            lut16[i] = 0;
        else if (i >= winMax)
            lut16[i] = 255;
        else
            lut16[i] = (Byte)((i - winMin) * factor);
    }
}


- (Byte *) createImageData16
{
    if (!pix16) {
        return nil;
    }
    
    NSInteger numBytes = imgWidth * imgHeight;
    Byte * imageData = (Byte *)calloc(numBytes, sizeof(Byte));
    if (!imageData) {
        return nil;
    }
    
    NSInteger k = 0;
    for (NSInteger i = 0; i < imgHeight; ++i) {
        k = i * imgWidth;
        for (NSInteger j = 0; j < imgWidth; ++j) {
            imageData[k + j] = lut16[pix16[k + j]];
        }
    }
    
    return imageData;
    
}




@end
