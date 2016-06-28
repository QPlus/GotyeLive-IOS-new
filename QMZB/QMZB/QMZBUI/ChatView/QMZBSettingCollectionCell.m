//
//  QMZBSettingCollectionCell.m
//  QMZB
//
//  Created by Jim on 16/5/16.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBSettingCollectionCell.h"

@implementation QMZBSettingCollectionCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.image = [[UIImageView alloc] initWithFrame:CGRectMake(frame.size.width *0.5 - 20, 20, 40,  40)];
        self.image.contentMode = UIViewContentModeScaleAspectFill;
        self.image.clipsToBounds = YES;
        //self.image.backgroundColor = [UIColor clearColor];
        
        
        self.name = [[UILabel alloc] initWithFrame:CGRectMake(0, 70, frame.size.width, 30)];
        self.name.textAlignment = NSTextAlignmentCenter;
        self.name.lineBreakMode = 0;
        self.name.textColor = TEXT_DARK_COLOR;
        self.name.font = [UIFont systemFontOfSize:14.0f];
        
        [self addSubview:self.image];
        [self addSubview:self.name];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
}

@end
