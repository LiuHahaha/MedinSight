//
//  KSAppDelegate.m
//  DicomViewer
//
//  Created by Niukenan on 13-6-13.
//  Copyright (c) 2013年 United-Imaging. All rights reserved.
//

#import "KSAppDelegate.h"

/*
bool writeApplicationData(NSData *data, NSString *fileName) {
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	if (!documentsDirectory) {
		
		NSLog(@"Documents directory not found!");
		return NO;
	}
	
	NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
	return ([data writeToFile:appFile atomically:YES]);
}

NSData *applicationDataFromFile(NSString *fileName) {
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
	NSData *myData = [[[NSData alloc] initWithContentsOfFile:appFile] autorelease];
	return myData;
}
*/



@implementation KSAppDelegate

@synthesize window = _window;

/*
- (void)cpTestData2DocDir {
	
    NSLog(@"ssss");
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSFileManager *fm = [NSFileManager defaultManager];		
	NSArray *fileNameArray = [fm directoryContentsAtPath:documentsDirectory];
    
    NSString *appFile;    
    
    for (int i=0; i<[fileNameArray count]; i++) 
    {
        NSString *s = [fileNameArray objectAtIndex:i];
        NSLog(s);
        
       appFile = [documentsDirectory stringByAppendingPathComponent:s];
        NSLog(appFile);

        
    }
    
	/*if (0 == [fileNameArray count]) 
    {
		
		NSString *mainBundleDirectory = [[NSBundle mainBundle] bundlePath];
		NSFileManager *fm = [NSFileManager defaultManager];		
		NSArray *fileNameArray = [fm directoryContentsAtPath:mainBundleDirectory];	
		for (NSString *fileName in fileNameArray) 
        {
			
			NSLog(@"writeApplicationData[%d]", writeApplicationData(UIImagePNGRepresentation([UIImage imageNamed:fileName]), fileName));		
        }
	}	
    
    
}
*/




- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //[self cpTestData2DocDir];
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
