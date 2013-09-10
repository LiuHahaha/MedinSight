//
//  KSDicomDictionary.h
//  DicomViewer
//
//  Created by Niukenan on 13-6-13.
//  Copyright (c) 2013年 United-Imaging. All rights reserved.
//

#ifndef __DICOM_DICTIONARY_H__
#define __DICOM_DICTIONARY_H__

#import <Foundation/Foundation.h>

@interface KSDicomDictionary : NSObject
{
    NSDictionary *dictionary;
}

+ (id) sharedInstance;

- (NSString *) valueForKey:(NSString *)key;

@end

#endif //__DICOM_DICTIONARY_H__