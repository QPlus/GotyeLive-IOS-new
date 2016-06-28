//
//  PresentCollectionViewCell.m
//  QMZB
//
//  Created by Jim on 16/4/20.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "PresentCollectionViewCell.h"
#import "QMZBUIUtil.h"

@interface PresentCollectionViewCell ()

@property (nonatomic, strong) NSString * image;

@property (nonatomic, strong) NSString * flowerName;

@end

@implementation PresentCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _bgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
        [self addSubview:_bgImageView];
        
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 50, 50, 20)];
        _nameLabel.textColor = BACKGROUND_DARK_COLOR;
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.font = [UIFont boldSystemFontOfSize:11];
        [self addSubview:_nameLabel];
        
    }
    
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _nameLabel.text = self.flowerName;
//    self.backgroundColor = [UIColor grayColor];
    UIImage *img = [UIImage imageNamed:self.image];
    img = [img stretchableImageWithLeftCapWidth:10 topCapHeight:10];
    _bgImageView.image = img;
}


- (void)fillCollectionCellWithImage:(NSString *)imageName Name:(NSString *)name
{
    self.image = imageName;
    self.flowerName = name;
}

@end
