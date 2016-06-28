//
//  NavigationView.m
//  QMZB
//
//  Created by 刘淦 on 5/4/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import "NavigationView.h"

#define kTabIndexFocus      0
#define kTabIndexHot        1
#define kTabIndexLatest     2


@implementation NavigationView
{
    CGPoint oldCenter;
    NSInteger currentIndex;
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
    self = [[[NSBundle mainBundle] loadNibNamed:@"NavigationView" owner:self options:nil] firstObject];
    
    if(self){
        self.frame = CGRectMake(0, 0, kScreenWidth, 64);
        currentIndex = kTabIndexHot;
        self.imageViewIndicator.hidden = NO;
        self.labelIndicator.hidden = YES;
        self.labelIndicator.alpha = 0.f;
        
        CGRect frame = vf(self.labelIndicator);
        fx(frame) = (kScreenWidth - fw(frame)) / 2;
        vf(self.labelIndicator) = frame;
        
        oldCenter = self.labelIndicator.center;
    }
    
    return self;
}

- (IBAction)onButtonClick:(id)sender
{
    switch ([sender tag]) {
        case kTabIndexFocus:
        {
            if(currentIndex == kTabIndexFocus){
                return;
            }
            
            currentIndex = kTabIndexFocus;
            
            self.imageViewIndicator.hidden = YES;
            self.labelIndicator.alpha = 0.f;
            self.labelIndicator.hidden = NO;
            
            beginAnimation(0, .3f, UIViewAnimationCurveEaseOut);
            self.labelIndicator.alpha = 1.f;
            CGPoint center = self.buttonFocus.center;
            center.y = vy(self.labelIndicator);
            self.labelIndicator.center = center;
            endAnimation;
        }
            break;
        case kTabIndexHot:
        {
            if(currentIndex == kTabIndexHot){
                return;
            }
            
            currentIndex = kTabIndexHot;
            self.imageViewIndicator.hidden = NO;
            self.labelIndicator.hidden = YES;
            self.labelIndicator.alpha = 0.f;
            self.labelIndicator.center = oldCenter;
        }
            break;
        case kTabIndexLatest:
        {
            
        }
            return;
            
        default:
            break;
    }
}

@end
