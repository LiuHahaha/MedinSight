//
//  BackgrandView.m
//  DicomViewer
//
//  Created by Niukenan on 13-6-13.
//  Copyright (c) 2013年 United-Imaging. All rights reserved.
//

#import "BackgrandView.h"

@implementation BackgrandView

@synthesize scale = _scale;

#define DEFAULT_SCALE 0.9

- (CGFloat) scale {
    if (!_scale) {
        return DEFAULT_SCALE;
    } else {
        return _scale;
    }
}

- (void) setScale:(CGFloat)scale {
    if (scale != _scale) {
        _scale = scale;
        [self setNeedsDisplay];
    }
}


#pragma mark Lifecycle

- (void)setUp {
    self.contentMode = UIViewContentModeRedraw;
}

- (void)awakeFromNib {
    [self setUp];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}


-(void)drawLine:(CGPoint) lineMid withLength:(CGFloat) length inContext: (CGContextRef) context{
    
    UIGraphicsPushContext(context);
    CGPoint lineStart = lineMid;
    CGPoint lineEnd = lineMid;
    
    lineStart.y -= length/2;
    lineEnd.y += length/2;
    
#define RULER_MARK 3
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, lineStart.x, lineStart.y);
    CGContextAddLineToPoint(context, lineEnd.x, lineEnd.y);
    //let's enhance some mean point
    CGContextMoveToPoint(context, lineStart.x, lineStart.y);
    CGContextAddLineToPoint(context, lineStart.x-RULER_MARK, lineStart.y);
    
    CGContextMoveToPoint(context, lineMid.x, lineMid.y);
    CGContextAddLineToPoint(context, lineMid.x-RULER_MARK, lineMid.y);
    
    CGContextMoveToPoint(context, lineEnd.x, lineEnd.y);
    CGContextAddLineToPoint(context, lineEnd.x-RULER_MARK, lineEnd.y);
    
    CGContextStrokePath(context);
    
    //draw some text;
    UIFont *myFont = [UIFont systemFontOfSize:12.0];
    NSString *text = [NSString stringWithFormat:@"%.1f", self.scale];
    
    [[UIColor whiteColor] set];
    
    [text drawAtPoint:lineEnd withFont:myFont];
    
    UIGraphicsPopContext();
}


- (void)drawRect:(CGRect)rect
{
  
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    //the ruler
    CGContextSetLineWidth(ctx, 2.0);
    UIColor *custom = [[UIColor alloc] initWithRed:0.5 green:0.9 blue:0.5 alpha:0.8];
    [custom setStroke];
    
#define RULER_MARGIN_SCALE 0.05
#define RULER_UNIT 100
    CGPoint rulerMid;
    rulerMid.x = (self.bounds.origin.x + self.bounds.size.width * (1- RULER_MARGIN_SCALE));
    rulerMid.y = self.bounds.origin.y + self.bounds.size.height/2;
    
    if (self.scale <= 1.2 && self.scale >= 0.5)
        [self drawLine:rulerMid withLength:RULER_UNIT * self.scale inContext:ctx];
    else
        [self drawLine:rulerMid withLength:RULER_UNIT inContext:ctx];
    

    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
