//
//  NumView.m
//  QMZB
//
//  Created by 刘淦 on 5/11/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import "NumView.h"

@implementation NumView
{
    IBOutlet UIView *view1, *view2, *view3;
    IBOutlet UILabel *label1b, *label1f, *label2b, *label2f, *label3b, *label3f;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (id)init
{
    self = [[[NSBundle mainBundle] loadNibNamed:@"NumView" owner:self options:nil] firstObject];
    
    if(self){
    }
    
    return self;
}

- (void)setCount:(NSInteger)count
{
    if(count < 0 || count > 1000) count = 999;
    
    NSInteger num1 = count / 100;
    NSInteger num2 = (count - num1 * 100) / 10;
    NSInteger num3 = count - num1 * 100 - num2 * 10;
    
    label3b.text = [NSString stringWithFormat:@"%ld", num3];
    label3f.text = [NSString stringWithFormat:@"%ld", num3];
    label2b.text = [NSString stringWithFormat:@"%ld", num2];
    label2f.text = [NSString stringWithFormat:@"%ld", num2];
    label1b.text = [NSString stringWithFormat:@"%ld", num1];
    label1f.text = [NSString stringWithFormat:@"%ld", num1];
    
    if(num1 > 0){
        view1.hidden = NO;
        view2.hidden = NO;
        view3.hidden = NO;
        return;
    }
    
    vf(view3) = vf(view2);
    vf(view2) = vf(view1);
    
    if(num2 > 0){
        view2.hidden = NO;
        view3.hidden = NO;
        return;
    }
    
    vf(view3) = vf(view2);
    view3.hidden = NO;
}

@end
