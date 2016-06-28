//
//  QMZBChatView.h
//  QMZB
//
//  Created by Jim on 16/4/19.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QMZBChatView : UIViewController

@property (nonatomic, assign) BOOL isLiveMode;
@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, assign) NSInteger itemTag;//标记是从哪个页面进入直播页面的
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *playUrl;

@end
