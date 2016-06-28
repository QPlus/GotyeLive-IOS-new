//
//  NavigationView.h
//  QMZB
//
//  Created by 刘淦 on 5/4/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NavigationView : UIView

@property (strong, nonatomic) IBOutlet UIButton *buttonFocus;
@property (strong, nonatomic) IBOutlet UIButton *buttonHot;
@property (strong, nonatomic) IBOutlet UIButton *buttonLatest;

@property (strong, nonatomic) IBOutlet UIButton *buttonSearch;
@property (strong, nonatomic) IBOutlet UIButton *buttonMessages;

@property (strong, nonatomic) IBOutlet UILabel *labelIndicator;
@property (strong, nonatomic) IBOutlet UIImageView *imageViewIndicator;

- (IBAction)onButtonClick:(id)sender;

@end
