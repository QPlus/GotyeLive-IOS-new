//
//  QMZBRegisteredUserController.m
//  QMZB
//
//  Created by Jim on 16/3/22.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBRegisteredUserController.h"
#import "QMZBUIUtil.h"
#import "QMZBNetwork.h"
#import "MBProgressHUD.h"
#import "NSString+Extension.h"
#import "QMZBUserInfo.h"
#import "QMZBLoginTextField.h"

@interface QMZBRegisteredUserController ()<MBProgressHUDDelegate,UITextFieldDelegate>
{
    BOOL _isLoading;
    MBProgressHUD *HUD;
    
    UIButton *_getPhonrCodeBut;
}

@property(nonatomic ,strong) QMZBNetwork *requestClient;

//@property (nonatomic, strong) QMZBLoginTextField *userName;

@property (nonatomic, strong) QMZBLoginTextField *password;

@property (nonatomic, strong) QMZBLoginTextField *userphone;

@property (nonatomic, strong) QMZBLoginTextField *usermail;

@end

@implementation QMZBRegisteredUserController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initNavigationBar];
}

// 初始化导航条
- (void)initNavigationBar
{
    [[self navigationController] setNavigationBarHidden:YES animated:YES];

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(10, 20, 40, 40);
    backBtn.layer.cornerRadius = 3;
    backBtn.backgroundColor = [UIColor clearColor];
    [backBtn setImage:[UIImage imageNamed:@"ab_ic_back"] forState:UIControlStateNormal];
    [self.view addSubview:backBtn];
    [backBtn addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *userLogin = [[UILabel alloc] initWithFrame:CGRectMake(ScreenWidth/3, 90, ScreenWidth/3, 40)];
    userLogin.text = @"用户注册";
    userLogin.font = [UIFont boldSystemFontOfSize:18.0f];
    userLogin.textAlignment = NSTextAlignmentCenter;
    userLogin.textColor = WHITE_COLOR;
    [self.view addSubview:userLogin];
    
    _userphone = [[QMZBLoginTextField alloc] initWithFrame:CGRectMake(36, 140,  ScreenWidth- 36*2, 45)];
    [_userphone textWithleftImage:@"login_ic_userphone" placeName:@"请输入手机号码"];
    _userphone.keyboardType = UIKeyboardTypePhonePad;
    
    _password = [[QMZBLoginTextField alloc] initWithFrame:CGRectMake(36, CGRectGetMaxY(_userphone.frame) + 20, ScreenWidth - 36*2, 45)];
    _password.secureTextEntry = YES;
    [_password textWithleftImage:@"login_ic_password" placeName:@"请输入密码"];
    
    [self.view addSubview:_userphone];
    [self.view addSubview:_password];
    
    _usermail = [[QMZBLoginTextField alloc] initWithFrame:CGRectMake(36, CGRectGetMaxY(_password.frame) + 20,  ScreenWidth- 36*2-80, 45)];
    [_usermail textWithleftImage:@"login_ic_usermail" placeName:@"请输入验证码"];
    _usermail.keyboardType = UIKeyboardTypePhonePad;

    
    [self.view addSubview:_usermail];
    
    
    
    _password.layer.cornerRadius = 5.0f;
    _password.secureTextEntry = YES;

    _userphone.layer.cornerRadius = 5.0f;
    _userphone.delegate = self;
    
    _usermail.layer.cornerRadius = 5.0f;
    _usermail.delegate = self;
    
    _getPhonrCodeBut = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth-36-100+30, CGRectGetMaxY(_password.frame) + 20, 70, 45)];
    _getPhonrCodeBut.layer.masksToBounds = NO;
    [_getPhonrCodeBut setAdjustsImageWhenHighlighted:NO];
    _getPhonrCodeBut.backgroundColor = COLOR(214, 214, 214, 0.3);
    _getPhonrCodeBut.layer.borderColor = [[UIColor clearColor] CGColor];
    _getPhonrCodeBut.layer.cornerRadius = 5.0f;
    _getPhonrCodeBut.titleLabel.font = [UIFont boldSystemFontOfSize:16.f];
    [_getPhonrCodeBut setTitleColor:WHITE_COLOR forState:UIControlStateNormal];
    [_getPhonrCodeBut setTitle:@"验证" forState:UIControlStateNormal];
    [_getPhonrCodeBut addTarget:self action:@selector(getPhoneCode:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_getPhonrCodeBut];
    
    UIButton *registbutton = [[UIButton alloc] initWithFrame:CGRectMake(36, CGRectGetMaxY(_getPhonrCodeBut  .frame) + 20, ScreenWidth - 36*2, 45)];
    registbutton.layer.masksToBounds = NO;
    [registbutton setAdjustsImageWhenHighlighted:NO];
    registbutton.backgroundColor = COLOR(214, 214, 214, 0.3);
    registbutton.layer.borderColor = [[UIColor clearColor] CGColor];
    registbutton.layer.cornerRadius = 5.0f;
    registbutton.titleLabel.font = [UIFont boldSystemFontOfSize:16.f];
    [registbutton setTitleColor:WHITE_COLOR forState:UIControlStateNormal];
    [registbutton setTitle:@"注册" forState:UIControlStateNormal];
    [registbutton addTarget:self action:@selector(clickRegister:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:registbutton];
    
    UILabel *userhasAccount = [[UILabel alloc] initWithFrame:CGRectMake(ScreenWidth/3, CGRectGetMaxY(registbutton.frame) + 10, 80, 40)];
    userhasAccount.text = @"已有账号?";
    userhasAccount.font = [UIFont boldSystemFontOfSize:14.0f];
    userhasAccount.textColor = WHITE_COLOR;
    [self.view addSubview:userhasAccount];
    
    UIButton *getBackbutton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth/3+80, CGRectGetMaxY(registbutton.frame) + 10, 100, 40)];
    getBackbutton.layer.masksToBounds = NO;
    [getBackbutton setAdjustsImageWhenHighlighted:NO];
    getBackbutton.backgroundColor = [UIColor clearColor];
    getBackbutton.layer.borderColor = [[UIColor clearColor] CGColor];
    getBackbutton.titleLabel.font = [UIFont boldSystemFontOfSize:14.f];
    [getBackbutton setTitleColor:BLUE_COLOR forState:UIControlStateNormal];
    [getBackbutton setTitle:@"点击登录" forState:UIControlStateNormal];
    getBackbutton.tag = 301;
    getBackbutton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [getBackbutton addTarget:self action:@selector(btnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:getBackbutton];
    
    //点击空白处收回键盘
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyboardHide:)];
    //设置成NO表示当前控件响应后会传播到其他控件上，默认为YES。
    tapGestureRecognizer.cancelsTouchesInView = NO;
    //将触摸事件添加到当前view
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

#pragma mark 点击空白处收回键盘
-(void)keyboardHide:(UITapGestureRecognizer*)tap
{
    [_userphone resignFirstResponder];
    [_password resignFirstResponder];
    [_usermail resignFirstResponder];
}

// 导航栏点击事件
- (void)btnClick:(UIButton *)sender
{
//    [self.navigationController popViewControllerAnimated:YES];
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:^(){}];
}

#pragma mark - TextField Delegate
//开始编辑输入框的时候，软键盘出现，执行此事件
-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    CGRect frame = textField.frame;
    int offset = frame.origin.y + 72 - (self.view.frame.size.height - 216.0);//键盘高度216
    
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    
    //将视图的Y坐标向上移动offset个单位，以使下面腾出地方用于软键盘的显示
    if(offset > 0)
        self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
    
    [UIView commitAnimations];
}

//输入框编辑完成以后，将视图恢复到原始状态
-(void)textFieldDidEndEditing:(UITextField *)textField
{
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame =CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    }];
    
}

- (void)getPhoneCode:(id)sender
{

    if (_userphone.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入手机号码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:_userphone.text forKey:@"phone"];
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [self startRequest];
    [_requestClient postddByByUrlPath:@"/live/AuthCode" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [HUD hide:YES];
            return;
        }
        NSDictionary *dics = back;
        NSLog(@"%@", dics);
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            [HUD hide:YES];

            [self verificationTimer];
        }else {
            // 错误返回码
            NSString *msg = [dics objectForKey:@"desc"];
            NSLog(@"未返回正确的数据：%@", msg);
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hud_error"]];
            HUD.mode = MBProgressHUDModeCustomView;
            [HUD hide:YES afterDelay:2]; // 延时2s消失
            HUD.labelText = msg;
        }
        _isLoading  = NO;
    }];
    
}

- (void)clickRegister:(id)sender
{

    if (_userphone.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入手机号码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    if (_usermail.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入验证码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    if (_password.text.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入密码" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//    [parameters setObject:_userName.text forKey:@"account"];
    [parameters setObject:_password.text forKey:@"password"];
    [parameters setObject:_usermail.text forKey:@"authCode"];
    [parameters setObject:_userphone.text forKey:@"phone"];
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [self startRequest];
    [_requestClient postddByByUrlPath:@"/live/Register" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [HUD hide:YES];
            return;
        }
        NSDictionary *dics = back;
        NSLog(@"%@", dics);
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            [HUD hide:YES];
            [self loginUser];
//            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hud_error"]];
//            HUD.mode = MBProgressHUDModeCustomView;
//            [HUD hide:YES afterDelay:2]; // 延时2s消失
//            HUD.labelText = @"注册成功！";
//            [self dismissViewControllerAnimated:YES completion:^(){}];

        }else {
            // 错误返回码
            NSString *msg = [dics objectForKey:@"desc"];
            NSLog(@"未返回正确的数据：%@", msg);
            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hud_error"]];
            HUD.mode = MBProgressHUDModeCustomView;
            [HUD hide:YES afterDelay:2]; // 延时2s消失
            HUD.labelText = msg;
        }
        _isLoading  = NO;
    }];

}

-(void) verificationTimer
{
    __block int timeout = 119; //倒计时时间
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,queue);
    dispatch_source_set_timer(_timer,dispatch_walltime(NULL, 0),1.0*NSEC_PER_SEC, 0); //每秒执行
    dispatch_source_set_event_handler(_timer, ^{
        if(timeout<=0){
            //倒计时结束，关闭
            dispatch_source_cancel(_timer);
            dispatch_async(dispatch_get_main_queue(), ^{
                [_getPhonrCodeBut setTitle:@"验证" forState:UIControlStateNormal];
                _getPhonrCodeBut.userInteractionEnabled = YES;
            });
        }else{
            int seconds = timeout % 120;
            NSString *strTime = [NSString stringWithFormat:@"%.2d", seconds];
            dispatch_async(dispatch_get_main_queue(), ^{
                [_getPhonrCodeBut setTitle:[NSString stringWithFormat:@"%@",strTime] forState:UIControlStateNormal];
                _getPhonrCodeBut.userInteractionEnabled = NO;
            });
            timeout--;
        }
    });
    dispatch_resume(_timer);
}


- (void)loginUser
{

//    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//    [parameters setObject:_userphone.text forKey:@"account"];
//    [parameters setObject:_password.text forKey:@"password"];
//    if (_requestClient == nil) {
//        _requestClient = [[QMZBNetwork alloc] init];
//    }
//    [self startRequest];
//    [_requestClient postddByByUrlPath:@"/live/Login" andParams:parameters andCallBack:^(id back) {
//        if ([back isKindOfClass:[NSString class]]) {
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//            [alert show];
//            [HUD hide:YES];
//            return;
//        }
//        NSDictionary *dics = back;
//        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
//        if (result_type == 10000) {
//            [HUD hide:YES];
//            
//            NSLog(@"%@", dics);
//            QMZBUserInfo *userInfo = [[QMZBUserInfo alloc] init];
//            userInfo.userName = [NSString jsonUtils:[dics objectForKey:@"account"]];
//            userInfo.nickName = [NSString jsonUtils:[dics objectForKey:@"nickName"]];
//            userInfo.liveRoomId = [NSString jsonUtils:[dics objectForKey:@"liveRoomId"]];
//            userInfo.sessionId = [NSString jsonUtils:[dics objectForKey:@"sessionId"]];
//            userInfo.headerpicId = [NSString jsonUtils:[dics objectForKey:@"headPicId"]];
//            userInfo.sex = [NSString jsonUtils:[dics objectForKey:@"sex"]];
//            userInfo.isLogin = YES;
//            [userInfo setUserInfoLogin:_userphone.text withPassWord:_password.text ];
//            AppDelegateInstance.userInfo = userInfo;
//            
//            [[NSNotificationCenter defaultCenter]  postNotificationName:NotificationUpdateTab object:[NSString stringWithFormat:@"%d", 0]];
////            [self.navigationController popToRootViewControllerAnimated:YES];
//        }else {
//            // 错误返回码
//            NSString *msg = [dics objectForKey:@"desc"];
//            NSLog(@"未返回正确的数据：%@", msg);
//            HUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hud_error"]];
//            HUD.mode = MBProgressHUDModeCustomView;
//            [HUD hide:YES afterDelay:2]; // 延时2s消失
//            HUD.labelText = msg;
//        }
//        _isLoading  = NO;
//    }];

    NSDictionary *userInfo = @{@"account":_userphone.text,@"password":_password.text};
    [[NSNotificationCenter defaultCenter]  postNotificationName:NotificationRegisterSeccess object:userInfo];
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:^(){}];

}

-(void) startRequest
{
    _isLoading = YES;
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.labelText = @"正在加载...";
    HUD.delegate = self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}




@end
