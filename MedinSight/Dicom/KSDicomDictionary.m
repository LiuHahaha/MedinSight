//
//  KSDicomDictionary.m
//  DicomViewer
//
//  Created by Niukenan on 13-6-13.
//  Copyright (c) 2013年 United-Imaging. All rights reserved.
//

#import "KSDicomDictionary.h"

static KSDicomDictionary *instance;

@implementation KSDicomDictionary

+ (id) sharedInstance
{
    if (!instance) {
        instance = [[KSDicomDictionary alloc] init];
    }
    
    return instance;
}

- (id) init
{ 
    self = [super init];
    
    if (self) {
        NSString * path = [[NSBundle mainBundle] pathForResource:@"DicomDictionary" ofType:@"plist"];
        dictionary = [[NSDictionary alloc] initWithContentsOfFile:path]; 
    }
    
    return self;
}

- (void) dealloc
{
    dictionary = nil;

}

- (id) valueForKey:(NSString *)key
{
    if (!key || [key isEqualToString:@""]) {
        return nil;
    }

    id retValue = nil;
    if (dictionary) {
        retValue = [dictionary valueForKey:key];
    }
    
    return retValue;
}

@end
