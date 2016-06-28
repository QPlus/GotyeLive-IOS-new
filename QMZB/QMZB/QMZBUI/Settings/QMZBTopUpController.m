//
//  QMZBTopUpController.m
//  QMZB
//
//  Created by Jim on 16/5/4.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBTopUpController.h"
#import "QMZBUIUtil.h"
#import "QMZBUserInfo.h"
#import "QMZBNetwork.h"
#import "NSString+Extension.h"
#import "MBProgressHUD.h"
#import "UIView+Extension.h"
#import "QMZBTopUpCell.h"
#import "Order.h"
#import <AlipaySDK/AlipaySDK.h>
#import "DataSigner.h"

@interface QMZBTopUpController ()<UITableViewDataSource,UITableViewDelegate,MBProgressHUDDelegate>
{
    UITableView *_tableView;
    MBProgressHUD *HUD;
    UIButton *_alipayBtn;
    UIButton *_weixinBtn;
    NSInteger _payType;//0支付宝   1微信
    UILabel *_myPrice;
    UIImageView *_masonry;
}

@property(nonatomic ,strong) QMZBNetwork *requestClient;

@end

@implementation QMZBTopUpController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initNavigationBar];
    
    [self initView];
    
    [self getMyPayInfo];
}

// 初始化导航条
- (void)initNavigationBar
{
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.translucent =NO;
    self.title = @"我的余额";
    self.view.backgroundColor = BACKGROUND_DARK_COLOR;
    [self.navigationController.navigationBar setBarTintColor:COLOR(203, 133, 248, 1)];
    [self.navigationController.navigationBar setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                                      [UIColor whiteColor], NSForegroundColorAttributeName,
                                                                      [UIFont boldSystemFontOfSize:18.0f], NSFontAttributeName, nil]];
    
    // 导航条 左边 返回按钮
    UIBarButtonItem *backItem=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"ab_ic_back"] style:UIBarButtonItemStyleDone target:self action:@selector(btnClick:)];
    backItem.tintColor = WHITE_COLOR;
    backItem.tag = 1;
    [self.navigationItem setLeftBarButtonItem:backItem];
    
}

// 导航栏点击事件
- (void)btnClick:(UIButton *)sender
{
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:^(){}];
}

- (void)initView
{
    UIView *priceView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 80)];
    priceView.backgroundColor = BACKGROUND_COLOR;
    [self.view addSubview:priceView];
    
    UILabel *priceLab = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 80)];
    priceLab.text = @"账户余额";
    priceLab.font = [UIFont systemFontOfSize:16.0];
    priceLab.textColor = ORANGE_COLOR;
    [priceView addSubview:priceLab];
    
    _masonry = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"masonry"]];
    _masonry.frame = CGRectMake(ScreenWidth-125, 25, 25, 25);
    [priceView addSubview:_masonry];
    _myPrice = [[UILabel alloc] initWithFrame:CGRectMake(ScreenWidth-100, 0, 100, 80)];
    _myPrice.font = [UIFont systemFontOfSize:16.0];
    _myPrice.textColor = ORANGE_COLOR;
    _myPrice.textAlignment = NSTextAlignmentCenter;
    [_myPrice setText:@"0"];
    [priceView addSubview:_myPrice];
    
    
    UIView *payView = [[UIView alloc] initWithFrame:CGRectMake(0, priceView.height+10, ScreenWidth, 120)];
    payView.backgroundColor = BACKGROUND_COLOR;
    [self.view addSubview:payView];
    
    UILabel *payLab = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, ScreenWidth-20, 40)];
    payLab.text = @"请选择支付方式";
    payLab.font = [UIFont systemFontOfSize:12.0];
    payLab.textColor = TEXT_BLACK_COLOR;
    [payView addSubview:payLab];
    
    _alipayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _alipayBtn.frame = CGRectMake(20, 40, ScreenWidth/2-30, 60);
    _alipayBtn.layer.cornerRadius = 3;
    _alipayBtn.tag = 101;
    _alipayBtn.selected = YES;
    [_alipayBtn setBackgroundImage:[UIImage imageNamed:@"w-chat-hover"] forState:UIControlStateNormal];
//    [_alipayBtn setBackgroundImage:[UIImage imageNamed:@"w-chat-no"] forState:UIControlStateSelected];
    [_alipayBtn addTarget:self action:@selector(topUpButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [payView addSubview:_alipayBtn];
    
    _weixinBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _weixinBtn.frame = CGRectMake(ScreenWidth/2+10, 40, ScreenWidth/2-30, 60);
    _weixinBtn.layer.cornerRadius = 3;
    _weixinBtn.tag = 102;
    _weixinBtn.selected = NO;
    [_weixinBtn setBackgroundImage:[UIImage imageNamed:@"w-chatzf"] forState:UIControlStateNormal];
//    [_weixinBtn setBackgroundImage:[UIImage imageNamed:@"w-chatzf-hover"] forState:UIControlStateSelected];
    [_weixinBtn addTarget:self action:@selector(topUpButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [payView addSubview:_weixinBtn];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, payView.height+10+priceView.height+10 , ScreenWidth, 310) style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.backgroundColor = BACKGROUND_COLOR;
    _tableView.delegate = self;
    _tableView.scrollEnabled = NO;
    [self.view addSubview:_tableView];
    
}

- (void)topUpButtonClick:(UIButton *)button
{
    BOOL selected =  button.selected;
    if (button.tag == 101) {
        if (selected) {
            [_alipayBtn setBackgroundImage:[UIImage imageNamed:@"w-chat-no"] forState:UIControlStateNormal];
            _weixinBtn.selected = YES;
            _alipayBtn.selected = NO;
            [_weixinBtn setBackgroundImage:[UIImage imageNamed:@"w-chatzf-hover"] forState:UIControlStateNormal];
        }else {
            [_alipayBtn setBackgroundImage:[UIImage imageNamed:@"w-chat-hover"] forState:UIControlStateNormal];
            _weixinBtn.selected = NO;
            _alipayBtn.selected = YES;
            [_weixinBtn setBackgroundImage:[UIImage imageNamed:@"w-chatzf"] forState:UIControlStateNormal];
        }

    }else {
        if (!selected) {
            [_weixinBtn setBackgroundImage:[UIImage imageNamed:@"w-chatzf-hover"] forState:UIControlStateNormal];
            _alipayBtn.selected = NO;
            _weixinBtn.selected = YES;
            [_alipayBtn setBackgroundImage:[UIImage imageNamed:@"w-chat-no"] forState:UIControlStateNormal];
        }else {
            
            [_weixinBtn setBackgroundImage:[UIImage imageNamed:@"w-chatzf"] forState:UIControlStateNormal];
            _alipayBtn.selected = YES;
            _weixinBtn.selected = NO;
            [_alipayBtn setBackgroundImage:[UIImage imageNamed:@"w-chat-hover"] forState:UIControlStateNormal];
        }
    }
}

#pragma mark -   支付宝参数修改
//支付宝参数
- (void)aliPayParameter:(NSString *)price
{
    
    NSString *partner = @"2088121295043898";
    NSString *seller = @"2016050401362624";
    NSString *privateKey = @"MIICXQIBAAKBgQC+cSvWQRnQJLQYoZrxVhJgBPDlcTQIxojZ8OfEZybkhQqsUZp08KXYuBpQTuZrDu34ofyYf3H+7AdZUuU1GBnBFebsRITdBr1faZzPn/awvunroAbYOyksZ8M3cIWnfeJV9gKBGY58ov+sSO8uhLbawMtj07WVR7q3zcNoZazaeQIDAQABAoGAH9tonN+pBMOPCOvHsoVWb4+ECK2mKa2kaOi+rIEg5WtH/Mlt0BANfjJV3IdGTjRiJIxcZ9ox5JXxKMUQKJCOhg9OBk88vH3CregBBAo0zgIhuSEc3x4YnnlzaCxFOoh0MYBLxO5rvhWeRyK1n37WR16aoe+8OwP901MY70nnv7ECQQDj8LilZUsZqCREzvw8ib0QB+vcS4qwWuhPM3mtlrbrBl5cUaiw+owkqPlqk7XlhnyMR6iUdI6aCfUbngEdb9nFAkEA1eK8VlAfqB9liKHsoDxmSuwapU4PbbdYVwFsjaLpn1XQr4qROrk+MrgCW0rRIsFZ6UbXkEduHpMA7cd5wbvtJQJBAJ+Bo2SyVnR00jSId8BRTsk6EdYN0taINwq9ZceQsR4UTdHint6B5bH9wNPQ27frfZqYxqJkUin/D9OspPEZhVUCQAmUIOkgp3pJBawLzGQUsGQUlNDoYQqB1oP2/VyOejX3iuQBqaVenGl7EifyftE2pYcr9AVzHXxjCvybHVnOx70CQQDhCu74fhlh9t99/pPeweHyyVfjsN98hvAGSmlPyFweLf68bJz1Z29WTYLXiIAJyCoO/6gbCcuCcf4G0K0PyRLb";

    NSString *notifyUrl = [NSString stringWithFormat:@"http://gotyelive.gotlive.com.cn"];
    Order *order = [[Order alloc] init];
    order.partner = partner;
    order.sellerID = partner;
    order.outTradeNO = @"1000"; //订单ID（由商家自行制定）
    order.subject = @"亲加"; //商品标题
    order.body = @"亲加"; //商品描述
    order.totalFee = [NSString stringWithFormat:@"%@",price]; //商品价格
    order.notifyURL =  notifyUrl; //回调URL
    
    order.service = @"mobile.securitypay.pay";
    order.paymentType = @"1";
    order.inputCharset = @"utf-8";
    order.itBPay = @"30m";
    order.showURL = @"m.alipay.com";
    
    //应用注册scheme,在AlixPayDemo-Info.plist定义URL types
    NSString *appScheme = @"QMZB";
    
    //将商品信息拼接成字符串
    NSString *orderSpec = [order description];
    NSLog(@"orderSpec = %@",orderSpec);
    
    //获取私钥并将商户信息签名,外部商户可以根据情况存放私钥和签名,只需要遵循RSA签名规范,并将签名字符串base64编码和UrlEncode
    id<DataSigner> signer = CreateRSADataSigner(privateKey);
    NSString *signedString = [signer signString:orderSpec];
     NSLog(@"signedString = %@",signedString);
    //将签名成功字符串格式化为订单字符串,请严格按照该格式
    NSString *orderString = nil;
    if (signedString != nil) {
        orderString = [NSString stringWithFormat:@"%@&sign=\"%@\"&sign_type=\"%@\"",
                       orderSpec, signedString, @"RSA"];
        
        [[AlipaySDK defaultService] payOrder:orderString fromScheme:appScheme callback:^(NSDictionary *resultDic) {
            NSLog(@"reslut = %@",resultDic);
        }];
    }

}


#pragma mark UITableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // 一个组的item的数量
    return 5;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //每个单元格的视图
    static NSString *itemCell = @"cell_item";
    QMZBTopUpCell *cell = [tableView dequeueReusableCellWithIdentifier:itemCell];
    if (cell == nil) {
        cell = [[QMZBTopUpCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemCell];
    }
    cell.backgroundColor = BACKGROUND_COLOR;
    
    if (indexPath.row == 0) {
        cell.userName.text = @"10";
        cell.payName.text = @"¥1.00";
    }else if (indexPath.row == 1) {
        cell.userName.text = @"100";
        cell.payName.text = @"¥10.00";
    }else if (indexPath.row == 2) {
        cell.userName.text = @"1000";
        cell.payName.text = @"¥100.00";
    }else if (indexPath.row == 3){
        cell.userName.text = @"10000";
        cell.payName.text = @"¥1000.00";
    }else if (indexPath.row == 4){
        cell.userName.text = @"50000";
        cell.payName.text = @"¥5000.00";
    }else {
        
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 单元格被点击的监听
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    if (indexPath.row == 0) {
//        [self payRMB:1];
//    }else if (indexPath.row == 1) {
//        [self payRMB:10];
//    }else if (indexPath.row == 2) {
//        [self payRMB:100];
//    }else if (indexPath.row == 3){
//        [self payRMB:1000];
//    }else if (indexPath.row == 4){
//        [self payRMB:5000];
//    }else {
//        
//    }
    [self aliPayParameter:@"0.01"];
}

- (void)payRMB:(NSInteger)index
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:@(index) forKey:@"rmb"];

    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [self startRequest];
    [_requestClient postddByByUrlPath:@"/pay/ChargeRMB" andParams:parameters andCallBack:^(id back) {
        [HUD hide:YES];
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            return;
        }
        NSDictionary *dics = back;
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            [_myPrice setText:[NSString jsonUtils:[dics objectForKey:@"qinCoin"]]];
        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    [self payRMB:index];
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
    }];
}

- (void)getMyPayInfo
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [_requestClient postddByByUrlPath:@"/pay/GetPayAccount" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            return;
        }
        
        NSDictionary *dics = back;
        NSLog(@"---%@", dics);
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            [_myPrice setText:[NSString jsonUtils:[dics objectForKey:@"qinCoin"]]];

        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    [self getMyPayInfo];
                }
            }];
        }else {
            
        }
    }];
    
}


-(void) startRequest
{
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.labelText = @"正在加载...";
    HUD.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
