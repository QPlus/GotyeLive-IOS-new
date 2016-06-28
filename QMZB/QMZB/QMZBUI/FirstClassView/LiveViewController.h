//
//  LiveViewController.h
//  QMZB
//
//  Created by 刘淦 on 5/5/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LiveViewController : UIViewController<UIScrollViewDelegate>

@property (nonatomic, assign) BOOL isLiveMode;
@property (nonatomic, copy) NSString *roomId;
@property (nonatomic, assign) NSInteger itemTag;//标记是从哪个页面进入直播页面的
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *nickName;
@property (nonatomic, copy) NSString *playUrl;
@property (nonatomic, assign) id curItem;
@property (nonatomic, copy) NSArray *playlist;

@end
