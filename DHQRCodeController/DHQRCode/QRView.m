//
//  QRView.m
//  QRWeiXinDemo
//
//  Created by lovelydd on 15/4/25.
//  Copyright (c) 2015年 lovelydd. All rights reserved.
//

#import "QRView.h"


static NSTimeInterval kQrLineanimateDuration = 0.01;

@implementation QRView {

    UIImageView *qrLine;
    CGFloat     qrLineY;
  
    UIImageView *left_U;
    UIImageView *left_D;
    UIImageView *right_U;
    UIImageView *right_D;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!qrLine) {
        [self initQRLine];
        
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:kQrLineanimateDuration target:self selector:@selector(show) userInfo:nil repeats:YES];
        [timer fire];
    }
}

- (void)initQRLine {
    qrLine              = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width / 2 - self.transparentArea.width / 2, self.bounds.size.height / 2 - self.transparentArea.height / 2, self.transparentArea.width, 2)];
    qrLine.image        = [UIImage imageNamed:@"line"];
    qrLine.contentMode  = UIViewContentModeScaleAspectFill;
    [self addSubview:qrLine];
    qrLineY             = qrLine.frame.origin.y;
}

- (void)show {
    [UIView animateWithDuration:kQrLineanimateDuration animations:^{
        CGRect rect     = qrLine.frame;
        rect.origin.y   = qrLineY;
        qrLine.frame    = rect;
    } completion:^(BOOL finished) {
        CGFloat maxBorder = self.frame.size.height / 2 + self.transparentArea.height / 2 - 4;
        if (qrLineY > maxBorder) {
            qrLineY = self.frame.size.height / 2 - self.transparentArea.height /2;
        }
        qrLineY++;
    }];
}

- (void)drawRect:(CGRect)rect {
    //整个二维码扫描界面的颜色
    CGSize screenSize       =[UIScreen mainScreen].bounds.size;
    CGRect screenDrawRect   =CGRectMake(0, 0, screenSize.width,screenSize.height);
    
    //中间清空的矩形框
    CGRect clearDrawRect    = CGRectMake(screenDrawRect.size.width / 2 - self.transparentArea.width / 2,
                                         screenDrawRect.size.height / 2 - self.transparentArea.height / 2,
                                         self.transparentArea.width,self.transparentArea.height);
    
    CGContextRef ctx        = UIGraphicsGetCurrentContext();
    [self addScreenFillRect:ctx rect:screenDrawRect];
    
    [self addCenterClearRect:ctx rect:clearDrawRect];
    
    [self addWhiteRect:ctx rect:clearDrawRect];
    
    [self addConorImage:clearDrawRect];
}

- (void)addScreenFillRect:(CGContextRef)ctx rect:(CGRect)rect {
    CGContextSetRGBFillColor(ctx, 40 / 255.0,40 / 255.0,40 / 255.0,0.7);
    CGContextFillRect(ctx, rect);   //draw the transparent layer
}

- (void)addCenterClearRect :(CGContextRef)ctx rect:(CGRect)rect {
    CGContextClearRect(ctx, rect);  //clear the center rect  of the layer
}

- (void)addWhiteRect:(CGContextRef)ctx rect:(CGRect)rect {
    CGContextStrokeRect(ctx, rect);
    CGContextSetRGBStrokeColor(ctx, 1, 1, 1, 1);
    CGContextSetLineWidth(ctx, 0.8);
    CGContextAddRect(ctx, rect);
    CGContextStrokePath(ctx);
}

- (void)addCornerLineWithContext:(CGContextRef)ctx rect:(CGRect)rect {
    
    //画四个边角
    CGContextSetLineWidth(ctx, 2);
    CGContextSetRGBStrokeColor(ctx, 83 /255.0, 239/255.0, 111/255.0, 1);//绿色
    
    //左上角
    CGPoint poinsTopLeftA[] = {
        CGPointMake(rect.origin.x+0.7, rect.origin.y),
        CGPointMake(rect.origin.x+0.7 , rect.origin.y + 15)
    };
    
    CGPoint poinsTopLeftB[] = {CGPointMake(rect.origin.x, rect.origin.y +0.7),CGPointMake(rect.origin.x + 15, rect.origin.y+0.7)};
    [self addLine:poinsTopLeftA pointB:poinsTopLeftB ctx:ctx];
    
    //左下角
    CGPoint poinsBottomLeftA[] = {CGPointMake(rect.origin.x+ 0.7, rect.origin.y + rect.size.height - 15),CGPointMake(rect.origin.x +0.7,rect.origin.y + rect.size.height)};
    CGPoint poinsBottomLeftB[] = {CGPointMake(rect.origin.x , rect.origin.y + rect.size.height - 0.7) ,CGPointMake(rect.origin.x+0.7 +15, rect.origin.y + rect.size.height - 0.7)};
    [self addLine:poinsBottomLeftA pointB:poinsBottomLeftB ctx:ctx];
    
    //右上角
    CGPoint poinsTopRightA[] = {CGPointMake(rect.origin.x+ rect.size.width - 15, rect.origin.y+0.7),CGPointMake(rect.origin.x + rect.size.width,rect.origin.y +0.7 )};
    CGPoint poinsTopRightB[] = {CGPointMake(rect.origin.x+ rect.size.width-0.7, rect.origin.y),CGPointMake(rect.origin.x + rect.size.width-0.7,rect.origin.y + 15 +0.7 )};
    [self addLine:poinsTopRightA pointB:poinsTopRightB ctx:ctx];
    
    CGPoint poinsBottomRightA[] = {CGPointMake(rect.origin.x+ rect.size.width -0.7 , rect.origin.y+rect.size.height+ -15),CGPointMake(rect.origin.x-0.7 + rect.size.width,rect.origin.y +rect.size.height )};
    CGPoint poinsBottomRightB[] = {CGPointMake(rect.origin.x+ rect.size.width - 15 , rect.origin.y + rect.size.height-0.7),CGPointMake(rect.origin.x + rect.size.width,rect.origin.y + rect.size.height - 0.7 )};
    [self addLine:poinsBottomRightA pointB:poinsBottomRightB ctx:ctx];
    CGContextStrokePath(ctx);
}

- (void)addLine:(CGPoint[])pointA pointB:(CGPoint[])pointB ctx:(CGContextRef)ctx {
    CGContextAddLines(ctx, pointA, 2);
    CGContextAddLines(ctx, pointB, 2);
}

- (void)addConorImage:(CGRect)rect {
  left_U            = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LU"]];
  [self addSubview:left_U];
  left_U.center     = rect.origin;
  
  left_D            = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"LD"]];
  [self addSubview:left_D];
  CGPoint d1        = rect.origin;
  d1.y += rect.size.width;
  left_D.center     = d1;
  
  right_U           = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RU"]];
  [self addSubview:right_U];
  CGPoint u1        = rect.origin;
  u1.x += rect.size.width;
  right_U.center    = u1;
  
  right_D           = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RD"]];
  [self addSubview:right_D];
  CGPoint d2        = rect.origin;
  d2.x += rect.size.width;
  d2.y += rect.size.width;
  right_D.center    = d2;
}

- (void)moveToPoint:(NSArray *)points {
  if (4 == points.count) {
    // 数据空时不做处理
    // 整个二维码扫描界面的颜色
    CGSize screenSize       =[UIScreen mainScreen].bounds.size;
    CGRect screenDrawRect   =CGRectMake(0, 0, screenSize.width,screenSize.height);
    
    // 中间清空的矩形框
    CGRect clearDrawRect    = CGRectMake(screenDrawRect.size.width / 2 - self.transparentArea.width / 2,
                                         screenDrawRect.size.height / 2 - self.transparentArea.height / 2,
                                         self.transparentArea.width,self.transparentArea.height);
    
    NSDictionary *one   = points[0];
    CGPoint u1          = clearDrawRect.origin;
    u1.x                = [[one objectForKey:@"X"] floatValue];
    u1.y                = [[one objectForKey:@"Y"] floatValue];
    
    NSDictionary *two   = points[1];
    CGPoint d1          = clearDrawRect.origin;
    d1.x                = [[two objectForKey:@"X"] floatValue];
    d1.y                = [[two objectForKey:@"Y"] floatValue];
    
    NSDictionary *three = points[2];
    CGPoint d2          = clearDrawRect.origin;
    d2.x                = [[three objectForKey:@"X"] floatValue];
    d2.y                = [[three objectForKey:@"Y"] floatValue];
    
    NSDictionary *four  = points[3];
    CGPoint u2          = clearDrawRect.origin;
    u2.x                = [[four objectForKey:@"X"] floatValue];
    u2.y                = [[four objectForKey:@"Y"] floatValue];
    
    [UIView animateWithDuration:0.2 animations:^{
      left_U.center     = u1;
      left_D.center     = d1;
      right_D.center    = d2;
      right_U.center    = u2;
    }];
  }
}

@end
