//
//  MessageCell.h
//  QMZB
//
//  Created by Jim on 16/4/27.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kNormalHeight           (30)
#define kMessageFont            [UIFont systemFontOfSize:18.f]

@interface MessageCell : UITableViewCell

//@property (nonatomic, strong) UILabel * nameLabel;//

@property (nonatomic, strong) UITextView * messaheLable;//

- (void)fillCellWithObject:(id)object Width:(CGFloat)width;

@end
