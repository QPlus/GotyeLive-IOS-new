//
//  SettingMenuView.m
//  QMZB
//
//  Created by 刘淦 on 5/6/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import "SettingMenuView.h"

@implementation SettingMenuView
{
    IBOutlet UIView *viewBack;
}


- (id)init
{
    self = [[[NSBundle mainBundle] loadNibNamed:@"SettingMenuView" owner:self options:nil] firstObject];
    
    if(self){
        MakeCornerRound(viewBack, 5);
    }
    
    return self;
}



// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    UIBezierPath *path = [[UIBezierPath alloc] init];

    [path moveToPoint:CGPointMake((vw(self) - 25)/2, vb(viewBack))];
    [path addLineToPoint:CGPointMake((vw(self) - 25)/2 + 25, vb(viewBack))];
    [path addLineToPoint:CGPointMake(vw(self) / 2, vh(self))];
    [path closePath];
    
    
    //三角形内填充绿色
    [viewBack.backgroundColor setFill];
    [path fill];
}


@end
