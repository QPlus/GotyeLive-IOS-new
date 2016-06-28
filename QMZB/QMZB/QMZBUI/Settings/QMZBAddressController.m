//
//  QMZBAddressController.m
//  QMZB
//
//  Created by Jim on 16/5/17.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBAddressController.h"
#import <CoreLocation/CoreLocation.h>
#import "QMZBAreaView.h"

@interface QMZBAddressController ()<CLLocationManagerDelegate,QMZBAreaPickerDelegate>

@property(nonatomic,strong)CLLocationManager *locMgr;
@property(nonatomic,strong)UILabel *locationLabel;
@property (strong, nonatomic) QMZBAreaView *locatePicker;
@property (strong, nonatomic) UIButton *locateButton;

@end

@implementation QMZBAddressController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initNavigationBar];
    [self startLocation];
    [self initView];
}

- (void)initNavigationBar
{
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.translucent =NO;
    self.title = @"定位";
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

- (void)initView
{
    _locateButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locateButton.frame = CGRectMake(10, 60, ScreenWidth-20, 40);
    _locateButton.layer.cornerRadius = 3;
    _locateButton.backgroundColor = COLOR(203, 133, 248, 1);
    [_locateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.view addSubview:_locateButton];
    [_locateButton addTarget:self action:@selector(choseLocatio:) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *s = [NSString stringWithFormat:@"当前定位:%@",AppDelegateInstance.userInfo.userAddress];
    [_locateButton setTitle:s forState:UIControlStateNormal];
    
    //点击空白处收回键盘
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelLocatePicker)];
    //设置成NO表示当前控件响应后会传播到其他控件上，默认为YES。
    tapGestureRecognizer.cancelsTouchesInView = NO;
    //将触摸事件添加到当前view
    [self.view addGestureRecognizer:tapGestureRecognizer];
}

- (void)choseLocatio:(UIButton *)sender
{
    [self cancelLocatePicker];
    _locatePicker = [[QMZBAreaView alloc] initWithdelegate:self];
    [_locatePicker showInView:self.view];
}

-(void)cancelLocatePicker
{
    [_locatePicker cancelPicker];
    _locatePicker.delegate = nil;
    _locatePicker = nil;
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

#pragma mark - HZAreaPicker delegate
-(void)pickerDidChaneStatus:(QMZBAreaView *)picker
{
    NSString *s = [NSString stringWithFormat:@"当前定位:%@%@%@",picker.locate.state, picker.locate.city, picker.locate.district];
    [_locateButton setTitle:s forState:UIControlStateNormal];
    AppDelegateInstance.userInfo.userAddress = [NSString stringWithFormat:@"%@%@%@",picker.locate.state, picker.locate.city, picker.locate.district];
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
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
