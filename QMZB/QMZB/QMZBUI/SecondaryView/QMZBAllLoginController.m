//
//  QMZBAllLoginController.m
//  QMZB
//
//  Created by Jim on 16/5/9.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBAllLoginController.h"
#import "WXApi.h"
#import "QMZBLoginController.h"
@interface QMZBAllLoginController ()
{
    NSString *_code;

}

@end

@implementation QMZBAllLoginController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notification:) name:@"LOGINNOTIFICATION" object:nil];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:NO];
    if (AppDelegateInstance.userInfo.isLogin) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)weixinBtnClick:(id)sender
{
//    if ([WXApi isWXAppInstalled] && [WXApi isWXAppSupportApi]) {
//        
//        //构造SendAuthReq结构体
//        SendAuthReq* req =[[SendAuthReq alloc]init];
//        req.scope = @"snsapi_userinfo" ;
//        req.state = @"qmzb" ;
//        //第三方向微信终端发送一个SendAuthReq消息结构
//        [WXApi sendReq:req];
//    }else {
//    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"暂未开通" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

- (IBAction)phoneBtnClick:(id)sender
{
    QMZBLoginController *registeredUser = [[QMZBLoginController alloc] init];
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self presentViewController:registeredUser animated:NO completion:nil];
}

- (IBAction)privacyBtnClick:(id)sender//亲加服务和隐私条款
{
    
}

#pragma mark - WXApi全局通知
- (void) notification:(NSNotification *)notification
{
    NSString *result = [notification.userInfo objectForKey:@"code"];
    _code = result;
    
    [self loadWeixin];
}

#pragma mark -   Weixin登录
- (void)loadWeixin
{
    if ([_code isEqualToString:@""]) {
        return;
    }
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",@"wxef1896544eeaef1a",@"51b4ac5d82a410b4498328200603f9c4",_code];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                /*
                 {
                 "access_token" = "OezXcEiiBSKSxW0eoylIeJDUKD6z6dmr42JANLPjNN7Kaf3e4GZ2OncrCfiKnGWiusJMZwzQU8kXcnT1hNs_ykAFDfDEuNp6waj-bDdepEzooL_k1vb7EQzhP8plTbD0AgR8zCRi1It3eNS7yRyd5A";
                 "expires_in" = 7200;
                 openid = oyAaTjsDx7pl4Q42O3sDzDtA7gZs;
                 "refresh_token" = "OezXcEiiBSKSxW0eoylIeJDUKD6z6dmr42JANLPjNN7Kaf3e4GZ2OncrCfiKnGWi2ZzH_XfVVxZbmha9oSFnKAhFsS0iyARkXCa7zPu4MqVRdwyb8J16V8cWw7oNIff0l-5F-4-GJwD8MopmjHXKiA";
                 scope = "snsapi_userinfo,snsapi_base";
                 }
                 */
                if ([dic objectForKey:@"errcode"])
                {
                    //AccessToken失效
                    [self getAccessTokenWithRefreshToken:[[NSUserDefaults standardUserDefaults]objectForKey:@"refresh_token"]];
                }else{
                    //获取需要的数据
                    [self getUserInfo:[dic objectForKey:@"access_token"] :[dic objectForKey:@"openid"]];
                }
            }
        });
    });
}

- (void)getAccessTokenWithRefreshToken:(NSString *)refreshToken
{
    NSString *urlString =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=%@&grant_type=refresh_token&refresh_token=%@",@"wxef1896544eeaef1a",refreshToken];
    NSURL *url = [NSURL URLWithString:urlString];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *dataStr = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data){
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                if ([dict objectForKey:@"errcode"]){
                    //授权过期
                }else{
                    //重新使用AccessToken获取信息
                    [self getUserInfo:[dict objectForKey:@"access_token"] :[dict objectForKey:@"openid"]];
                }
            }
        });
    });
}

-(void)getUserInfo:(NSString *)token :(NSString *)openId
{
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",token,openId];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                /*
                 {
                 city = Haidian;
                 country = CN;
                 headimgurl = "http://wx.qlogo.cn/mmopen/FrdAUicrPIibcpGzxuD0kjfnvc2klwzQ62a1brlWq1sjNfWREia6W8Cf8kNCbErowsSUcGSIltXTqrhQgPEibYakpl5EokGMibMPU/0";
                 language = "zh_CN";
                 nickname = "xxx";
                 openid = oyAaTjsDx7pl4xxxxxxx;
                 privilege =     (
                 );
                 province = Beijing;
                 sex = 1;
                 unionid = oyAaTjsxxxxxxQ42O3xxxxxxs;
                 }
                 */
                NSLog(@"weixinUserInfo:%@",dic);
//                flag = 1;
//                [self requestData:[dic objectForKey:@"openid"]];
                
            }
        });
        
    });
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
