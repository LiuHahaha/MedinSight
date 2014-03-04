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
#import "DicomPixelsConverter.h"
#import "ThrDReViewController.h"

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
@interface KSViewController()
{
    // 图像数据体
    ushort *** imagesVolume;
    Byte *** images256Volume;
    
    //
    int orgx,orgy;
    //
    int dataSize_X;
    int dataSize_Y;
    int dataSize_Z;


}
- (void) decodeAndDisplay:(NSString *)path;
- (void) displayWith:(NSInteger)windowWidth windowCenter:(NSInteger)windowCenter;
- (ushort **) decodeAndReadOneSliceData:(NSString *) path;

@end

// KSViewController @implementation
//
@implementation KSViewController

@synthesize dicom2DView;
@synthesize dicom2DView2;
@synthesize dicom2DView3;
@synthesize dicom2DView4;



@synthesize patientName, modality, windowInfo, date;
@synthesize viewIndicator;
@synthesize slider;
@synthesize btnDataRead;
@synthesize seg_indicator_Trans_or_WW_WL = _seg_indicator_Trans_or_WW_WL;
@synthesize switch_indicator_Link_WW_WL = _switch_indicator_Link_WW_WL;


@synthesize centerPoint = _centerPoint;
//@synthesize sysView;


int Documents_Num; //number of images

NSString *Manipulation=@"WW/WL";


/////////////////////////add by Xutq///////////////
// ---pinching---1
CGFloat lastScaleFactor = 1;
// ---panning (or Dragging)---1
CGPoint netTranslation;

/////////////////////////add end///////////////////


bool flag_data_read=false;


#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"push2GLKView"]) {
        if ([segue.destinationViewController isKindOfClass:[ThrDReViewController class]]) {
            ThrDReViewController *tvc = (ThrDReViewController *)segue.destinationViewController;
            tvc.images256Volume = images256Volume;
            [tvc setVolumeSidesLengthWithHeight:dataSize_Z Length:dataSize_X Width:dataSize_Y];
        }
    }
}




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
    //UILabel *label = (UIProgressView *)[progressAlert viewWithTag:kTagOfLabelInView];
    
    if (progressView != nil) 
	{
		if (progressView.progress > 1.0 || progressView.progress == 1.0) 
		{
            [progressAlert dismissWithClickedButtonIndex:0 animated:YES];
			progressAlert = NULL;
		}
	}

    progressView.progress = [progress floatValue];
    UILabel *label;
    [label setText:[NSString stringWithFormat:@"%d /%d",(int)([progress floatValue]*Documents_Num), Documents_Num]];

}

#pragma mark sub thread
- (void)loading{
    
       
    NSLog(@"Data Slices Reading....");
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSMutableArray *fileNameArray = [[fm contentsOfDirectoryAtPath:documentsDirectory error:nil] mutableCopy];
    
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
    progressAlert = NULL;
    
	
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

- (IBAction)reDownLoadFromServer:(id)sender {
    [self showPlainTextAlertView:self];
}

- (IBAction)switch_Link_WW_WL:(UISwitch *)sender {
    
}

#pragma -mark create Plane View
//XOY平面
-(void)createXOYView:(int) Xslice WW_WL:(WW_And_WL)WW_WL
{
/*    if (Xslice <= Documents_Num)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSArray *fileNameArray = [fm contentsOfDirectoryAtPath:documentsDirectory error:nil];
        
        if ([fileNameArray count] != 0) {
            NSString *s = [fileNameArray objectAtIndex:Xslice];
            NSLog(@"%@", s);
            
            //得到slider处的图像路径
            NSString *appFile  = [documentsDirectory stringByAppendingPathComponent:s];
            NSLog(@"%@", appFile);
            //显示slider处的图像
            
            [self decode:appFile];
            [self displayWith:WW_WL.WW windowCenter:WW_WL.WL];
        }
        
    }
*/

    // 图像宽
    int imageWidth = dataSize_X;
    //图像高
    int imageHeight = dataSize_Y;
    
    // 宽*高 一个slice图像总的像素个数
    ushort * sliceData = (ushort *)calloc( imageWidth* imageHeight , sizeof(ushort));
    
    //图像高，  行数
    for (int j=0; j<imageHeight; j++)
        //图像宽 ， 列数
        for(int i=0; i<imageWidth; i++)
        {
            sliceData[(j * imageWidth) + i]= imagesVolume [Xslice] [imageHeight-1-j] [i] ;
        }
    
    dicom2DView.signed16Image = dicomDecoder.signedImage;
    
    [dicom2DView setPixels16:sliceData
                       width:imageWidth
                      height:imageHeight
                 windowWidth:WW_WL.WW
                windowCenter:WW_WL.WL
             samplesPerPixel:1
                 resetScroll:YES];
    
    
    dicom2DView.frame = CGRectMake(self.dicom2DView.frame.origin.x, self.dicom2DView.frame.origin.y, self.dicom2DView.frame.size.width, self.dicom2DView.frame.size.width);
    [dicom2DView setNeedsDisplay];
    
    NSString * info = [NSString stringWithFormat:@"WW/WL: %d / %d", dicom2DView.winWidth, dicom2DView.winCenter];
    self.windowInfo.text = info;
    
    SAFE_FREE(sliceData);

}

//YOZ平面 算法&绘制
- (void)createYOZView:(int)Xslice WW_WL:(WW_And_WL)WW_WL
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

    SAFE_FREE(sliceData);
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
    
    SAFE_FREE(sliceData);
}

#pragma - mark slider - function
//slider 滑动时 显示图像的函数
- (void)valueChaged:(UISlider *)sender
{
    // 需要修改啊～～～～～～～～～～～对于slider的判断
	int value= (int)sender.value ;
    
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
                if (value < dataSize_Y) {
                    [self createXOZView:value WW_WL:eachWW_WL[2]];
                    sliderValues[2] = value;
                }
            }
        }
    }
}



#pragma mark - Dicom slices to DataVolume
//解析单幅图像, 图像数据出口
- (ushort **) decodeAndReadOneSliceData:(NSString *) path
{
    [self decode:path];
    if (!dicomDecoder.dicomFound || !dicomDecoder.dicomFileReadSuccess) 
    {
        dicomDecoder = nil;
        return nil;
    }
    
    NSInteger imageWidth      = dicomDecoder.width;
    NSInteger imageHeight     = dicomDecoder.height;
    
    //获得解析过的图像数据，一维
    ushort * pixels16 = [dicomDecoder getPixels16];
    
    //申请空间
    ushort ** sliceData = (ushort **)calloc(imageHeight, sizeof(ushort *));
    for (int i=0; i<imageHeight; i++)
        sliceData[i]= (ushort *)calloc(imageWidth, sizeof(ushort));
    
    //一维转二维
    int i,j;
    for (i=0;i<imageHeight;i++)
		for (j=0;j<imageWidth;j++)
			sliceData[i][j] = pixels16[  (i * imageWidth) + j];
  
    return sliceData;
}

- (Byte **) ConvertOneSliceData:(NSString *) path
{
    [self decode:path];
    if (!dicomDecoder.dicomFound || !dicomDecoder.dicomFileReadSuccess)
    {
        dicomDecoder = nil;
        return nil;
    }
    
    NSInteger imageWidth      = dicomDecoder.width;
    NSInteger imageHeight     = dicomDecoder.height;
    
    //获得解析过的图像数据，一维
    DicomPixelsConverter *dicomPixelsConverter = [[DicomPixelsConverter alloc] init];

    Byte *pixels16 = [dicomPixelsConverter setPixels16:[dicomDecoder getPixels16]
                                                 width:imageWidth
                                                height:imageHeight
                                           windowWidth:dicomDecoder.windowWidth
                                          windowCenter:dicomDecoder.windowCenter];
    
    //申请空间
    Byte ** sliceData = (Byte **)calloc(imageHeight, sizeof(Byte *));
    for (int i=0; i<imageHeight; i++)
        sliceData[i]= (Byte *)calloc(imageWidth, sizeof(Byte));
    
    //一维转二维
    int i,j;
    for (i=0;i<imageHeight;i++)
		for (j=0;j<imageWidth;j++)
			sliceData[i][j] = pixels16[  (i * imageWidth) + j];
    
    return sliceData;
}





#pragma mark -
#pragma mark - View lifecycle

- (void) dealloc
{
    scrollView = nil;
    self.dicom2DView = nil;
    self.dicom2DView2 = nil;
    self.dicom2DView3 = nil;

    self.patientName = nil;
    self.modality = nil;
    self.windowInfo = nil;
    self.date = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    //read files from document path
    [self readDicomDataFromDocDir];
  
    //initlize the UIElement
    [self initParameter];
    
    self.viewIndicator.text = @"Tap to choose one Plane";
}

- (void)initParameter {
    //添加slider动作
    [slider addTarget:self action:@selector(valueChaged:) forControlEvents:UIControlEventValueChanged];
    //初始化slider对象属性， min，max， init位置
    slider.minimumValue = 1;
	slider.maximumValue = Documents_Num;
	slider.value = MIN(MIN(dataSize_X, dataSize_Y), dataSize_Z) / 2 ;
    for (int i = 0; i < 4; i++) {
        sliderValues[i] = slider.value;
    }
    
    //设置Labels, 按tag提取 信息
    NSString * info;
    info = [dicomDecoder infoFor:PATIENT_NAME];
    self.patientName.text = [NSString stringWithFormat:@"Patient: %@", info];
    info = [dicomDecoder infoFor:MODALITY];
    self.modality.text = [NSString stringWithFormat:@"Modality: %@", info];
    info = [dicomDecoder infoFor:SERIES_DATE];
    self.date.text = info;
    
    //设置各个view
    viewInBigMode = none;
    chooseView = xoy;
    
    eachWW_WL[0].WW = dicomDecoder.windowWidth;
    eachWW_WL[0].WL = dicomDecoder.windowCenter;
    eachWW_WL[1] = eachWW_WL[2] = eachWW_WL[3] = eachWW_WL[0];

    [self createYOZView:sliderValues[1] WW_WL:eachWW_WL[1]];
    [self createXOZView:sliderValues[2] WW_WL:eachWW_WL[2]];
    [self createXOYView:sliderValues[0] WW_WL:eachWW_WL[0]];
   
    //记录Axical view的左上座标作为 bigViewMode 的 左上座标
    scrollViewOriginPoint = CGPointMake(dicom2DView.frame.origin.x, dicom2DView.frame.origin.y);

    //parameter for main pan
    sumTrans = CGPointMake(0, 0);
    sumTransInView = CGPointMake(0, 0);
    
    //it seems i do not use it
    self.centerPoint = CGPointMake(0, 0);
}



- (void)viewDidUnload
{
    [super viewDidUnload];
    SAFE_FREE(imagesVolume);
    scrollView = nil;
    self.dicom2DView = nil;
    self.dicom2DView2 = nil;
    self.dicom2DView3 = nil;
    
    self.patientName = nil;
    self.modality = nil;
    self.windowInfo = nil;
    self.date = nil;
    
}

// 读取Documents里的文件
- (void)readDicomDataFromDocDir {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    //get document's path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSLog(@"Document Path: %@", documentsDirectory);
    //get the files's name, save in an array
    NSError *error = nil;
    NSMutableArray *fileNameArray = [[fm contentsOfDirectoryAtPath:documentsDirectory error:&error] mutableCopy];
    if (error) {
        NSLog(@"read files error: %@", [error localizedDescription]);
    }
    
    //Delete useless file
    for (NSString * content in fileNameArray) {
        if ([content isEqual:@".DS_Store"]) {
            [fileNameArray removeObject:content];
            break;
        }
    }
    
    Documents_Num = [fileNameArray count];
    //为图像数据体申请空间
    imagesVolume = (ushort ***)calloc(Documents_Num, sizeof(ushort **));
    images256Volume = (Byte ***)calloc(Documents_Num, sizeof(Byte **));


    
    if (Documents_Num!=0) { //如果Document目录下有文件
        //遍历，生成 图像数据体
        for (int i=0; i<[fileNameArray count]; i++)
        {
            NSString *fileName = [fileNameArray objectAtIndex:i];
            NSString *absolutePathOfFile = [documentsDirectory stringByAppendingPathComponent:fileName];
            imagesVolume[i] = [self decodeAndReadOneSliceData:absolutePathOfFile];
            images256Volume[i] = [self ConvertOneSliceData:absolutePathOfFile];
        }
        flag_data_read=true;
        
        //获取数据体的三维
        dataSize_X =dicomDecoder.width;
        dataSize_Y =dicomDecoder.height;
        dataSize_Z = Documents_Num - 1;

    }
    else {
        NSString *dicomPath = [[NSBundle mainBundle] pathForResource:@"14" ofType:nil ];
        [self decodeAndDisplay:dicomPath];
        
        self.viewIndicator.text = @"No Dicoms in Document";
    }
}


#pragma mark -
#pragma mark - Dicom View Display
//获取DICOM数据，解析
- (void) decode:(NSString *)path
{
    if (!dicomDecoder) {
        dicomDecoder = [[KSDicomDecoder alloc] init];
    }
    [dicomDecoder setDicomFilename:path];

}
//获取DICOM数据，解析并生成图像
- (void) decodeAndDisplay:(NSString *)path
{        
    [self decode:path];
    [self displayWith:dicomDecoder.windowWidth windowCenter:dicomDecoder.windowCenter];
}

- (void) displayWith:(NSInteger)windowWidth windowCenter:(NSInteger)windowCenter
{
    if (!dicomDecoder.dicomFound || !dicomDecoder.dicomFileReadSuccess) 
    {
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
        //获取图像数据（一维）from Decoder
        ushort * pixels16 = [dicomDecoder getPixels16];
        
        //如果窗宽窗位没有设置，遍历，找到max，min（说明图像数据里存储的是灰度信息), 计算出窗宽、窗位
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
            winWidth = (NSInteger)((max + min)/2.0 + 0.5); //中值
            winCenter = (NSInteger)((max - min)/2.0 + 0.5); //中心距两端的距离
        }
        
        //is the indicator of Pixel Representation(0028, 0103)
        dicom2DView.signed16Image = signedImage;

        //把数据交给view，生成bitmap图像
        [dicom2DView setPixels16:pixels16
                           width:imageWidth
                          height:imageHeight
                     windowWidth:winWidth
                    windowCenter:winCenter
                 samplesPerPixel:samplesPerPixel
                     resetScroll:YES];
        
        //重绘
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

        //更新 WW/WL Label
        NSString * info = [NSString stringWithFormat:@"WW/WL: %d / %d", dicom2DView.winWidth, dicom2DView.winCenter];
        self.windowInfo.text = info;
    }
}


#pragma mark -
#pragma mark - Gesture




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
    
    [mainView addSubview:scrollView];
}

- (void)RemoveScrollView: (UITapGestureRecognizer *)sender {
    [sender.view removeFromSuperview];
    [scrollView removeFromSuperview];
    scrollView = nil;
    [mainView addSubview:sender.view];
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




/////////////////////////add by Xutq///////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ---panning (or Dragging)---3
// ---handle pan gesture---
-(IBAction)handlePanGestureToPanImage:(UIGestureRecognizer *)sender
{
    CGPoint translation = [(UIPanGestureRecognizer *) sender translationInView:dicom2DView];
    
    if ([Manipulation  isEqual: @"Transform"]) {
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
    progressAlert = NULL;
    
    
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
