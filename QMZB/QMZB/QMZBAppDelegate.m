//
//  AppDelegate.m
//  QMZB
//
//  Created by Jim on 16/3/16.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBAppDelegate.h"
#import "QMZBUIUtil.h"
#import "QMZBTabViewController.h"

#import "WXApi.h"
#import "WeiboSDK.h"
#import "GLCore.h"
#import "GLPlayer.h"
#import "GLChatSession.h"
#import "GLPublisher.h"
#import "BaseNavigationController.h"
#import "MobClick.h"
#import <AlipaySDK/AlipaySDK.h>

#define APPKEY           (@"46a9779e-f653-11e5-8fee-5254009b7711")
#define LIVE_AK          (@"8aa76e4e008e4a8b82db68f289c8ead0")    //deploy
#define COMPANY          (@"gotyeopen")

#define WX_APP           (@"wxef1896544eeaef1a")
#define Weibo_APP        (@"971559106")
#define Bugly_APP        (@"900015967")

@interface QMZBAppDelegate ()<WXApiDelegate, WeiboSDKDelegate>


@end

@implementation QMZBAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    QMZBTabViewController *tabBarController = [[QMZBTabViewController alloc] init];
    BaseNavigationController * navigationController = [[BaseNavigationController alloc] initWithRootViewController:tabBarController];

    // 2 作为根视图控制器
    self.window.rootViewController = navigationController;
    

    [WXApi registerApp:WX_APP];
    [WeiboSDK registerApp:Weibo_APP];
    [WeiboSDK enableDebugMode:YES];
    
//    [MobClick setLogEnabled:YES];
    [MobClick startWithAppkey:@"57106368e0f55a8ac10008b9"];
    
    [GLCore registerWithAppKey:APPKEY accessSecret:LIVE_AK companyId:nil];
    [GLCore setDebugLogEnabled:YES];
    
#ifdef __IPHONE_8_0
#if __IPHONE_8_0 <= __IPHONE_OS_VERSION_MAX_ALLOWED
    if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 8.0) {
        [application registerForRemoteNotifications];
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil]];
    } else {
        [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
    }
#endif
#else
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert|UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound];
#endif
    
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(nonnull NSURL *)url
{
    if ([url.host isEqualToString:@"safepay"]) {
        //跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
        }];
        return YES;
    }
    return [WXApi handleOpenURL:url delegate:self] ||
    [WeiboSDK handleOpenURL:url delegate:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options
{
    return [self application:application handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(id)annotation
{
    return [self application:application handleOpenURL:url];
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request
{
    
}

- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    
}

#pragma mark 微信支付结果

-(void) onResp:(BaseResp*)resp
{
    if ([resp isKindOfClass:[SendAuthResp class]]){
        //weixin  登录
        SendAuthResp *aresp = (SendAuthResp *)resp;
        if (aresp.errCode== 0) {
            NSString *code = aresp.code;
            NSDictionary *dic = @{@"code":code};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"LOGINNOTIFICATION"
                                                                object:self
                                                              userInfo:dic];
        }
    }
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window
{
//    if (self.allowRotation) {
//        return UIInterfaceOrientationMaskPortrait;
//    }else {
//    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
