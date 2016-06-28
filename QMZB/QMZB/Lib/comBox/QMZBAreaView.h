//
//  QMZBAreaView.h
//  QMZB
//
//  Created by Jim on 16/5/18.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QMZBLocationModel.h"

@class QMZBAreaView;

@protocol QMZBAreaPickerDelegate <NSObject>

@optional
- (void)pickerDidChaneStatus:(QMZBAreaView *)picker;
- (void)didClickButton;
@end

@interface QMZBAreaView : UIView<UIPickerViewDelegate, UIPickerViewDataSource>

@property (assign, nonatomic) id <QMZBAreaPickerDelegate> delegate;
@property (strong, nonatomic) IBOutlet UIPickerView *locatePicker;
@property (strong, nonatomic) QMZBLocationModel *locate;

- (id)initWithdelegate:(id <QMZBAreaPickerDelegate>)delegate;
- (void)showInView:(UIView *)view;
- (void)cancelPicker;

@end
