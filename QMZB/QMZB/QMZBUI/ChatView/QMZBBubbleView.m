//
//  QMZBBubbleView.m
//  QMZB
//
//  Created by Jim on 16/4/26.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBBubbleView.h"
#import "QMZBUIUtil.h"
#import "UIView+Extension.h"

@implementation QMZBBubbleView
{
    UILabel *_labelName;
    UILabel *_contentLabel;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0]];
        
        _labelName = [[UILabel alloc] initWithFrame:CGRectMake(5, 6, 1, 30)];
        [_labelName setFont:[UIFont systemFontOfSize:14]];
        [_labelName setTextColor:TEXT_RED_COLOR];
        [_labelName setNumberOfLines:1];
        [self addSubview:_labelName];
        
        _contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 6, 1, 30)];
        [_contentLabel setFont:[UIFont systemFontOfSize:14]];
        [_contentLabel setTextColor:TEXT_BLACK_COLOR];
        [_contentLabel setNumberOfLines:1];
        [self addSubview:_contentLabel];
        
        [self.layer setMasksToBounds:YES];
        [self.layer setCornerRadius:15];
        
        [self setClipsToBounds:YES];
    }
    return self;
}


- (void)setPresenterWithNickname:(NSString *)nickName withContent:(NSString *)content
{
    [_contentLabel setText:content];
    if ([nickName isEqualToString:@""]) {
        [_contentLabel sizeToFit];
        self.width = _contentLabel.width+10;
    }else {
        
        [_contentLabel sizeToFit];
        UIFont *font = _labelName.font;
        NSString *nicName = [NSString stringWithFormat:@"%@:",nickName];
        [_labelName setText:nicName];
        CGSize size = [_labelName.text boundingRectWithSize:CGSizeMake( 4000.f, 30)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:@{NSFontAttributeName: font}
                                                    context:nil].size;
        [_labelName setFrame:CGRectMake(5, 0, size.width, 30)];
        [_contentLabel setFrame:CGRectMake(size.width+5, 0, _contentLabel.width, 30)];
        self.width = _contentLabel.width+10+size.width;
    }
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
