//
//  KSViewController.m
//  DicomViewer
//
//  Created by Niukenan on 13-6-13.
//  Copyright (c) 2013年 United-Imaging. All rights reserved.
//

#import "KSViewController.h"
#import "KSDicom2DView.h"
#import "KSDicomDecoder.h"

#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <unistd.h>
#include <netdb.h>
#include <stdlib.h>


#define kTagOfProgressView		100
#define kTagOfLabelInView       111

//#define WL                      700
//#define WW                      3200
#define MAX_CENTER_Trans_X 293.376
#define threshold_Trans_X 112.0696

NSMutableData *data;

typedef enum {
    none, xoy, yoz, xoz
}View;

View viewInBigMode;
View chooseView;

CGPoint viewOriginPoint;
CGPoint scrollViewOriginPoint;

UIImageView *ViewView;

int sliderValues[4] = {0,0,0,0};
float scaleValues[4] = {1,1,1,1};
typedef struct {
    float WW;
    float WL;
}WW_And_WL;
WW_And_WL eachWW_WL[4];

CGPoint sumTrans;
CGPoint sumTransInView;
// KSViewController PrivateMethods
// 
@interface KSViewController(PrivateMethods)

- (void) decodeAndDisplay:(NSString *)path;
- (void) displayWith:(NSInteger)windowWidth windowCenter:(NSInteger)windowCenter;
- (ushort **) decodeAndReadOneSliceData:(NSString *) path;

@end

// KSViewController @implementation
//
@implementation KSViewController

@synthesize deckView = _deckView;
@synthesize mainView = _mainView;

@synthesize dicom2DView;
@synthesize dicom2DView2;
@synthesize dicom2DView3;
@synthesize dicom2DView4;


@synthesize backgroudView;
//@synthesize scrollView;

@synthesize patientName, modality, windowInfo, date;
@synthesize viewIndicator;
@synthesize slider;
@synthesize btnDataRead;
@synthesize seg_indicator_Trans_or_WW_WL = _seg_indicator_Trans_or_WW_WL;
@synthesize switch_indicator_Link_WW_WL = _switch_indicator_Link_WW_WL;

@synthesize SingleTap = _SingleTap;
@synthesize DoubleTap = _DoubleTap;

@synthesize centerPoint = _centerPoint;
//@synthesize sysView;


int Documents_Num; //number of images
//NSArray *fileNameArray;
//NSString *documentsDirectory;

NSString *Manipulation=@"WW/WL";


/////////////////////////add by Xutq///////////////
//@synthesize imageView;
// ---pinching---1
CGFloat lastScaleFactor = 1;
// ---panning (or Dragging)---1
CGPoint netTranslation;

/////////////////////////add end///////////////////

int dataSize_X;
int dataSize_Y;
int dataSize_Z;

bool flag_data_read=false;


// 图像数据体
ushort *** imagesVolume;


int orgx,orgy;


#pragma mark - PrivateMethods   alert View add ProgressView & Activity Indicator
- (void) createProgressionAlertWithMessage:(NSString *)message withActivity:(BOOL)activity
{
	progressAlert = [[UIAlertView alloc] initWithTitle: message
                                               message: @"Please wait..."
                                              delegate: self
                                     cancelButtonTitle: nil
                                     otherButtonTitles: nil];
	
	// Create the progress bar and add it to the alert
	if (activity) 
	{
		UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		activityView.frame = CGRectMake(139.0f-18.0f, 80.0f, 37.0f, 37.0f);
		[progressAlert addSubview:activityView];
		[activityView startAnimating];
	} 
	else 
	{
        UILabel *label_data = [[UILabel alloc] initWithFrame:CGRectMake(120.0f, 100.0f, 120.0f, 30.0f)];
        label_data.tag=kTagOfLabelInView;
        label_data.backgroundColor= [UIColor clearColor];
        label_data.textColor= [UIColor whiteColor];
        
        //label_data.text=@"ddd";
        [progressAlert addSubview:label_data];
        
        
		UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(30.0f, 80.0f, 225.0f, 90.0f)];
		progressView.tag = kTagOfProgressView;
		[progressAlert addSubview:progressView];
		progressView.progress = 0.0;
		[progressView setProgressViewStyle: UIProgressViewStyleBar];        
	}
	[progressAlert show];
}


- (void)progressValueIncrease
{
	UIProgressView *progressView = (UIProgressView *)[progressAlert viewWithTag:kTagOfProgressView];
	if (progressView != nil) 
	{
		if (progressView.progress > 1.0 || progressView.progress == 1.0) 
		{
			[progressAlert dismissWithClickedButtonIndex:0 animated:YES];
			[progressAlert release];
			progressAlert = NULL;
		}
		else 
		{
			progressView.progress = progressView.progress + 0.01;
		}
	}
}


- (void)updateProgressBar:(NSString *)progress{
    UIProgressView *progressView = (UIProgressView *)[progressAlert viewWithTag:kTagOfProgressView];
    UILabel *label = (UIProgressView *)[progressAlert viewWithTag:kTagOfLabelInView];
    
    if (progressView != nil) 
	{
		if (progressView.progress > 1.0 || progressView.progress == 1.0) 
		{
            [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
			[progressAlert release];
			progressAlert = NULL;
		}
	}

    progressView.progress = [progress floatValue];
    
    [label setText:[NSString stringWithFormat:@"%d /%d",(int)([progress floatValue]*Documents_Num), Documents_Num]];

}

#pragma mark sub thread
- (void)loading{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
       
    NSLog(@"Data Slices Reading....");
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *fileNameArray = [fm directoryContentsAtPath:documentsDirectory];
    
    for (NSString * content in fileNameArray) {
        //Delete useless file
        if ([content isEqual:@".DS_Store"]) {
            [fileNameArray removeObject:content];
            break;
        }
    }
    
    Documents_Num = [fileNameArray count];
    dataSize_Z = [fileNameArray count];
    
    //ushort *** imagesVolume = (ushort ***)calloc(Documents_Num, sizeof(ushort **));
    imagesVolume = (ushort ***)calloc(Documents_Num, sizeof(ushort **));
    
    
    UIProgressView *progressView = (UIProgressView *)[progressAlert viewWithTag:kTagOfProgressView];
	CGFloat progress = progressView.progress;

        
    for (int i=0; i<[fileNameArray count]; i++) 
    {
        NSString *s = [fileNameArray objectAtIndex:i];
        
        NSString *appFile= [documentsDirectory stringByAppendingPathComponent:s];
        NSLog(@"appfile is coming");
        NSLog(@"%@",appFile);
        
        imagesVolume[i] = [self decodeAndReadOneSliceData:appFile];
        
        [self performSelectorOnMainThread:@selector(updateProgressBar:) withObject:[NSString stringWithFormat:@"%f", ((float)i/(float)Documents_Num)]  waitUntilDone:NO];
    }
    
    flag_data_read=true;

    NSString *s = [fileNameArray objectAtIndex:20];
    NSString *appFile= [documentsDirectory stringByAppendingPathComponent:s];
    NSLog(@"%@", appFile);
    
    [self decode:appFile];
    
    //
    [self initParameter];

   
    //
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    progressAlert = NULL;
    
	
	[pool release];
}



#pragma mark ButtonAction

//读取三维数据体数据
-(IBAction)btnDataRead:(id)sender
{
    // 显示Alert View 
    [self createProgressionAlertWithMessage:@"Data Reading..." withActivity:NO];

    // 开启读入图像线程
    [NSThread detachNewThreadSelector:@selector(loading) toTarget:self withObject:nil];
    
}
 
-(void)createXOYView:(int) Xslice WW_WL:(WW_And_WL)WW_WL
{
    if (Xslice <= Documents_Num)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSArray *fileNameArray = [fm directoryContentsAtPath:documentsDirectory];
        
        if ([fileNameArray count] != 0) {
            NSString *s = [fileNameArray objectAtIndex:Xslice];
            NSLog(@"%@", s);
            
            //得到slider处的图像路径
            NSString *appFile  = [documentsDirectory stringByAppendingPathComponent:s];
            NSLog(@"%@", appFile);
            //显示slider处的图像
            
            [dicomDecoder setDicomFilename:appFile];
            
            //解析出patient's 信息
            NSString * info = [dicomDecoder infoFor:PATIENT_NAME];
            self.patientName.text = [NSString stringWithFormat:@"Patient: %@", info];
            
            info = [dicomDecoder infoFor:MODALITY];
            self.modality.text = [NSString stringWithFormat:@"Modality: %@", info];
            
            info = [dicomDecoder infoFor:SERIES_DATE];
            self.date.text = info;
            
            info = [NSString stringWithFormat:@"WW/WL: %d / %d", dicom2DView.winWidth, dicom2DView.winCenter];
            self.windowInfo.text = info;
            
            [self displayWith:WW_WL.WW windowCenter:WW_WL.WL];
        }
        else {
            NSString * dicomPath = [[NSBundle mainBundle] pathForResource:@"14" ofType:nil ];
            [self decodeAndDisplay:dicomPath];
            //[self showPlainTextAlertView:self];
        }
        
    }
}



//YOZ平面 算法&绘制
-(void)createYOZView:(int) Xslice WW_WL:(WW_And_WL)WW_WL
{
    // 图像宽
    int imageWidth = dataSize_Y;
    //图像高
    int imageHeight = dataSize_Z;
    
    // 宽*高 一个slice图像总的像素个数
    ushort * sliceData = (ushort *)calloc( imageWidth* imageHeight , sizeof(ushort));
    
    //图像高，  行数
    for (int j=0; j<imageHeight; j++) 
        //图像宽 ， 列数
        for(int i=0; i<imageWidth; i++) 
        {
            sliceData[(j * imageWidth) + i]= imagesVolume [imageHeight-1-j] [i] [Xslice];
        }
	

    dicom2DView2.signed16Image = dicomDecoder.signedImage;
    
    [dicom2DView2 setPixels16:sliceData
                       width:imageWidth
                      height:imageHeight
                 windowWidth:WW_WL.WW
                windowCenter:WW_WL.WL
             samplesPerPixel:1
                 resetScroll:YES];
    
    
    dicom2DView2.frame = CGRectMake(self.dicom2DView2.frame.origin.x, self.dicom2DView2.frame.origin.y, self.dicom2DView2.frame.size.width, self.dicom2DView2.frame.size.width);
    [dicom2DView2 setNeedsDisplay];
    
    NSString * info = [NSString stringWithFormat:@"WW/WL: %d / %d", dicom2DView2.winWidth, dicom2DView2.winCenter];
    self.windowInfo.text = info;

}






//XOZ平面 算法&绘制
-(void)createXOZView:(int) Yslice WW_WL:(WW_And_WL)WW_WL
{
    // 图像宽
    int imageWidth = dataSize_X;
    //图像高
    int imageHeight = dataSize_Z;
    
    // 宽*高 一个slice图像总的像素个数
    ushort * sliceData = (ushort *)calloc( imageWidth* imageHeight , sizeof(ushort));
    
    //图像高，  行数
    for (int j=0; j<imageHeight; j++) 
        //图像宽 ， 列数
        for(int i=0; i<imageWidth; i++) 
        {
            sliceData[(j * imageWidth) + i] = imagesVolume [imageHeight-1-j] [Yslice] [i];
        }
	
    
    dicom2DView3.signed16Image = dicomDecoder.signedImage;
    
    [dicom2DView3 setPixels16:sliceData
                        width:imageWidth
                       height:imageHeight
                  windowWidth:WW_WL.WW
                 windowCenter:WW_WL.WL
              samplesPerPixel:1
                  resetScroll:YES];
    

    dicom2DView3.frame = CGRectMake(self.dicom2DView3.frame.origin.x, self.dicom2DView3.frame.origin.y, self.dicom2DView3.frame.size.width, self.dicom2DView3.frame.size.height);
    [dicom2DView3 setNeedsDisplay];
    
    NSString * info = [NSString stringWithFormat:@"WW/WL: %d / %d", dicom2DView3.winWidth, dicom2DView3.winCenter];
    self.windowInfo.text = info;
    
}



- (IBAction)reDownLoadFromServer:(id)sender {
    [self showPlainTextAlertView:self];
}

- (IBAction)switch_Link_WW_WL:(UISwitch *)sender {
    
}




#pragma mark -
#pragma mark - Dicom slices to DataVolume
//解析单幅图像
- (ushort **) decodeAndReadOneSliceData:(NSString *) path
{
    [dicomDecoder release];
    dicomDecoder = [[KSDicomDecoder alloc] init];
    [dicomDecoder setDicomFilename:path];
    if (!dicomDecoder.dicomFound || !dicomDecoder.dicomFileReadSuccess) 
    {
        [dicomDecoder release];
        dicomDecoder = nil;
        return nil;
    }
    
    dataSize_X =dicomDecoder.width;
    dataSize_Y =dicomDecoder.height;

    
    NSInteger imageWidth      = dicomDecoder.width;
    NSInteger imageHeight     = dicomDecoder.height;
    
    ushort * pixels16 = [dicomDecoder getPixels16];       
    
    ushort ** sliceData = (ushort **)calloc(imageHeight, sizeof(ushort *));
    
    
    int i,j;
    for (i=0; i<imageHeight; i++)
        sliceData[i]= (ushort *)calloc(imageWidth, sizeof(ushort));
   

    for (i=0;i<imageHeight;i++)
		for (j=0;j<imageWidth;j++)
			sliceData[i][j] = pixels16[  (i * imageWidth) + j];
  
    return sliceData;
}


- (void)valueChaged:(id)sender
{
    
    // 需要修改啊～～～～～～～～～～～对于slider的判断
	UISlider *mySlider = sender;
	int value= (int) mySlider.value ;
    
    
	if (value!=slider.value)
	{
        if (Documents_Num!=0)
        {            
            // XOY
            if (chooseView == xoy) {
                if (value < Documents_Num)
                {
                    [self createXOYView:value WW_WL:eachWW_WL[0]];
                    sliderValues[0] = value;
                }
            }
            
            // YOZ
            if (chooseView == yoz)
            {
                if (value < dataSize_X) {
                    [self createYOZView:value WW_WL:eachWW_WL[1]];
                    sliderValues[1] = value;
                }
                
            }
            
            
            //XOZ
            if (chooseView == xoz)
            {
                if (value<dataSize_Y) {
                    [self createXOZView:value WW_WL:eachWW_WL[2]];
                    sliderValues[2] = value;
                }
            }
        }
    }
}




#pragma mark -
#pragma mark - View lifecycle

- (void) dealloc
{


    [_SingleTap release];
    [_DoubleTap release];
    [_seg_indicator_Trans_or_WW_WL release];
    [_switch_indicator_Link_WW_WL release];
    [viewIndicator release];
    [super dealloc];
    
    //self.scrollView = nil;
    self.backgroudView = nil;
    self.dicom2DView = nil;
    self.dicom2DView2 = nil;
    self.dicom2DView3 = nil;
    self.dicom2DView4 = nil;

    self.patientName = nil;
    self.modality = nil;
    self.windowInfo = nil;
    self.date = nil;
    

    [dicomDecoder release];
    [panGesture release];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
 
    
//    self.deckView = [[DeckView alloc] init];
//    self.deckView = CGRectMake(0, 0, width, height);
//    [self.view addSubview:deckView];
//    
//    mainView = [[MainView alloc] init];
//    mainView.frame = CGRectMake(0, 0, width, height);
//    [self.view addSubview:mainView];

    
    //read images from the Documents
    //in this method, decodeAndDisplay was called with the parameter: the first image's path
    [self cpTestData2DocDir];

    
//    // decode and display dicom @"dcm"
//    NSString * info = [dicomDecoder infoFor:PATIENT_NAME];
//    self.patientName.text = [NSString stringWithFormat:@"Patient: %@", info];
//    
//    info = [dicomDecoder infoFor:MODALITY];
//    self.modality.text = [NSString stringWithFormat:@"Modality: %@", info];
//    
//    info = [dicomDecoder infoFor:SERIES_DATE];
//    self.date.text = info;
//    
//    info = [NSString stringWithFormat:@"WW/WL: %d / %d", dicom2DView.winWidth, dicom2DView.winCenter];
//    self.windowInfo.text = info;
    
    // Add gesture
//    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc]
//                                              initWithTarget:self
//                                              action:@selector(handlePinchGesture:)];
//    [dicom2DView addGestureRecognizer:pinchGesture];


//    
//    // 关键在这一行，如果双击确定偵測失败才會触发单击
//    [_SingleTap requireGestureRecognizerToFail:_DoubleTap];


    
    
    //添加slider动作
    [slider addTarget:self action:@selector(valueChaged:) forControlEvents:UIControlEventValueChanged];
    
    [self initParameter];
    
    
    self.viewIndicator.text = @"Axial";
    
    ViewView = [[UIImageView alloc] initWithImage:dicom2DView.dicomImage];
}

- (void)initParameter {
    //初始化slider对象属性， min，max， init位置
    slider.minimumValue = 1;
	slider.maximumValue = Documents_Num;
	slider.value = MIN(MIN(dataSize_X, dataSize_Y), dataSize_Z) / 2 ;
    for (int i = 0; i < 4; i++) {
        sliderValues[i] = slider.value;
    }
    
    NSLog(@"%d",Documents_Num);
    // NSLog([fileNameArray objectAtIndex:0]);
    
    
    //which view is in big mode
    viewInBigMode = none;
    chooseView = xoy;
    
    
    
    eachWW_WL[0].WW = dicomDecoder.windowWidth;
    eachWW_WL[0].WL = dicomDecoder.windowCenter;
    eachWW_WL[1] = eachWW_WL[2] = eachWW_WL[3] = eachWW_WL[0];

    [self createYOZView:sliderValues[1] WW_WL:eachWW_WL[1]];
    [self createXOZView:sliderValues[2] WW_WL:eachWW_WL[2]];
    [self createXOYView:sliderValues[0] WW_WL:eachWW_WL[0]];
    
    self.centerPoint = CGPointMake(0, 0);
    //self.centerPoint = CGPointMake(self.mainView.frame.size.width / 2, self.mainView.frame.size.height / 2);
    sumTrans = CGPointMake(0, 0);
    sumTransInView = CGPointMake(0, 0);
    scrollViewOriginPoint = CGPointMake(dicom2DView.frame.origin.x, dicom2DView.frame.origin.y);

}



- (void)viewDidUnload
{
    [super viewDidUnload];
    
//    [dicom2DView removeGestureRecognizer:panGesture];
//    [dicom2DView2 removeGestureRecognizer:panGesture];
//    [dicom2DView3 removeGestureRecognizer:panGesture];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

// 读取Documents里的文件
- (void)cpTestData2DocDir {
//    NSFileManager *fm = [NSFileManager defaultManager];
//    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSArray *tmpfileNameArray = [fm subpathsAtPath:documentsDirectory];
//    NSLog(@"%@", tmpfileNameArray);
//    
//    NSMutableArray *fileNameArray = [tmpfileNameArray mutableCopy];
//    
//    for (NSString *content in fileNameArray) {
//        //Delete useless file
//        if ([content isEqual:@".DS_Store"]) {
//            NSError *error;
//            if (![fm removeItemAtPath:content error:&error]) {
//                NSLog(@"Remove Error: %@", [error localizedDescription]);
//                return;
//            }
//            [fileNameArray removeObject:content];
//            
//        } else {
//            continue;
//        }
//    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    //get document's path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    //get the files's name, save in an array
    NSArray *fileNameArray = [fm directoryContentsAtPath:documentsDirectory];
    
    for (NSString * content in fileNameArray) {
        //Delete useless file
        if ([content isEqual:@".DS_Store"]) {
            [fileNameArray removeObject:content];
            break;
        }
    }
    
    dataSize_Z = Documents_Num = [fileNameArray count];
    
    //为图像数据体申请空间
    imagesVolume = (ushort ***)calloc(Documents_Num, sizeof(ushort **));
    
    if (Documents_Num!=0) { //如果Document目录下有文件
        //遍历，生成 图像数据体
        for (int i=0; i<[fileNameArray count]; i++)
        {
            NSString *s = [fileNameArray objectAtIndex:i];
            
            NSString *appFile= [documentsDirectory stringByAppendingPathComponent:s];
            NSLog(@"appfile is coming");
            NSLog(@"%@",appFile);
            
            imagesVolume[i] = [self decodeAndReadOneSliceData:appFile];
            
        }
        flag_data_read=true;
        
        NSString *s = [fileNameArray objectAtIndex:20];
        NSString *appFile= [documentsDirectory stringByAppendingPathComponent:s];
        NSLog(@"%@", appFile);
        
        [self decode:appFile];
        
        
        
    }
    else {
        NSString * dicomPath = [[NSBundle mainBundle] pathForResource:@"14" ofType:nil ];
        [self decodeAndDisplay:dicomPath];
        //[self showPlainTextAlertView:self];
    }
}


#pragma mark -
#pragma mark - Dicom View Display
- (void) decode:(NSString *)path
{
    [dicomDecoder release];
    dicomDecoder = [[KSDicomDecoder alloc] init];
    [dicomDecoder setDicomFilename:path];

}

- (void) decodeAndDisplay:(NSString *)path
{        
    [dicomDecoder release];
    dicomDecoder = [[KSDicomDecoder alloc] init];
    [dicomDecoder setDicomFilename:path];
    [self displayWith:dicomDecoder.windowWidth windowCenter:dicomDecoder.windowCenter];
}

- (void) displayWith:(NSInteger)windowWidth windowCenter:(NSInteger)windowCenter
{
    if (!dicomDecoder.dicomFound || !dicomDecoder.dicomFileReadSuccess) 
    {
        [dicomDecoder release];
        dicomDecoder = nil;
        return;
    }

    NSInteger winWidth        = windowWidth;
    NSInteger winCenter       = windowCenter;
    NSInteger imageWidth      = dicomDecoder.width;
    NSInteger imageHeight     = dicomDecoder.height;
    NSInteger bitDepth        = dicomDecoder.bitDepth;
    NSInteger samplesPerPixel = dicomDecoder.samplesPerPixel;
    BOOL signedImage          = dicomDecoder.signedImage;
    
    BOOL needsDisplay = NO;
    
    if (samplesPerPixel == 1 && bitDepth == 8)
    {
        Byte * pixels8 = [dicomDecoder getPixels8];
        
        if (winWidth == 0 && winCenter == 0)
        {
            Byte max = 0, min = 255;
            NSInteger num = imageWidth * imageHeight;
            for (NSInteger i = 0; i < num; i++)
            {
                if (pixels8[i] > max) {
                    max = pixels8[i];
                }
                
                if (pixels8[i] < min) {
                    min = pixels8[i];
                }
            }
            
            winWidth = (NSInteger)((max + min)/2.0 + 0.5);
            winCenter = (NSInteger)((max - min)/2.0 + 0.5);
        }
        
        [dicom2DView setPixels8:pixels8
                          width:imageWidth
                         height:imageHeight
                    windowWidth:winWidth
                   windowCenter:winCenter
                samplesPerPixel:samplesPerPixel
                    resetScroll:YES];
        
        needsDisplay = YES;
        NSLog(@"set Pixel 8");
    }
    
    if (samplesPerPixel == 1 && bitDepth == 16)
    {
        ushort * pixels16 = [dicomDecoder getPixels16];
        
        if (winWidth == 0 || winCenter == 0)
        {
            ushort max = 0, min = 65535;
            NSInteger num = imageWidth * imageHeight;
            for (NSInteger i = 0; i < num; i++)
            {
                if (pixels16[i] > max) {
                    max = pixels16[i];
                }
                
                if (pixels16[i] < min) {
                    min = pixels16[i];
                }
            }
            
            winWidth = (NSInteger)((max + min)/2.0 + 0.5);
            winCenter = (NSInteger)((max - min)/2.0 + 0.5);
        }
        
        dicom2DView.signed16Image = signedImage;

        
        [dicom2DView setPixels16:pixels16
                           width:imageWidth
                          height:imageHeight
                     windowWidth:winWidth
                    windowCenter:winCenter
                 samplesPerPixel:samplesPerPixel
                     resetScroll:YES];
        
        
        needsDisplay = YES;
        NSLog(@"set Pixel 16");
    }
    
    if (samplesPerPixel == 3 && bitDepth == 8)
    {
        Byte * pixels24 = [dicomDecoder getPixels24];
        
        if (winWidth == 0 || winCenter == 0)
        {
            Byte max = 0, min = 255;
            NSInteger num = imageWidth * imageHeight * 3;
            for (NSInteger i = 0; i < num; i++)
            {
                if (pixels24[i] > max) {
                    max = pixels24[i];
                }
                
                if (pixels24[i] < min) {
                    min = pixels24[i];
                }
            }
            
            winWidth = (max + min)/2 + 0.5;
            winCenter = (max - min)/2 + 0.5;
        }
        
        [dicom2DView setPixels8:pixels24
                          width:imageWidth
                         height:imageHeight
                    windowWidth:winWidth
                   windowCenter:winCenter
                samplesPerPixel:samplesPerPixel
                    resetScroll:YES];
        
        
        needsDisplay = YES;
        NSLog(@"set Pixel 24");
    }
    
    if (needsDisplay)
    {
        CGFloat x = (self.view.frame.size.width - imageWidth*1.3) /2;
        CGFloat y = (self.view.frame.size.height - imageHeight*1.3) /2;
        orgx=x;
        orgy=y;

        
        dicom2DView.frame = CGRectMake(self.dicom2DView.frame.origin.x, self.dicom2DView.frame.origin.y, self.dicom2DView.frame.size.width, self.dicom2DView.frame.size.height);

        [dicom2DView setNeedsDisplay];

        
        
        NSString * info = [NSString stringWithFormat:@"WW/WL: %d / %d", dicom2DView.winWidth, dicom2DView.winCenter];
        self.windowInfo.text = info;
    }
}


#pragma mark -
#pragma mark - Gesture

//PanGesture for adjust WW/WL
//-(IBAction) handlePanGestureToAdjustWWandWL:(UIPanGestureRecognizer *) sender
//{
//    UIGestureRecognizerState state = [sender state];
//    
//    if (state == UIGestureRecognizerStateBegan)
//    {
//        prevTransform = dicom2DView.transform;
//        startPoint = [sender locationInView:self.view];
//    }
//    else if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded)
//    {
//        
//        CGPoint location    = [sender locationInView:self.view];
//        CGFloat offsetX     = location.x - startPoint.x;
//        CGFloat offsetY     = location.y - startPoint.y;
//        startPoint          = location;
//        
//#if 0   
//        // translate
//        //
//        CGAffineTransform translate = CGAffineTransformMakeTranslation(offsetX, offsetY);
//        dicom2DView.transform  = CGAffineTransformConcat(prevTransform, translate);
//#else
//        // adjust window width/level
//        //
//        dicom2DView.winWidth  += offsetX * dicom2DView.changeValWidth;
//        dicom2DView.winCenter += offsetY * dicom2DView.changeValCentre;
//        
//        if (dicom2DView.winWidth <= 0) {
//            dicom2DView.winWidth = 1;
//        }
//        
//        if (dicom2DView.winCenter == 0) {
//            dicom2DView.winCenter = 1;
//        }
//        
//        if (dicom2DView.signed16Image) {
//            dicom2DView.winCenter += SHRT_MIN;
//        }
//        
//        [dicom2DView setWinWidth:dicom2DView.winWidth];
//        [dicom2DView setWinCenter:dicom2DView.winCenter];
//        //[dicom2DView setNeedsDisplay];
//        
//        [self displayWith:dicom2DView.winWidth windowCenter:dicom2DView.winCenter];
//        
//#endif
//    }
//}


#pragma mark gesture
- (IBAction)handleMainViewPan:(UIPanGestureRecognizer *)recognizer {

//    
//    CGPoint translation = [recognizer translationInView:self.view];
//    sumTrans.x += translation.x;
//    if (sumTrans.x > MAX_CENTER_Trans_X) {
//        sumTrans.x = MAX_CENTER_Trans_X;
//    }
//    if (sumTrans.x < 0) {
//        sumTrans.x = 0;
//    }
//    recognizer.view.center = CGPointMake(self.view.center.x + sumTrans.x, recognizer.view.center.y);
//    NSLog(@"%f", sumTrans.x);
//    if (recognizer.state == UIGestureRecognizerStateEnded) {
//        
//        [UIView animateWithDuration:0.2 animations:^(void){
//            
//            if (sumTrans.x > threshold_Trans_X) {
//                recognizer.view.center = CGPointMake(self.view.center.x + MAX_CENTER_Trans_X, recognizer.view.center.y);
//                sumTrans.x = MAX_CENTER_Trans_X;
//            }else{
//                recognizer.view.center = CGPointMake(self.view.center.x, recognizer.view.center.y);
//                sumTrans.x = 0;
//            }
//            
//        }];
//        
//        
//    }
//    
//    [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
}
#pragma mark xoy-gesture
- (void)slowingEffect:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint velocity = [recognizer velocityInView:self.view];
        
        CGFloat magnitude = sqrtf((velocity.x * velocity.x) + (velocity.y * velocity.y));
        
        CGFloat slideMult = magnitude / 200;
        
        NSLog(@"magnitude: %f, slideMult: %f", magnitude, slideMult);
        
        float slideFactor = 0.001 * slideMult; // Increase for more of a slide
        
        CGPoint finalPoint = CGPointMake(recognizer.view.center.x + (velocity.x * slideFactor),
                                         
                                         recognizer.view.center.y + (velocity.y * slideFactor));
        
        finalPoint.x = MIN(MAX(finalPoint.x, 0), self.view.bounds.size.width);
        
        finalPoint.y = MIN(MAX(finalPoint.y, 0), self.view.bounds.size.height);
        
        [UIView animateWithDuration:slideFactor*2 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            recognizer.view.center = finalPoint;
            
        } completion:nil];
    }

}

- (void)AjustWW_WL:(CGPoint) offset {
    // adjust window width/level
    KSDicom2DView *view;
    switch (chooseView) {
        case xoy:
            view = dicom2DView;
            break;
            
        case yoz:
            view = dicom2DView2;
            break;
            
        case xoz:
            view = dicom2DView3;
            break;
            
        default:
            break;
    }
    if (abs(offset.x) >= abs(offset.y)) {
        view.winWidth  += offset.x * view.changeValWidth;
    }
    else {
        view.winCenter += offset.y * view.changeValCentre;
    }
    
    if (view.winWidth <= 0) {
        view.winWidth = 1;
    }
    
    if (view.winCenter == 0) {
        view.winCenter = 1;
    }
    
    if (view.signed16Image) {
        view.winCenter += SHRT_MIN;
    }

    [view setWinWidth:view.winWidth];
    [view setWinCenter:view.winCenter];
    
    
    if ([self switch_indicator_Link_WW_WL].on) {
        eachWW_WL[0].WW = view.winWidth;
        eachWW_WL[0].WL = view.winCenter;
        for (int i = 1; i < 4; i++) {
            eachWW_WL[i] = eachWW_WL[0];
        }
        switch (chooseView) {
            case xoy:
                [self createYOZView:sliderValues[1] WW_WL:eachWW_WL[0]];
                [self createXOZView:sliderValues[2] WW_WL:eachWW_WL[0]];
                [self createXOYView:sliderValues[0] WW_WL:eachWW_WL[0]];
                
                break;
                
            case yoz:
                [self createXOYView:sliderValues[0] WW_WL:eachWW_WL[0]];
                [self createXOZView:sliderValues[2] WW_WL:eachWW_WL[0]];
                [self createYOZView:sliderValues[1] WW_WL:eachWW_WL[0]];
                
                break;
                
            case xoz:
                [self createXOYView:sliderValues[0] WW_WL:eachWW_WL[0]];
                [self createYOZView:sliderValues[1] WW_WL:eachWW_WL[0]];
                [self createXOZView:sliderValues[2] WW_WL:eachWW_WL[0]];
                break;
                
            default:
                break;
        }


    }
    else {
        switch (chooseView) {
            case xoy:
                eachWW_WL[0].WW = view.winWidth;
                eachWW_WL[0].WL = view.winCenter;
                [self createXOYView:sliderValues[0] WW_WL:eachWW_WL[0]];
                break;
            
            case yoz:
                eachWW_WL[1].WW = view.winWidth;
                eachWW_WL[1].WL = view.winCenter;
                [self createYOZView:sliderValues[1] WW_WL:eachWW_WL[1]];
                break;
            
            case xoz:
                eachWW_WL[2].WW = view.winWidth;
                eachWW_WL[2].WL = view.winCenter;
                [self createXOZView:sliderValues[2] WW_WL:eachWW_WL[2]];
                break;
            
            default:
                break;
        }
    }
    
    
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    if ([self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex == 0) {
        if (viewInBigMode != none) {
            CGPoint translation = [recognizer translationInView:self.view];
            sumTransInView = translation;
            
            recognizer.view.center = CGPointMake(recognizer.view.center.x + translation.x, recognizer.view.center.y + translation.y);
            [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
            //[self slowingEffect:recognizer];
        }
    }
    if ([self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex == 1) {
        UIGestureRecognizerState state = [recognizer state];
        if (state == UIGestureRecognizerStateBegan)
        {
            startPoint = [recognizer locationInView:self.view];
        }
        else if (state == UIGestureRecognizerStateChanged || state == UIGestureRecognizerStateEnded)
        {
            CGPoint location = [recognizer locationInView:self.view];
            CGPoint offset;
            offset.x = location.x - startPoint.x;
            offset.y = location.y - startPoint.y;
            startPoint = location;
            
            [self AjustWW_WL:offset];
        }
    }
    
}

- (void)hiddenOthers {
    switch (chooseView) {
        case xoy:
            dicom2DView2.hidden = true;
            dicom2DView3.hidden = true;
            dicom2DView4.hidden = true;
            break;
            
        case yoz:
            dicom2DView.hidden = true;
            dicom2DView3.hidden = true;
            dicom2DView4.hidden = true;
            break;
        case xoz:
            dicom2DView.hidden = true;
            dicom2DView2.hidden = true;
            dicom2DView4.hidden = true;
            break;
        default:
            break;
    }
    
}
- (void)showOthers {
    switch (chooseView) {
        case xoy:
            dicom2DView2.hidden = false;
            dicom2DView3.hidden = false;
            dicom2DView4.hidden = false;
            break;
            
        case yoz:
            dicom2DView.hidden = false;
            dicom2DView3.hidden = false;
            dicom2DView4.hidden = false;
            break;
        case xoz:
            dicom2DView.hidden = false;
            dicom2DView2.hidden = false;
            dicom2DView4.hidden = false;
            break;
        default:
            break;
    }
    
}

- (CGRect)DoubleSize: (UITapGestureRecognizer *)sender{
    viewOriginPoint = sender.view.frame.origin;
    //return CGRectMake(dicom2DView.frame.origin.x, dicom2DView.frame.origin.y, 360*2, 360*2);
    return CGRectMake(0, 0, 360*2, 360*2);
}

- (CGRect)ResumeSize {
    return CGRectMake(viewOriginPoint.x, viewOriginPoint.y, 360, 360);
}

- (void)EmbedViewInScollView: (UITapGestureRecognizer *)sender {
    scrollView = [[UIScrollView alloc]  initWithFrame:CGRectMake(scrollViewOriginPoint.x, scrollViewOriginPoint.y, 720, 720)];
    [scrollView addSubview:sender.view];
    //[scrollView addSubview:ViewView];
    //scrollView.contentSize = CGSizeMake(sender.view.frame.size.width * 2, sender.view.frame.size.height * 2);
    //scrollView.contentSize = CGSizeMake(3600, 3600);
    
    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.maximumZoomScale = 2.0;//允许放大2倍
    scrollView.minimumZoomScale = 0.5;//允许放大到0.5倍
    scrollView.delegate = self;
    scrollView.bounces = true;
    scrollView.bouncesZoom = true;
    [self.mainView addSubview:scrollView];
 
}

- (void)RemoveScrollView: (UITapGestureRecognizer *)sender {
    [sender.view removeFromSuperview];
    [self.mainView addSubview:sender.view];
    [scrollView removeFromSuperview];
    scrollView = NULL;
}



- (UIView *)viewForZoomingInScrollView:(UIScrollView *)sender {
//    switch (chooseView) {
//        case xoy:
//            return dicom2DView;
//            break;
//        case yoz:
//            return dicom2DView2;
//            break;
//        case xoz:
//            return dicom2DView3;
//            break;
//        default:
//            break;
//    }
    return ViewView;
}

- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)sender {
    //double tap to double size
    switch (viewInBigMode) {
        case none:
            sender.view.frame = [self DoubleSize:sender];
            [self hiddenOthers];
            [self EmbedViewInScollView:sender];
            viewInBigMode = chooseView;
            break;

            
        default:
            //double tap to resume the view
            if (viewInBigMode == chooseView) {
                sender.view.frame = [self ResumeSize];
                [self showOthers];
                [self RemoveScrollView:sender];
                viewInBigMode = none;
            }
            break;
    }


}



- (IBAction)handleSingleTap:(UITapGestureRecognizer *)sender {
    chooseView = xoy;
    slider.minimumValue = 1;
	slider.maximumValue = Documents_Num;
    slider.value=sliderValues[0];
    
    //如果不是在放大模式下，因为拖动功能被锁定不能用，所以将默认pan动作关联到调窗
    if (viewInBigMode == none) {
        [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 1;
    }
    else {
        [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 0;
    }
    
    self.viewIndicator.text = @"Axial";
    
    [self createXOYView:sliderValues[0] WW_WL:eachWW_WL[0]];
   
}

- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)sender {
    chooseView = xoy;
    [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 1;
}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    if (viewInBigMode != none) {
        recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
        recognizer.scale = 1;
        scaleValues[0] = recognizer.scale;
        
        recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, recognizer.scale, recognizer.scale);
        
        recognizer.scale = 1;
    }

}

- (IBAction)handleYOZViewSingleTap:(UITapGestureRecognizer *)sender {
    chooseView= yoz;
    slider.minimumValue = 1;
	slider.maximumValue = dataSize_X;
    slider.value=sliderValues[1];
    
    
    //如果不是在放大模式下，因为拖动功能被锁定不能用，所以将默认pan动作关联到调窗
    if (viewInBigMode == none) {
        [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 1;
    }
    else {
        [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 0;
    }
    
    self.viewIndicator.text = @"Saggital";

    [self createYOZView:sliderValues[1] WW_WL:eachWW_WL[1]];


}

- (IBAction)handleYOZViewLongPress:(UILongPressGestureRecognizer *)sender {
    chooseView = yoz;
    [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 1;
}

- (IBAction)handleXOZViewSingleTap:(UITapGestureRecognizer *)sender {
    chooseView= xoz;
    slider.minimumValue = 1;
	slider.maximumValue = dataSize_Y;
    slider.value=sliderValues[2];
    
    //如果不是在放大模式下，因为拖动功能被锁定不能用，所以将默认pan动作关联到调窗
    if (viewInBigMode == none) {
        [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 1;
    }
    else {
        [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 0;
    }
    
    self.viewIndicator.text = @"Coronal";

    [self createXOZView:sliderValues[2] WW_WL:eachWW_WL[2]];


}

- (IBAction)handleXOZViewLongPress:(UILongPressGestureRecognizer *)sender {
    chooseView = xoz;
    [self seg_indicator_Trans_or_WW_WL].selectedSegmentIndex = 1;
}

//- (void)handlerPanGesture:(UIPanGestureRecognizer *)recognizer
//{
//    if ((recognizer.state == UIGestureRecognizerStateBegan) ||
//        (recognizer.state == UIGestureRecognizerStateChanged))
//    {
//        CGPoint offset = [recognizer translationInView:self.dicom2DView];
//        CGRect frame = self.dicom2DView.frame;
//        frame.origin.x += offset.x;
//        frame.origin.y += offset.y;
//        //if (frame.origin.x >= 0 && frame.origin.x <= 360)
//        //{
//            self.dicom2DView.frame = frame;
//        //}
//        [self.view bringSubviewToFront:dicom2DView];
//        [recognizer setTranslation:CGPointZero inView:self.dicom2DView];
//        
////        CGPoint offset2 = [recognizer translationInView:self.dicom2DView2];
////        CGRect frame2 = self.dicom2DView2.frame;
////        frame2.origin.x += offset2.x;
////        frame2.origin.y += offset2.y;
////        //if (frame.origin.x >= 0 && frame.origin.x <= 360)
////        //{
////        self.dicom2DView2.frame = frame2;
////        //}
////        [self.view bringSubviewToFront:dicom2DView2];
////        [recognizer setTranslation:CGPointZero inView:self.dicom2DView2];
//
//    }
////    else if (recognizer.state == UIGestureRecognizerStateEnded)
////    {
//////        BOOL isVisible = self.rightViewController.view.frame.origin.x < kScreenWidth / 2;
////        [self.dicom2DView setNeedsDisplay];
////        
////    }
//    
////    CGPoint translation = [(UIPanGestureRecognizer *) sender translationInView:dicom2DView];
////    
////
////    NSLog(@"netTranslation: %f, %f", netTranslation.x, netTranslation.y);
////    
////    //if (Manipulation == @"Transform") {
////        sender.view.transform = CGAffineTransformMakeTranslation(
////                                                                 netTranslation.x + translation.x,
////                                                                 netTranslation.y + translation.y);
////        if (sender.state == UIGestureRecognizerStateEnded) {
////            netTranslation.x += translation.x;
////            netTranslation.y += translation.y;
////        }
//    
//    
//}


/////////////////////////add by Xutq///////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ---panning (or Dragging)---3
// ---handle pan gesture---
-(IBAction)handlePanGestureToPanImage:(UIGestureRecognizer *)sender
{
    CGPoint translation = [(UIPanGestureRecognizer *) sender translationInView:dicom2DView];
    
    if (Manipulation == @"Transform") {
        sender.view.transform = CGAffineTransformMakeTranslation(
                                                                 netTranslation.x + translation.x,
                                                                 netTranslation.y + translation.y);
        if (sender.state == UIGestureRecognizerStateEnded) {
            netTranslation.x += translation.x;
            netTranslation.y += translation.y;
        }
        
    }    
}

//---pinch gesture---3
// ---handle pinch gesture---
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateChanged || sender.state == UIGestureRecognizerStateEnded) {
        [self backgroudView].scale *= sender.scale;
        [self dicom2DView].scale *= sender.scale;
        sender.scale = 1;
    }

}
// add by xutq
// ---handle tap gesture---
- (IBAction) handleTapGesture:(UITapGestureRecognizer *)sender
{
        //NSLog(@"handleTapGesture");
        if (sender.view.contentMode == UIViewContentModeScaleAspectFit) {
            sender.view.contentMode = UIViewContentModeCenter;
        }
        else
            sender.view.contentMode = UIViewContentModeScaleAspectFit;
            
        
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////add end///////////////////
//*/




- (void)writeDataToFile:(NSData *)data wihtName:(unsigned char *)filename {
    //get the document's path
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [documentPaths objectAtIndex:0];
    
    //generate the file gona to save the data
    NSString *AbsoluteName = [docPath stringByAppendingPathComponent: [NSString stringWithFormat:@"%s", filename]];
    
    //write the data to the file
    [data writeToFile:AbsoluteName atomically:YES];
    
    //NSLog(@"%@", fileName);
}


#pragma mark - network part
- (void)connectToServerUsingSocket:(NSArray *)ipAndPort {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    //remove the files first
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *tmpfileNameArray = [fm subpathsAtPath:documentsDirectory];
    
    NSMutableArray *fileNameArray = [tmpfileNameArray mutableCopy];
    
    //    NSLog(@"fileNames list in Docuemnts: %@", fileNameArray);
    
    //change the path to document
    [fm changeCurrentDirectoryPath:[documentsDirectory stringByExpandingTildeInPath]];
    for (NSString * content in fileNameArray) {
        //Delete all files
        NSError *error;
        if (![fm removeItemAtPath:content error:&error]) {
            NSLog(@"Remove Error: %@", [error localizedDescription]);
            return;
        }
    }
    
    
    
    
    if (data == nil) {
        data = [[NSMutableData alloc] init];
    }
    
    NSString *ipString = ipAndPort[0];
    const char *ip=[ipString cStringUsingEncoding:NSUTF8StringEncoding];
    uint port = [ipAndPort[1] intValue];
    
    NSLog(@"%s, %d", ip, port);
    
    unsigned char filename[50]; //50
    long filesize;
	unsigned char databuf[1024]; //1024
	int sockfd;
	struct sockaddr_in serv_addr;
    
	// struct hostent *host;
	int i;
	int lastsize=0;
    
	// host = gethostbyname("localhost");
    
	sockfd=socket(AF_INET,SOCK_STREAM,0);
    
    
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_port = htons(port);
	//serv_addr.sin_addr = *((struct in_addr*)host->h_addr);
	serv_addr.sin_addr.s_addr = inet_addr(ip);
	bzero(&(serv_addr.sin_zero),8);
    
	if(connect(sockfd,(struct sockaddr *) &serv_addr,sizeof(struct sockaddr))==-1)	{
		NSLog(@"connected error");
		exit(1);
	}
    
	//接收文件数目
	int count=0;
	int countbyte;
	countbyte=recv(sockfd,&count,4,0);
    
	NSLog(@"文件数目=%d",count);
    Documents_Num = count;
    
    UIProgressView *progressView = (UIProgressView *)[progressAlert viewWithTag:kTagOfProgressView];
	CGFloat progress = progressView.progress;
    
	while(count--) {
        if (data == nil) {
            data = [[NSMutableData alloc] init];
        }
        //#2 接收文件名
        int filenameLength;
        i=recv(sockfd,&filenameLength,4,0);
        i=recv(sockfd,filename,filenameLength,0); //接收文件名
		// printf("recv %d bytes\n",i);
        //NSString *tmpString = [[NSString alloc] initWithCString:filename encoding:filenameLength];
		//strcat(filename, "\0");
        //NSLog(@"the end of the fileName :%c", filename[filenameLength - 1]);
        NSString *tmpString = [[NSString alloc] initWithCString:filename encoding:filenameLength];
        tmpString = [tmpString substringToIndex:filenameLength];
        
        NSLog(@"file name=%@", tmpString);
        
        i=recv(sockfd,&filesize,8,0); //接收文件大小
		// printf("recv %d bytes\n",i);
		NSLog(@"filesize=%ld",filesize);
		lastsize=filesize; //文件大小赋给变量
        
		//接收文件内容
		i=0;
		
		while(lastsize>0) {
			//NSLog(@"lastsize=%d",lastsize);
			if(lastsize>sizeof(databuf)) {
				i=recv(sockfd,databuf,sizeof(databuf),0);
				//NSLog(@"接收字节i=%d",i);
                [data appendBytes:databuf length:i];
                
			} else {
				i=recv(sockfd,databuf,lastsize,0);
				//NSLog(@"接收字节i=%d",i);
                [data appendBytes:databuf length:i];
                
                
			}
            
			lastsize=lastsize-i;
            
		}
        
		NSLog(@"该文件接收完毕");
        if ([data length]) {
            [self writeDataToFile:data wihtName:[tmpString cStringUsingEncoding:NSUTF8StringEncoding]];
            //NSLog(@"the Final dataLength: %u",[data length]);
            data = nil;
        }
        
        [self performSelectorOnMainThread:@selector(updateProgressBar:) withObject:[NSString stringWithFormat:@"%f", ((float)(Documents_Num - count)/(float)Documents_Num)]  waitUntilDone:NO];
	}
    
    Documents_Num = 0;
    
    [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
    [progressAlert release];
    progressAlert = NULL;
    
    
    [pool release];
    [self performSelectorOnMainThread:@selector(btnDataRead:) withObject:nil waitUntilDone:NO];

    [NSThread exit];
    
}


- (void)CallNewThread: (NSArray *)ipAndPort {
    
    // 显示Alert View
    [self createProgressionAlertWithMessage:@"Data DownLoading..." withActivity:NO];

    // 开启下载进程
    [NSThread detachNewThreadSelector:@selector(connectToServerUsingSocket:) toTarget:self withObject:ipAndPort];

}

#pragma mark - login - AlertView
- (void)showPlainTextAlertView:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"IP Address"
                                                        message:@"Enter IP Address"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView textFieldAtIndex:0].text = @"192.168.";
    [alertView show];
}

//- (void)showLoginPassAlertView {
//    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Login" message:@"Enter your Username and Password" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
//    alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
//    [alertView show];
//}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            ;
            break;
        case 1:
            switch (alertView.alertViewStyle) {
                case UIAlertViewStylePlainTextInput:
                {
                    UITextField *textField = [alertView textFieldAtIndex:0];
                    //NSLog(@"Plain text input: %@", textField.text);
                    NSArray *ipAndPort = [[NSArray alloc] initWithObjects:textField.text, @"54453", nil];
                    
                    //[NSThread detachNewThreadSelector:@selector(connectToServerUsingSocket) toTarget:self withObject:ipAndPort];
                    //[self connectToServerUsingSocket:ipAndPort];
                    [self CallNewThread:ipAndPort];
                }
                break;
                    
                case UIAlertViewStyleSecureTextInput:
                {
                    UITextField *textField = [alertView textFieldAtIndex:0];
                    NSLog(@"Secure text input: %@", textField.text);
                }
                break;
                    
                default:
                    break;
            }
            break;
        default:
            break;
    }
}

//- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
//    ;
//}

- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    UIAlertViewStyle style = alertView.alertViewStyle;
    
    if ((style == UIAlertViewStyleSecureTextInput) ||
        (style == UIAlertViewStylePlainTextInput) ||
        (style == UIAlertViewStyleLoginAndPasswordInput)) {
        UITextField *textField = [alertView textFieldAtIndex:0];
        if ([textField.text length] == 0) {
            return NO;
        }
    }
    
    return YES;
}



@end
