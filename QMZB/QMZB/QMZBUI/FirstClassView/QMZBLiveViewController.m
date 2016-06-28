//
//  QMZBLiveViewController.m
//  QuanMingZhiBo
//
//  Created by Jim on 16/3/16.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBLiveViewController.h"
#import "QMZBUIUtil.h"
//#import "QMZBChatViewController.h"
#import "MBProgressHUD.h"
#import "GLCore.h"
//#import "GLChatManager.h"
#import "GLPublisher.h"
#import "QMZBSortGroup.h"
#import "QMZBSortItem.h"
#import "MBProgressHUD.h"
#import "QMZBLiveListModel.h"
#import "QMZBLiveCell.h"
#import "MJRefresh.h"    //刷新
#import "QMZBNetwork.h"
#import "NSString+Extension.h"
#import "QMZBUserInfo.h"
#import "QMZBSeacherLiveController.h"
#import "iCarousel.h"
#import "QMZBChatView.h"
#import <CoreLocation/CoreLocation.h>

#import "NavigationView.h"
#import "LiveViewController.h"

#define TYPE_TAB1 1
#define TYPE_TAB2 2
#define kTabHeight 64.f//#lg,40.f

@interface QMZBLiveViewController ()<UITableViewDataSource, UITableViewDelegate,MBProgressHUDDelegate,UIScrollViewDelegate,iCarouselDataSource,iCarouselDelegate, CLLocationManagerDelegate>
{
    GLAuthToken *_authToken;
    
    QMZBSortGroup *_tabGrop;
    
    NSMutableArray *_tabArrays;// 排序View集合
    
    NSInteger _type;
    
    BOOL _isLoading;
    
    MBProgressHUD *HUD;

    NSInteger _pageIndex;

    UIScrollView *_baseScrollView;
    
}

@property(nonatomic ,strong) UITableView *tableViewTAB1;

@property(nonatomic ,strong) UITableView *tableViewTAB2;

@property (strong, nonatomic) NavigationView *tabContentView;

@property (nonatomic, strong) NSMutableArray *dataArrays;

@property (nonatomic, strong) NSMutableArray *onlineList;

@property (nonatomic, strong) NSMutableArray *offlineList;

@property(nonatomic ,strong) QMZBNetwork *requestClient;

@property (nonatomic , strong) iCarousel *carousel;

@property(nonatomic,strong)CLLocationManager *locMgr;

@end

@implementation QMZBLiveViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initNavigationBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:NotificationloginSeccess object:nil];
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(updateSelected:) name:NotificationUpdateTab object:nil];

    [self startLocation];
}

- (void)initNavigationBar
{
    [[self navigationController] setNavigationBarHidden:YES/*#lg, NO, hide navigationBar*/ animated:NO];
//    self.navigationController.navigationBar.translucent =NO;
//    [self.navigationController.navigationBar setBarTintColor:COLOR(203, 133, 248, 1)];
    self.view.backgroundColor = BACKGROUND_COLOR;
    
//    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 35)];
//    UIButton *search = [UIButton buttonWithType:UIButtonTypeCustom];
//    search.frame = CGRectMake(ScreenWidth-50, 0, 35  , 35);
//    [search setImage:[UIImage imageNamed:@"ab_ic_search"] forState:UIControlStateNormal];
//    [search addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
//    search.tag = 1;
//    [headerView addSubview:search];
//    headerView.backgroundColor = [UIColor clearColor];
//    
//    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 0, ScreenWidth-100, 35)];
//    titleLabel.text = [NSString stringWithFormat:@"亲加直播"];
//    titleLabel.font = [UIFont systemFontOfSize:16];
//    titleLabel.backgroundColor = [UIColor clearColor];
//    titleLabel.textAlignment = NSTextAlignmentCenter;
//    titleLabel.textColor = WHITE_COLOR;
//    [headerView addSubview:titleLabel];
//    
//    self.tabBarController.navigationItem.titleView = headerView;
}

-(void) updateSelected:(NSNotification *)notification
{
    NSString *itemIndex = (NSString *)[notification object];
    
    if ([itemIndex isEqualToString:@"100"]) {
        [self initNavigationBar];
    }else {
        
    }
    
}

#pragma mark 点击事件
// 导航栏点击事件
- (void)btnClick:(UIButton *)sender
{
    QMZBSeacherLiveController *controller = [[QMZBSeacherLiveController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
    NSLog(@"=======");

}

- (void)buttonMessagesClick:(UIButton *)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"暂未开放此功能" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alert show];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self initNavigationBar];
    if (AppDelegateInstance.userInfo.sessionId.length > 0) {
        
        [self requestData:1];
    }else {
        
    }

}
- (void)notification:(NSNotification *)notification
{
    [self initView];
    [self initNavigationBar];
    [self requestData:1];
    [self.tableViewTAB1 headerBeginRefreshing];
    [self startLocation];
}

- (void)initView
{
    _baseScrollView =[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    _baseScrollView.delegate = self;
    _baseScrollView.showsHorizontalScrollIndicator = NO;
    _baseScrollView.showsVerticalScrollIndicator = NO;
    _baseScrollView.bounces = NO;
    [_baseScrollView setPagingEnabled:YES];
    _baseScrollView.backgroundColor = BACKGROUND_COLOR;
    //[self.view addSubview:_baseScrollView];//#lg, remove scrollview
    
    _tabContentView = [[NavigationView alloc] init];
    _tabContentView.backgroundColor = [UIColor colorWithRed:203/255.f green:133/255.f blue:248/255.f alpha:1.f];

    //[_baseScrollView addSubview:_tabContentView];//#lg, added to self.view
    [self.view addSubview: _tabContentView];
    
    [_tabContentView.buttonHot addTarget:self action:@selector(itemClick:) forControlEvents:UIControlEventTouchUpInside];
    [_tabContentView.buttonFocus addTarget:self action:@selector(itemClick:) forControlEvents:UIControlEventTouchUpInside];
    [_tabContentView.buttonSearch addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_tabContentView.buttonMessages addTarget:self action:@selector(buttonMessagesClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _type = TYPE_TAB1;
    
#if 0
    _tabArrays = [[NSMutableArray alloc] init];
    
    NSArray *sortArrays = [NSArray arrayWithObjects:@"全部", @"关注", nil];
    
    for (int i = 0; i < sortArrays.count; i++) {
        
        QMZBSortItem *sortView;
        sortView = [[QMZBSortItem alloc] initWithFrame:CGRectMake(ScreenWidth/sortArrays.count * (i), 0, ScreenWidth/sortArrays.count, kTabHeight) andName:sortArrays[i] sortImage:@"sort_asc" state:SortNone];
        
        if (i == 0) {
            sortView.nameLabel.textColor = COLOR(25, 151, 220, 1); // 初始状态
        }
        
        UILabel *linelabel = [[UILabel alloc] init];
        linelabel.backgroundColor = [UIColor lightGrayColor];
        if(i != 1)
        {
            linelabel.frame = CGRectMake(ScreenWidth/sortArrays.count * (i+1), 11, 0.2, kTabHeight-22);
        }
        
        [sortView setTag:i];
        [sortView addTarget:self action:@selector(itemClick:) forControlEvents:UIControlEventTouchUpInside];
        
        [_tabArrays addObject:sortView];
        [_tabContentView addSubview:sortView];
        [_tabContentView addSubview:linelabel];
    }
    
    
    _tabGrop = [[QMZBSortGroup alloc] initWithFrame:CGRectMake(0, kTabHeight - 3.0, ScreenWidth, 3) sortArrays:_tabArrays defaultPosition:0];
    [_tabContentView addSubview:_tabGrop];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, kTabHeight - 0.5f, ScreenWidth, 1.f)];
    line.backgroundColor = DIVIDE_LINE_COLOR;
    [_tabContentView addSubview:line];
#endif
    
    CGRect frame = CGRectMake(0, kTabHeight, kScreenWidth, kScreenHeight - 64 - 49);
    _carousel = [[iCarousel alloc] initWithFrame: frame];
    _carousel.backgroundColor = BACKGROUND_DARK_COLOR;
    _carousel.dataSource = self;
    _carousel.delegate = self;
    _carousel.decelerationRate = 0.7;
    _carousel.type = iCarouselTypeLinear;
    _carousel.pagingEnabled = YES;
    _carousel.edgeRecognition = YES;
    _carousel.bounceDistance = 0.4;
    _carousel.bounces = NO;
    [self.view addSubview:_carousel];
    
    [_carousel setCurrentItemIndex: 1];
    [_carousel scrollToItemAtIndex:1 animated:NO];
    
//    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kTabHeight , ScreenWidth, ScreenHeight - 64 - kTabHeight-49) style:UITableViewStylePlain];
//    _tableView.dataSource = self;
//    _tableView.backgroundColor = BACKGROUND_DARK_COLOR;
//    _tableView.delegate = self;
//    
//    // 1.下拉刷新(进入刷新状态就会调用self的headerRereshing)
//    [self.tableView addHeaderWithTarget:self action:@selector(headerRereshing)];
//    // 自动刷新(一进入程序就下拉刷新)
////    [self.tableView headerBeginRefreshing];
//    // 2.上拉加载更多(进入刷新状态就会调用self的footerRereshing)
//    [self.tableView addFooterWithTarget:self action:@selector(footerRereshing)];
//    _tableView.separatorStyle = UITableViewCellSelectionStyleNone;
//    [_baseScrollView addSubview:_tableView];
    
    _dataArrays = [NSMutableArray array];
    _onlineList = [NSMutableArray array];
    _offlineList = [NSMutableArray array];

    
}


- (IBAction)itemClick:(id)sender
{
    
    if (_isLoading) {
        return;
    }
    
    switch ([sender tag]) {
        case 1:
        {
            if (_type == TYPE_TAB1) {
                return;
            }
            _type = TYPE_TAB1;
            [_carousel scrollToItemAtIndex:1 animated:YES];
        }
            break;
        case 0:
        {
            if (_type == TYPE_TAB2) {
                return;
            }
            _type = TYPE_TAB2;
            [_carousel scrollToItemAtIndex:0 animated:YES];
        }
            break;
        default:
            break;
    }
    
//    for (QMZBSortItem *sortView in _tabArrays) {
//        sortView.nameLabel.textColor = TEXT_BLACK_COLOR;
//    }
//    sender.nameLabel.textColor = COLOR(25, 151, 220, 1);
    
    _pageIndex = 1;
    [self requestData:_pageIndex];
}

- (void)setItemClick:(NSInteger)index
{
    switch (index) {
        case 1:
        {
            if (_type == TYPE_TAB1) {
                return;
            }
            _type = TYPE_TAB1;
        }
            break;
        case 0:
        {
            if (_type == TYPE_TAB2) {
                return;
            }
            _type = TYPE_TAB2;
        }
            break;
        default:
            break;
    }
    
    _pageIndex = 1;
    [self requestData:_pageIndex];
    UIButton *btn = [[UIButton alloc] init];
    btn.tag = index;
    [_tabContentView onButtonClick: btn];
}

- (void) requestData:(NSInteger) pageindex
{
    if (_isLoading) {
        return;
    }
   
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    NSLog(@"请求%@列表中", _type==1?@"全部":@"关注");
    [parameters setObject:@(_type) forKey:@"type"];
    [parameters setObject:@(pageindex) forKey:@"refresh"];
    [parameters setObject:@(10) forKey:@"count"];
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [_requestClient postddByByUrlPath:@"/live/GetLiveRoomList" andParams:parameters andCallBack:^(id back) {
        [self hiddenRefreshView];
        if ([back isKindOfClass:[NSString class]]) {
           
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [HUD hide:YES];
            return ;
        }else {
            NSDictionary *dics = back;
            NSLog(@"%@",dics);
            int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
            if (result_type  == 10000) {
                [HUD hide:YES];
                if (pageindex == 1) {
                    [_dataArrays removeAllObjects];
                    [_onlineList removeAllObjects];
                    [_offlineList removeAllObjects];
                }
                if (_type == 1) {
                    
                    if ([[dics objectForKey:@"list"] isKindOfClass:[NSNull class]]) {
                        
                    }else {
                        
                        NSArray *array = [NSArray array];
                        array = [dics objectForKey:@"list"];
                        for (NSDictionary *dictionary in array) {
                            QMZBLiveListModel *model = [[QMZBLiveListModel alloc] init];
                            model.followCount = [NSString jsonUtils:[dictionary objectForKey:@"followCount"]];
                            model.anchorIcon = [dictionary objectForKey:@"headPicId"];
                            model.anchorName = [dictionary objectForKey:@"anchorName"];
                            model.liveRoomTopic = [dictionary objectForKey:@"liveRoomTopic"];
                            model.liveRoomDesc = [dictionary objectForKey:@"liveRoomDesc"];
                            model.liveRoomName = [dictionary objectForKey:@"liveRoomName"];
                            model.liveRoomUserPwd = [dictionary objectForKey:@"liveRoomUserPwd"];
                            model.liveRoomanchorPwd = [dictionary objectForKey:@"liveRoomAnchorPwd"];
                            model.liveRoomId = [dictionary objectForKey:@"liveRoomId"];
                            model.isFollow = [NSString jsonUtils:[dictionary objectForKey:@"isFollow"]];
                            model.playerCount = [NSString jsonUtils:[dictionary objectForKey:@"playerCount"]];
                            model.playRtmpUrl = [NSString jsonUtils:[dictionary objectForKey:@"playRtmpUrl"]];
                            model.playHlsUrl = [NSString jsonUtils:[dictionary objectForKey:@"playHlsUrl"]];
                            model.playFlvUrl = [NSString jsonUtils:[dictionary objectForKey:@"playFlvUrl"]];

                            [_dataArrays addObject:model];
                        }
                    }
                    [_tableViewTAB1 reloadData];
                }else {
                    
                    if ([[dics objectForKey:@"onlineList"] isKindOfClass:[NSNull class]]) {
                        
                    }else {
                        
                        NSArray *onlineArray = [NSArray array];
                        onlineArray = [dics objectForKey:@"onlineList"];
                        for (NSDictionary *dictionary in onlineArray) {
                            QMZBLiveListModel *model = [[QMZBLiveListModel alloc] init];
                            model.followCount = [NSString jsonUtils:[dictionary objectForKey:@"followCount"]];
                            model.anchorIcon = [dictionary objectForKey:@"headPicId"];
                            model.anchorName = [dictionary objectForKey:@"anchorName"];
                            model.liveRoomTopic = [dictionary objectForKey:@"liveRoomTopic"];
                            model.liveRoomDesc = [dictionary objectForKey:@"liveRoomDesc"];
                            model.liveRoomName = [dictionary objectForKey:@"liveRoomName"];
                            model.liveRoomUserPwd = [dictionary objectForKey:@"liveRoomUserPwd"];
                            model.liveRoomanchorPwd = [dictionary objectForKey:@"liveRoomAnchorPwd"];
                            model.liveRoomId = [dictionary objectForKey:@"liveRoomId"];
                            model.isFollow = [NSString jsonUtils:[dictionary objectForKey:@"isFollow"]];
                            model.playerCount = [NSString jsonUtils:[dictionary objectForKey:@"playerCount"]];
                            model.playRtmpUrl = [NSString jsonUtils:[dictionary objectForKey:@"playRtmpUrl"]];
                            model.playHlsUrl = [NSString jsonUtils:[dictionary objectForKey:@"playHlsUrl"]];
                            model.playFlvUrl = [NSString jsonUtils:[dictionary objectForKey:@"playFlvUrl"]];
                            [_onlineList addObject:model];
                        }
                    }
                    if ([[dics objectForKey:@"offlineList"] isKindOfClass:[NSNull class]]) {
                        
                    }else {
                        
                        NSArray *offLineArray = [NSArray array];
                        offLineArray = [dics objectForKey:@"offlineList"];
                        for (NSDictionary *dictionary in offLineArray) {
                            QMZBLiveListModel *model = [[QMZBLiveListModel alloc] init];
                            model.followCount = [NSString jsonUtils:[dictionary objectForKey:@"followCount"]];
                            model.anchorIcon = [NSString jsonUtils:[dictionary objectForKey:@"headPicId"]];
                            model.anchorName = [NSString jsonUtils:[dictionary objectForKey:@"anchorName"]];
                            model.liveRoomTopic = [NSString jsonUtils:[dictionary objectForKey:@"liveRoomTopic"]];
                            model.liveRoomDesc = [NSString jsonUtils:[dictionary objectForKey:@"liveRoomDesc"]];
                            model.liveRoomName = [NSString jsonUtils:[dictionary objectForKey:@"liveRoomName"]];
                            model.liveRoomUserPwd = [NSString jsonUtils:[dictionary objectForKey:@"liveRoomUserPwd"]];
                            model.liveRoomanchorPwd = [NSString jsonUtils:[dictionary objectForKey:@"liveRoomAnchorPwd"]];
                            model.liveRoomId = [NSString jsonUtils:[dictionary objectForKey:@"liveRoomId"]];
                            model.isFollow = [NSString jsonUtils:[dictionary objectForKey:@"isFollow"]];
                            model.playerCount = [NSString jsonUtils:[dictionary objectForKey:@"playerCount"]];
                            model.playRtmpUrl = [NSString jsonUtils:[dictionary objectForKey:@"playRtmpUrl"]];
                            model.playHlsUrl = [NSString jsonUtils:[dictionary objectForKey:@"playHlsUrl"]];
                            model.playFlvUrl = [NSString jsonUtils:[dictionary objectForKey:@"playFlvUrl"]];
                            [_offlineList addObject:model];
                        }
                    }
                    
                    [_tableViewTAB2 reloadData];
                }
            }else if (result_type  == 10003) {
                AppDelegateInstance.userInfo.isLogin = NO;
                [_requestClient reLogin_andCallBack:^(BOOL back) {
                    if (back) {
                        
                        _isLoading  = NO;
                        [self requestData:1];
                    }
                }];
                
            }else {
                // 错误返回码
                NSString *msg = [dics objectForKey:@"desc"];
                NSLog(@"未返回正确的数据：%@", msg);
                HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hud_error"]];
                HUD.mode = MBProgressHUDModeCustomView;
                [HUD hide:YES afterDelay:2]; // 延时2s消失
                HUD.labelText = msg;
            }
        }
        _isLoading  = NO;
    }];

}


- (void) followLiveRoom:(NSInteger) liveRoomId :(NSInteger) isFollow
{
    if (_isLoading) {
        return;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:@(liveRoomId) forKey:@"liveRoomId"];
    [parameters setObject:@(isFollow) forKey:@"isFollow"];
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [_requestClient postddByByUrlPath:@"/live/FollowLiveRoom" andParams:parameters andCallBack:^(id back) {
        [self hiddenRefreshView];
        if ([back isKindOfClass:[NSString class]]) {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [HUD hide:YES];
            return ;
        }else {
            NSDictionary *dics = back;
            NSLog(@"%@",dics);
            int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
            if (result_type  == 10000) {
                [HUD hide:YES];
                
            }else if (result_type  == 10003) {
                AppDelegateInstance.userInfo.isLogin = NO;
                [_requestClient reLogin_andCallBack:^(BOOL back) {
                    if (back) {
                        
                        _isLoading  = NO;
                       [self followLiveRoom: liveRoomId : isFollow];
                    }
                }];
                
            }else {
                // 错误返回码
                NSString *msg = [dics objectForKey:@"desc"];
                NSLog(@"未返回正确的数据：%@", msg);
                HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hud_error"]];
                HUD.mode = MBProgressHUDModeCustomView;
                [HUD hide:YES afterDelay:2]; // 延时2s消失
                HUD.labelText = msg;
            }
        }
        _isLoading  = NO;
    }];
    
}


- (void)hud:(MBProgressHUD *)hud showError:(NSString *)error
{
    hud.detailsLabelText = error;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:1];
}


#pragma mark UITableViewDelegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // 分组的数量
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // 一个组的item的数量
    if (_type == TYPE_TAB1) {
        
        return _dataArrays.count;
    }
    return (_onlineList.count + _offlineList.count);

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kScreenWidth + kHeightOffsetLiveRoomCell;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //每个单元格的视图
    static NSString *itemCell = @"cell_item";
    QMZBLiveCell *cell = [tableView dequeueReusableCellWithIdentifier:itemCell];
    if (cell == nil) {
        cell = [[QMZBLiveCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemCell];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = BACKGROUND_COLOR;
    
    if (_type == TYPE_TAB1) {
        
        QMZBLiveListModel *obj = [[QMZBLiveListModel alloc]init];
        obj = _dataArrays[indexPath.row];
        cell.liveRoomTopic.text = [NSString stringWithFormat:@"直播中"];
        [cell fillCellWithObject:obj];
    }else {
        if (_onlineList.count == 0) {
            QMZBLiveListModel *obj = [[QMZBLiveListModel alloc]init];
            obj = _offlineList[indexPath.row];
            cell.liveRoomTopic.text = [NSString stringWithFormat:@"已结束"];
            [cell fillCellWithObject:obj];
        }else {
            
            if (indexPath.row < _onlineList.count) {
                QMZBLiveListModel *obj = [[QMZBLiveListModel alloc]init];
                obj = _onlineList[indexPath.row];
                cell.liveRoomTopic.text = [NSString stringWithFormat:@"直播中"];
                [cell fillCellWithObject:obj];
            }else {
                QMZBLiveListModel *obj = [[QMZBLiveListModel alloc]init];
                obj = _offlineList[indexPath.row - _onlineList.count];
                cell.liveRoomTopic.text = [NSString stringWithFormat:@"已结束"];
                [cell fillCellWithObject:obj];
            }
        }
    }
    __block QMZBLiveCell *blockCell = cell;
    cell.didSelectedButton = ^(UIButton *button){
        QMZBLiveListModel *model = [[QMZBLiveListModel alloc]init];
        if (_type == TYPE_TAB1) {
            
            model = _dataArrays[indexPath.row];
            if ([model.isFollow integerValue] == 0) {
                
                [self followLiveRoom:[model.liveRoomId integerValue] :1];
                model.isFollow = @"1";
                [blockCell.followButton setImage:[UIImage imageNamed:@"icon_follow_yes"] forState:UIControlStateNormal];
            }else {
                [self followLiveRoom:[model.liveRoomId integerValue] :0];
                model.isFollow = @"0";
                [blockCell.followButton setImage:[UIImage imageNamed:@"icon_follow_no"] forState:UIControlStateNormal];
            }
            [_dataArrays removeObjectAtIndex:indexPath.row];
            [_dataArrays insertObject:model atIndex:indexPath.row];
            [_tableViewTAB1 reloadData];
        }else {
            if (_onlineList.count == 0) {
                model = _offlineList[indexPath.row - _onlineList.count];
                
                [self followLiveRoom:[model.liveRoomId integerValue] :0];
                
                [_offlineList removeObjectAtIndex:(indexPath.row - _onlineList.count)];
            }else {
                
                if (indexPath.row < _onlineList.count) {
                    model = _onlineList[indexPath.row];
                    
                    [self followLiveRoom:[model.liveRoomId integerValue] :0];
                    
                    [_onlineList removeObjectAtIndex:indexPath.row];
                }else {
                    model = _offlineList[indexPath.row - _onlineList.count];
                    
                    [self followLiveRoom:[model.liveRoomId integerValue] :0];
                    
                    [_offlineList removeObjectAtIndex:(indexPath.row - _onlineList.count)];
                }
            }
            [_tableViewTAB2 reloadData];
        }
    };
        
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *list = nil;
    // 单元格被点击的监听
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    QMZBLiveListModel *obj = [[QMZBLiveListModel alloc]init];
    
    if (_type == TYPE_TAB1) {
        
        list = _dataArrays;
        obj = _dataArrays[indexPath.row];
    }else {
        if (_onlineList.count == 0) {
            list = _offlineList;
            obj = _offlineList[indexPath.row-_onlineList.count];
            NSString *message = [NSString stringWithFormat:@"%@没有在直播",obj.anchorName];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }else {
            
            if (indexPath.row < _onlineList.count) {
                list = _onlineList;
                obj = _onlineList[indexPath.row];
            }else {
                list = _offlineList;
                obj = _offlineList[indexPath.row-_onlineList.count];
                NSString *message = [NSString stringWithFormat:@"%@没有在直播",obj.anchorName];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
                return;
            }
        }
    }
    
#if 0
    QMZBChatView *chat = [[QMZBChatView alloc] init];
    chat.isLiveMode = 0;
    chat.roomId = obj.liveRoomId;
    chat.password = obj.liveRoomUserPwd;
    chat.nickName = AppDelegateInstance.userInfo.nickName;
    chat.playUrl = obj.playFlvUrl;
#else
    LiveViewController *chat = [[LiveViewController alloc] init];
    
    chat.isLiveMode = 0;
    chat.roomId = obj.liveRoomId;
    chat.password = obj.liveRoomUserPwd;
    chat.nickName = AppDelegateInstance.userInfo.nickName;
    chat.playUrl = obj.playFlvUrl;
    chat.curItem = obj;
    chat.playlist = list;
#endif
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self presentViewController:chat animated:NO completion:nil];
}

#pragma mark 开始进入刷新状态
- (void)headerRereshing
{
    _pageIndex = 1;
    [self requestData:_pageIndex];
    
}

- (void)footerRereshing
{
    _pageIndex = 0;
    [self requestData:_pageIndex];
}



// 隐藏刷新视图
-(void) hiddenRefreshView
{
    if (!self.tableViewTAB1.isHeaderHidden) {
        [self.tableViewTAB1 headerEndRefreshing];
    }
    
    if (!self.tableViewTAB1.isFooterHidden) {
        [self.tableViewTAB1 footerEndRefreshing];
    }
    if (!self.tableViewTAB2.isHeaderHidden) {
        [self.tableViewTAB2 headerEndRefreshing];
    }
    
    if (!self.tableViewTAB2.isFooterHidden) {
        [self.tableViewTAB2 footerEndRefreshing];
    }
}

#pragma mark iCarouselDelegate
- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return 2;
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
  
    if (index == 1)
    {
        view = [[UIView alloc] initWithFrame:carousel.bounds];
        _tableViewTAB1 = [[UITableView alloc] initWithFrame:view.bounds style:UITableViewStylePlain];
        _tableViewTAB1.dataSource = self;
        _tableViewTAB1.backgroundColor = BACKGROUND_DARK_COLOR;
        _tableViewTAB1.delegate = self;
        
        _tableViewTAB1.rowHeight = kScreenWidth + kHeightOffsetLiveRoomCell;
        // 1.下拉刷新(进入刷新状态就会调用self的headerRereshing)
        [self.tableViewTAB1 addHeaderWithTarget:self action:@selector(headerRereshing)];
        [self.tableViewTAB1 addFooterWithTarget:self action:@selector(footerRereshing)];
        _tableViewTAB1.separatorStyle = UITableViewCellSelectionStyleNone;
        [view addSubview:_tableViewTAB1];
    }else {
        view = [[UIView alloc] initWithFrame:carousel.bounds];
        _tableViewTAB2 = [[UITableView alloc] initWithFrame:view.bounds style:UITableViewStylePlain];
        _tableViewTAB2.dataSource = self;
        _tableViewTAB2.backgroundColor = BACKGROUND_DARK_COLOR;
        _tableViewTAB2.delegate = self;
        
        _tableViewTAB2.rowHeight = kScreenWidth + kHeightOffsetLiveRoomCell;
        // 1.下拉刷新(进入刷新状态就会调用self的headerRereshing)
        [self.tableViewTAB2 addHeaderWithTarget:self action:@selector(headerRereshing)];
        [self.tableViewTAB2 addFooterWithTarget:self action:@selector(footerRereshing)];
        _tableViewTAB2.separatorStyle = UITableViewCellSelectionStyleNone;
        [view addSubview:_tableViewTAB2];
    }
    
    
    return view;
}

- (void)carouselDidScroll:(iCarousel *)carousel
{
    if (_type-1==carousel.currentItemIndex) {
        [self setItemClick:carousel.currentItemIndex];
    }else {
        
    }
}

- (void)carousel:(iCarousel *)carousel didSelectItemAtIndex:(NSInteger)index
{
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel
{
}

- (void)carouselDidEndDecelerating:(iCarousel *)carousel
{
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



#pragma mark开始定位
-(void)startLocation
{
    if (_locMgr == nil) {
        
        self.locMgr = [[CLLocationManager alloc] init];
        self.locMgr.delegate = self;
        self.locMgr.desiredAccuracy = kCLLocationAccuracyBest;
        self.locMgr.distanceFilter = 10.0f;
        if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 8.0) {
            [self.locMgr requestAlwaysAuthorization];
        } else {
        }
    }
    [self.locMgr startUpdatingLocation];
    if ([CLLocationManager locationServicesEnabled]) {
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"无法进行定位" message:@"请检查您的设备是否开启定位功能" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}
//定位代理经纬度回调
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    [_locMgr stopUpdatingLocation];
    CLLocation *loc = [locations firstObject];
    CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
    [geoCoder reverseGeocodeLocation:loc completionHandler:^(NSArray *placemarks, NSError *error) {
        
        for (CLPlacemark * placemark in placemarks) {
            NSDictionary *test = [placemark addressDictionary];
            //  Country(国家)  State(城市)  SubLocality(区)   Name(地址)
            NSString *address = [NSString stringWithFormat:@"%@%@",[NSString jsonUtils:[test objectForKey:@"State"]],[NSString jsonUtils:[test objectForKey:@"SubLocality"]]];
            AppDelegateInstance.userInfo.userAddress = address;
        }
        if (AppDelegateInstance.userInfo.userAddress) {
            [self requestModifyUserInfo];
        }
    }];

}

- (void)requestModifyUserInfo
{
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:AppDelegateInstance.userInfo.userAddress forKey:@"address"];
    
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [_requestClient postddByByUrlPath:@"/live/ModifyUserInfo" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            return;
        }
        NSDictionary *dics = back;
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            
            NSLog(@"%@", dics);

        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    [self requestModifyUserInfo];
                }
            }];
            
        }else {
            // 错误返回码
            NSString *msg = [dics objectForKey:@"desc"];
            NSLog(@"未返回正确的数据：%@", msg);
            HUD.mode = MBProgressHUDModeIndeterminate;
            [HUD hide:YES afterDelay:2]; // 延时2s消失
            HUD.labelText = msg;
        }
    }];
    
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}


@end
