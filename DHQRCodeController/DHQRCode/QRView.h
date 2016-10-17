//
//  QRView.h
//  QRWeiXinDemo
//
//  Created by lovelydd on 15/4/25.
//  Copyright (c) 2015年 lovelydd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QRView : UIView

/**
 *  透明的区域
 */
@property (nonatomic, assign) CGSize transparentArea;

// 扫描到结果后移动四个角块
- (void)moveToPoint:(NSArray *)points;

@end
