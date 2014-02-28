//
//  KSViewController.h
//  DicomViewer
//
//  Created by Niukenan on 13-6-13.
//  Copyright (c) 2013年 United-Imaging. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainView.h"
#import "DeckView.h"

@class KSDicom2DView;
@class KSDicomDecoder;

@class DeckView;
@class MainView;

@interface KSViewController : UIViewController <UIAlertViewDelegate, UIScrollViewDelegate>
{
    DeckView *deckView;
    MainView *mainView;
    
    
    KSDicom2DView   *dicom2DView;
    KSDicom2DView   *dicom2DView2;
    KSDicom2DView   *dicom2DView3;
    KSDicom2DView   *dicom2DView4;
    
    KSDicomDecoder  *dicomDecoder;
    
    
    UILabel * patientName;
    UILabel * modality;
    UILabel * windowInfo;
    UILabel * date;
    
    IBOutlet UISlider *slider;
    IBOutlet UIButton *btnDataRead;
    IBOutlet UISegmentedControl *segmentedWW_WL_Trans;
    
    //IBOutlet UIActivityIndicatorView * sysView;
    UIAlertView *progressAlert;
    
    UIPanGestureRecognizer *panGesture;
    CGAffineTransform prevTransform;
    CGPoint startPoint;
    
    UIScrollView * scrollView;
    
}


//Outlet - View
@property (nonatomic, retain) IBOutlet KSDicom2DView *dicom2DView;
@property (retain, nonatomic) IBOutlet KSDicom2DView *dicom2DView2;
@property (retain, nonatomic) IBOutlet KSDicom2DView *dicom2DView3;
@property (retain, nonatomic) IBOutlet KSDicom2DView *dicom2DView4;


//Outlet - Label
@property (retain, nonatomic) IBOutlet UILabel *viewIndicator;

@property (nonatomic, retain) IBOutlet UILabel * patientName;
@property (nonatomic, retain) IBOutlet UILabel * modality;
@property (nonatomic, retain) IBOutlet UILabel * windowInfo;
@property (nonatomic, retain) IBOutlet UILabel * date;


@property (nonatomic, retain) UISlider *slider;
@property (nonatomic, retain) UIButton *btnDataRead;
@property (retain, nonatomic) IBOutlet UISegmentedControl *seg_indicator_Trans_or_WW_WL;
@property (retain, nonatomic) IBOutlet UISwitch *switch_indicator_Link_WW_WL;

@property (retain, nonatomic) IBOutlet UITapGestureRecognizer *SingleTap;
@property (retain, nonatomic) IBOutlet UITapGestureRecognizer *DoubleTap;

@property (nonatomic) CGPoint centerPoint;

//@property(nonatomic, retain) UIActivityIndicatorView * sysView;


//MPR data read
-(IBAction)btnDataRead:(id)sender;



- (IBAction)reDownLoadFromServer:(id)sender;
- (IBAction)switch_Link_WW_WL:(UISwitch *)sender;

#pragma mark gesture
#pragma  xoy
- (IBAction)handleSingleTap:(UITapGestureRecognizer *)sender;
- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)sender;
#pragma yoz
- (IBAction)handleYOZViewSingleTap:(UITapGestureRecognizer *)sender;
- (IBAction)handleYOZViewLongPress:(UILongPressGestureRecognizer *)sender;
#pragma xoz
- (IBAction)handleXOZViewSingleTap:(UITapGestureRecognizer *)sender;
- (IBAction)handleXOZViewLongPress:(UILongPressGestureRecognizer *)sender;


- (IBAction)handlePan:(UIPanGestureRecognizer *)sender;
- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)sender;
- (IBAction)handlePinch:(UIPinchGestureRecognizer *)sender;

#pragma mainView
- (IBAction)handleMainViewPan:(UIPanGestureRecognizer *)sender;


@end









