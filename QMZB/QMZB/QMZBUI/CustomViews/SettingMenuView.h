//
//  SettingMenuView.h
//  QMZB
//
//  Created by 刘淦 on 5/6/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kTagShare           0
#define kTagLamp            1
#define kTagSwitch          2
#define kTagOptimize        3

@interface SettingMenuView : UIView

@property (strong, nonatomic) IBOutlet UIButton *buttonShare;
@property (strong, nonatomic) IBOutlet UIButton *buttonLampSwitch;
@property (strong, nonatomic) IBOutlet UIButton *buttonCameraSwitch;
@property (strong, nonatomic) IBOutlet UIButton *buttonMagic;

@property (strong, nonatomic) IBOutlet UIButton *buttonLayer1;
@property (strong, nonatomic) IBOutlet UIButton *buttonLayer2;
@property (strong, nonatomic) IBOutlet UIButton *buttonLayer3;
@property (strong, nonatomic) IBOutlet UIButton *buttonLayer4;

@property (strong, nonatomic) IBOutlet UILabel *labelShare;
@property (strong, nonatomic) IBOutlet UILabel *labelLampSwitch;
@property (strong, nonatomic) IBOutlet UILabel *labelCameraSwitch;
@property (strong, nonatomic) IBOutlet UILabel *labelMagic;
@end
