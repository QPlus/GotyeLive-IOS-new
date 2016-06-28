//
//  GiftView.m
//  QMZB
//
//  Created by 刘淦 on 5/11/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import "GiftView.h"
#import "NumView.h"

@implementation GiftView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)init
{
    self = [[[NSBundle mainBundle] loadNibNamed:@"GiftView" owner:self options:nil] firstObject];
    
    if(self){
        MakeCornerRound(self.buttonAvatar, vh(self.buttonAvatar) / 2);
    }
    
    return self;
}

- (void)addNumView
{
    NumView *numView = [[NumView alloc] init];
//    numView.center = CGPointMake(vr(self.imageViewGift) + vw(numView)* 2.f / 5, vy(self.imageViewGift) + vh(numView) / 2);
    CGRect frame = numView.frame;
    fx(frame) = vr(self.imageViewGift) - 5;
    fy(frame) = vy(self.imageViewGift);
    numView.frame = frame;
    [numView setCount: 1];
    [self addSubview: numView];
    
    numView.transform = CGAffineTransformMakeScale(8, 8);
    //Bloom
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:20 options:UIViewAnimationOptionCurveEaseOut animations:^{
        numView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)onGiftViewDisappear
{
    [self removeFromSuperview];
}

@end
