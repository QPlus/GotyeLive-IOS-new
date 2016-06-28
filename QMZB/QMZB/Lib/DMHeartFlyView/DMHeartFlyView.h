//
//  DMHeartFlyView.h
//  DMHeartFlyAnimation
//
//  Created by Rick on 16/3/9.
//  Copyright © 2016年 Rick. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define kWidthHeart         25

@interface DMHeartFlyView : UIView
-(void)animateInView:(UIView *)view;
-(instancetype)initWithFrame:(CGRect)frame index:(int)index;

@end

