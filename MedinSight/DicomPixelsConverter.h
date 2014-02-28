//
//  DicomPixelsConverter.h
//  MedinSight
//
//  Created by Liang Zisheng on 2/28/14.
//  Copyright (c) 2014 United-Imaging. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DicomPixelsConverter : NSObject

- (Byte *)setPixels16:(ushort *)pixel
                width:(NSInteger)width
               height:(NSInteger)height
          windowWidth:(double)winW
         windowCenter:(double)winC;

@end
