//
//  QMZBLiveCell.m
//  QMZB
//
//  Created by Jim on 16/3/23.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBLiveCell.h"
#import "QMZBUIUtil.h"
#import "UIImageView+WebCache.h"
#import "QMZBNetWork.h"

@interface QMZBLiveCell()

@property (nonatomic , strong) id object;

@end
@implementation QMZBLiveCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        CGRect frame = vf(self);
        fh(frame) = kScreenWidth + kHeightOffsetLiveRoomCell;
        vf(self) = frame;

        self.backgroundColor = BACKGROUND_COLOR;
        
        _headImage = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 30, 30)];
        _headImage.contentMode = UIViewContentModeScaleAspectFill;
        _headImage.clipsToBounds = YES;
        [self addSubview:_headImage];
        
        MakeCornerRound(_headImage, vh(_headImage) / 2);
        
        self.imageViewPreview = [[UIImageView alloc] initWithFrame: CGRectMake(0, 46, kScreenWidth, kScreenWidth)];
        self.imageViewPreview.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview: self.imageViewPreview];
        
        _userName = [[UILabel alloc] init];
        _userName.frame = CGRectMake(vr(_headImage) + 5, _headImage.center.y - 15, ScreenWidth/2, 30);
        _userName.font = [UIFont boldSystemFontOfSize:14.f];
        _userName.textColor = TEXT_BLACK_COLOR;
        [self addSubview:_userName];
        
        _liveRoomTopic = [[UILabel alloc] init];
        _liveRoomTopic.frame = CGRectMake(kScreenWidth - 80 - 10, 60, 80, 26);
        _liveRoomTopic.font = [UIFont boldSystemFontOfSize:14.f];
        _liveRoomTopic.textAlignment = NSTextAlignmentCenter;
        _liveRoomTopic.textColor =[UIColor whiteColor];
        _liveRoomTopic.text = @"直播中";
        _liveRoomTopic.clipsToBounds = YES;
        [self addSubview:_liveRoomTopic];
        MakeBorderRoundWithColor(_liveRoomTopic, vh(_liveRoomTopic) / 2, [UIColor whiteColor], 1);
        
        UIImageView *peoplecount = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_headImage.frame) + 10, 68, 16, 16)];
        peoplecount.image = [UIImage imageNamed:@"peoplecount"];
        peoplecount.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:peoplecount];
        
        peoplecount.hidden = YES;
        
        _followCount = [[UILabel alloc] init];
        _followCount.frame = CGRectMake(kScreenWidth - 130, 13, 100, 30);
        _followCount.textAlignment = NSTextAlignmentRight;
        _followCount.font = [UIFont systemFontOfSize:20.f];
        _followCount.textColor = [UIColor colorWithRed:177/255.f green:127/255.f blue:180.f alpha:1.f];
        [self addSubview:_followCount];
        
        CGRect frame1 = vf(_followCount);
        fx(frame1) = fr(frame1);
        fw(frame1) = 30;
        fy(frame1) = 20;
        fh(frame1) = 20;
        UILabel *label = [[UILabel alloc] initWithFrame: frame1];
        label.textColor = [UIColor lightGrayColor];
        label.font = [UIFont systemFontOfSize: 12];
        label.text = @"在看";
        [self addSubview: label];
        
        _followButton = [[UIButton alloc] init];
        _followButton.frame = CGRectMake(ScreenWidth-50, kScreenWidth, 40, 40);
        _followButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0);
        [self addSubview:_followButton];
        
    }
    
    return self;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.object) {
        
        _listModel = self.object;
        
        if ([_listModel.anchorIcon intValue]==0) {
            _headImage.image = [UIImage imageNamed:@"load"];
            self.imageViewPreview.image = [UIImage imageNamed:@"beauty.png"];

        }else {
            
            [_headImage setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
            [self.imageViewPreview setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHighPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"moren.png"]];
        }
        
        _userName.text = [NSString stringWithFormat:@"%@",_listModel.anchorName];
        _followCount.text = [NSString stringWithFormat:@"%@",_listModel.playerCount];
        if ([_listModel.isFollow integerValue] == 1) {
            
            [_followButton setImage:[UIImage imageNamed:@"icon_follow_yes"] forState:UIControlStateNormal];
        }else {
            [_followButton setImage:[UIImage imageNamed:@"icon_follow_no"] forState:UIControlStateNormal];
        }

        [_followButton addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];

    }
}

- (void)fillCellWithObject:(id)object
{
    self.object = object;
}

- (void)awakeFromNib
{
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)click:(id)seder
{
    UIButton *button = seder;
    if (self.didSelectedButton != nil) {
        self.didSelectedButton(button);
    }
}

@end
