//
//  GiftView.h
//  QMZB
//
//  Created by 刘淦 on 5/11/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GiftView : UIView

- (void)addNumView;

- (void)onGiftViewDisappear;

@property (strong, nonatomic) IBOutlet UILabel *labelAction;
@property (strong, nonatomic) IBOutlet UILabel *labelNickname;
@property (strong, nonatomic) IBOutlet UIButton *buttonAvatar;
@property (strong, nonatomic) IBOutlet UIImageView *imageViewGift;

@end
