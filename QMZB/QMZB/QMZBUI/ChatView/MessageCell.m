//
//  MessageCell.m
//  QMZB
//
//  Created by Jim on 16/4/27.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "MessageCell.h"
#import "QMZBUiUtil.h"
#import "UIView+Extension.h"


@interface MessageCell()

@property (nonatomic , strong) id object;

@property (nonatomic , assign) CGFloat width;

@end

@implementation MessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _messaheLable = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 50, kNormalHeight)];
        _messaheLable.editable = NO;
        _messaheLable.backgroundColor = [UIColor clearColor];
        _messaheLable.showsVerticalScrollIndicator = NO;
        _messaheLable.showsHorizontalScrollIndicator = NO;
        _messaheLable.textColor = [UIColor whiteColor];
        _messaheLable.font = [UIFont boldSystemFontOfSize: 16.f];
        [self addSubview:_messaheLable];
        
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
    if (!self.object) {
        return;
    }

    _messaheLable.frame = CGRectMake(0, 0, self.width, kNormalHeight);
    
    NSData *da= [self.object dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:da options:NSJSONReadingMutableContainers error:&error];
    if ([jsonObject isKindOfClass:[NSDictionary class]]){
        NSMutableAttributedString *str;
        NSDictionary *dictionary = (NSDictionary *)jsonObject;
        NSString *msgid = [dictionary objectForKey:@"msgid"];
        NSString *nickName = [dictionary objectForKey:@"nickname"];
        
        if ([msgid intValue]==0) {
            str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:大家好!",nickName]];
            [str addAttribute:NSForegroundColorAttributeName value:kColorNickname range:NSMakeRange(0,nickName.length+1)];
            [str addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(nickName.length + 1, str.length - nickName.length - 1)];
        }else if ([msgid intValue]==1) {
            NSDictionary *data = [dictionary objectForKey:@"data"];
            NSString *msgText = [data objectForKey:@"msg"];
            str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:%@",nickName,msgText]];
            [str addAttribute:NSForegroundColorAttributeName value:kColorNickname range:NSMakeRange(0,nickName.length+1)];
            [str addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(nickName.length + 1, str.length - nickName.length - 1)];
        }else if ([msgid intValue]==2) {

        }else if ([msgid intValue]==3) {
            NSDictionary *data = [dictionary objectForKey:@"data"];
            NSString *eventid = [data objectForKey:@"eventid"];
            NSMutableAttributedString *str;
            if ([eventid intValue] == 1) {
                str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:我送了一朵花!",nickName]];
            }else if ([eventid intValue] == 2) {
                str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:我送了一枚钻石!",nickName]];
            }else if ([eventid intValue] == 3) {
                str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:我送了一束花!",nickName]];
            }else {
                str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:我送了一辆跑车!",nickName]];
            }
            [str addAttribute:NSForegroundColorAttributeName value:kColorNickname range:NSMakeRange(0,nickName.length+1)];
            [str addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(nickName.length + 1, str.length - nickName.length - 1)];

        }else {
            
        }
        
        [str addAttribute:NSFontAttributeName value:kMessageFont range:NSMakeRange(0, str.length)];
        _messaheLable.attributedText = str;
    }
    
    
    CGSize size = _messaheLable.contentSize;
    CGRect frame = self.frame;
    fh(frame) = MAX(size.height, kNormalHeight);
    self.frame = frame;
    fx(frame) = 0; fy(frame) = 0;
    vf(_messaheLable) = frame;
}


- (void)fillCellWithObject:(id)object Width:(CGFloat)width
{
    self.object = object;
    self.width = width;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
