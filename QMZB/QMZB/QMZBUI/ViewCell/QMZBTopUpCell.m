//
//  QMZBTopUpCell.m
//  QMZB
//
//  Created by Jim on 16/5/4.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBTopUpCell.h"
#import "QMZBUIUtil.h"
#import "UIView+Extension.h"

@implementation QMZBTopUpCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        self.backgroundColor = BACKGROUND_COLOR;
        
        UIImageView *headImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 25, 25)];
        headImage.contentMode = UIViewContentModeScaleAspectFill;
        headImage.image = [UIImage imageNamed:@"masonry"];
        [self addSubview:headImage];
        
        _userName = [[UILabel alloc] init];
        _userName.frame = CGRectMake(CGRectGetMaxX(headImage.frame) + 5, 5, ScreenWidth/2, 40);
        _userName.font = [UIFont systemFontOfSize:14.f];
        _userName.textColor = TEXT_BLACK_COLOR;
        [self addSubview:_userName];
        
        _payName = [[UILabel alloc] init];
        _payName.frame = CGRectMake(CGRectGetMaxX(headImage.frame) + ScreenWidth/2+10, 5, ScreenWidth-CGRectGetMaxX(headImage.frame)-ScreenWidth/2-20, 40);
        _payName.textAlignment = NSTextAlignmentCenter;
        _payName.font = [UIFont systemFontOfSize:14.f];
        _payName.textColor = ORANGE_COLOR;
        [self addSubview:_payName];
        [_payName.layer setCornerRadius:5.0]; //设置矩形四个圆角半径
        [_payName.layer setBorderWidth:1.5f];   //边框宽度
        [_payName.layer setBorderColor:ORANGE_COLOR.CGColor];//边框颜色
        
    }
    
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
}


@end
