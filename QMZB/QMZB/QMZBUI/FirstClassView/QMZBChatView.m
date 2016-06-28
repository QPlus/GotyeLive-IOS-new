//
//  QMZBChatView.m
//  QMZB
//
//  Created by Jim on 16/4/19.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBChatView.h"
#import "GLPlayer.h"
#import "GLCore.h"
#import "GLPublisher.h"
#import "GLPublisherDelegate.h"
#import "UIView+Extension.h"
#import "WXApiObject.h"
#import "WXApi.h"
#import "GLClientUrl.h"
#import "WeiboSDK.h"
#import <MediaPlayer/MediaPlayer.h>
#import "QMZBUIUtil.h"
#import "GLChatObserver.h"
#import "GLChatSession.h"
#import "GLRoomPlayer.h"
#import "GLRoomPublisher.h"
#import "GLRoomPublisherDelegate.h"
#import "MBProgressHUD.h"
#import "QMZBNetwork.h"
#import "NSString+Extension.h"
#import "MobClick.h"
#import "DMHeartFlyView.h"
#import "PresentCollectionViewCell.h"
#import "iCarousel.h"
#import "QMZBBubbleView.h"
#import "MessageCell.h"

@interface QMZBChatView ()<GLPlayerDelegate,GLRoomPlayerDelegate, GLChatObserver, GLRoomPublisherDelegate, UITextFieldDelegate,MBProgressHUDDelegate,iCarouselDataSource,iCarouselDelegate,UIGestureRecognizerDelegate,UITableViewDataSource, UITableViewDelegate>
{
    NSTimer *_logPublisher;
    NSInteger _logTime;
    
    GLSmoothSkinFilter *_smoothSkinFilter;
    
    UITextField *_inputField;
    
    NSTimer *_pushLiveStreamTimer;
    NSTimer *_publishTimer;
    NSUInteger _totalPublishSeconds;

    CGFloat _chatConY;
    BOOL _isHeartFlyView;
    
    UIView *_presentView;
    UIView *_shareView;
    
    NSInteger _tapGestureType;
    
    UITapGestureRecognizer *_tapGesture;
    
    dispatch_source_t _timer;//定时获取了聊天室人数
    
}
@property (strong, nonatomic) IBOutlet GLPlayerView *playView;
@property (strong, nonatomic) IBOutlet UIView *chatContentView;
@property (strong, nonatomic) IBOutlet UIButton *startRec;
@property (strong, nonatomic) IBOutlet UILabel *timeLabel;
@property (strong, nonatomic) IBOutlet UILabel *manCount;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (strong, nonatomic) IBOutlet UIView *chatSuperView;
@property (strong, nonatomic) IBOutlet UIButton *presentBut;
@property (strong, nonatomic) IBOutlet UIButton *cameraBut;
@property (strong, nonatomic) IBOutlet UIButton *whitenBut;
@property (strong, nonatomic) IBOutlet UIButton *shareBut;

@property (nonatomic,copy)GLRoomPublisher *publisher;

@property (nonatomic,copy)GLPlayer *player;

@property (nonatomic,copy)GLChatSession *chatKit;

@property (nonatomic,copy)GLRoomSession * session;

@property(nonatomic ,strong) QMZBNetwork *requestClient;

@property (nonatomic , strong) iCarousel *carousel;

@property (nonatomic , strong) UITableView *chatTableView;

@property (nonatomic, strong) NSMutableArray *messageArrays;

@end

@implementation QMZBChatView

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loginRoom];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillhide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillshow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)loginRoom
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _session = [GLCore sessionWithType:GLRoomSessionTypeDefault roomId:_roomId password:_password nickname:_nickName bindAccount:AppDelegateInstance.userInfo.userName];
    _chatKit = [[GLChatSession alloc] initWithSession:_session];
    if (self.isLiveMode) {
        
        _publisher = [[GLRoomPublisher alloc] initWithSession:_session];
    }else {
        
        _player = [[GLPlayer alloc] initWithUrl:_playUrl];
//        _player = [[GLRoomPlayer alloc] initWithRoomSession:_session];
//        _player.playUrl = _playUrl;
        GLRoomSession *sess = [[GLRoomSession alloc] initWithType:GLRoomSessionTypeDefault roomId:_roomId password:_password nickname:_nickName bindAccount:nil];
        _player.roomSession = sess;
    }
    
    [hud hide:YES];
    
    _logTime = 0;
    _logPublisher = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(logPublisherTimer) userInfo:nil repeats:YES];
    [_logPublisher fire];
    
    [self initView];
    [_session authOnSuccess:^(GLAuthToken *authToken) {
        if (authToken.role == GLAuthTokenRolePresenter) {
            
            
            [self _loginPublisherWithForce:NO callback:^(NSError *error) {
                
                [_logPublisher invalidate];
                NSString *now = [NSString stringWithFormat:@"%ld",(long)(_logTime/10)];
                NSLog(@"-----%@",now);
                NSDictionary *dic = @{@"time":now};
                [MobClick event:@"loginPublisher" attributes:dic];
                
                if (!error) {
                    [self _enterChatRoomWithRoomId:_roomId password:_password callback:^(NSError *error, NSString *account, NSString *nickname) {
                        if (error) {
                            [self hud:hud showError:error.localizedDescription];
                        } else {
                            
                        }
                    }];
                    return;
                }
                
                if (error.code == GLPublisherErrorCodeOccupied) {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"当前直播间已经有人登录了，继续登录的话将会踢出当前用户的用户。是否继续？" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *goOn = [UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        [self _loginPublisherWithForce:YES callback:^(NSError *error) {
                            if (error) {
                                [self hud:hud showError:error.localizedDescription];
                                return;
                            }
                            [self _enterChatRoomWithRoomId:_roomId password:_password callback:^(NSError *error, NSString *account, NSString *nickname) {
                                if (error) {
                                    [self hud:hud showError:error.localizedDescription];
                                } else {
                                    [hud hide:YES];
                                }
                            }];
                        }];
                    }];
                    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        [self.view endEditing:YES];
                    }];
                    [alert addAction:cancel];
                    [alert addAction:goOn];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                } else {
                    [self hud:hud showError:error.localizedDescription];
                }
            }];
        } else {
            [self _enterChatRoomWithRoomId:_roomId password:_password callback:^(NSError *error, NSString *account, NSString *nickname) {
                if (error) {
                    [self hud:hud showError:error.localizedDescription];
                } else {
                    
                }
            }];
        }
        
        
    } failure:^(NSError *error) {
        NSLog(@"====%@",error.localizedDescription);
        [self hud:hud showError:error.localizedDescription];
    }];
    
}

- (void)logPublisherTimer
{
    _logTime++;
}

- (void)initView
{
    _tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showTheLove)];
    _tapGesture.delegate = self;
    [_chatSuperView addGestureRecognizer:_tapGesture];
    
    _carousel = [[iCarousel alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight)];
    _carousel.backgroundColor = [UIColor clearColor];
    _carousel.dataSource = self;
    _carousel.delegate = self;
    _carousel.decelerationRate = 0.7;
    _carousel.type = iCarouselTypeLinear;
    _carousel.pagingEnabled = YES;
    _carousel.edgeRecognition = YES;
    _carousel.bounceDistance = 0.4;
    _carousel.bounces = NO;
    [self.view addSubview:_carousel];
    [_carousel scrollToItemAtIndex:1 animated:NO];
    
    _chatTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 180, _chatContentView.width, _chatContentView.height-180) style:UITableViewStylePlain];
    _chatTableView.dataSource = self;
    _chatTableView.backgroundColor = [UIColor clearColor];
    _chatTableView.delegate = self;
    _chatTableView.showsVerticalScrollIndicator = NO;
    _chatTableView.separatorStyle = UITableViewCellSelectionStyleNone;
    [_chatContentView addSubview:_chatTableView];
    
    _inputField = [[UITextField alloc] initWithFrame:CGRectMake(16, -100, ScreenWidth-32, 40)];
    [_chatSuperView addSubview:_inputField];
    _inputField.layer.cornerRadius = 5.0f;
    _inputField.backgroundColor = WHITE_COLOR;
    _inputField.returnKeyType = UIReturnKeySend;
    _inputField.delegate = self;
    _inputField.placeholder = @"说点什么吧";
    UIColor *color = [UIColor lightGrayColor];
    _inputField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_inputField.placeholder attributes:@{NSForegroundColorAttributeName: color}];
    
    //礼物view
    _presentView = [[UIView alloc] initWithFrame:CGRectMake(10, ScreenHeight, ScreenWidth-20, 100)];
    _presentView.backgroundColor = COLOR(25, 151, 220, 0.3);
    [_chatSuperView addSubview:_presentView];
    [self initflowerView];
    
    //分享view
    _shareView = [[UIView alloc] initWithFrame:CGRectMake(10, ScreenHeight, ScreenWidth-20, 120)];
    _shareView.backgroundColor = COLOR(25, 151, 220, 0.3);
    [_chatSuperView addSubview:_shareView];
    UILabel *shareLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, ScreenWidth-20, 20)];
    shareLabel.text = @"分享到";
    shareLabel.textColor = TEXT_BLACK_COLOR;
    shareLabel.textAlignment = NSTextAlignmentCenter;
    shareLabel.font = [UIFont systemFontOfSize:15.0];
    shareLabel.backgroundColor = [UIColor clearColor];
    [_shareView addSubview:shareLabel];
    
    for (int i = 0; i < 3; i++) {
        UIButton *function = [UIButton buttonWithType:UIButtonTypeCustom];
        function.frame = CGRectMake(i*(ScreenWidth-20)/3, 35, (ScreenWidth-20)/3, 50);
        function.layer.cornerRadius = 3;
        function.tag = 1000+i;
        function.backgroundColor = [UIColor clearColor];
        [_shareView addSubview:function];
        [function addTarget:self action:@selector(functionBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        UILabel *titleLab = [[UILabel alloc] initWithFrame:CGRectMake(i*(ScreenWidth-20)/3, 90, (ScreenWidth-20)/3, 20)];
        titleLab.textColor = TEXT_BLACK_COLOR;
        titleLab.textAlignment = NSTextAlignmentCenter;
        titleLab.font = [UIFont systemFontOfSize:13.0];
        titleLab.backgroundColor = [UIColor clearColor];
        [_shareView addSubview:titleLab];
        
        if (i == 0) {
            titleLab.text = @"微信朋友圈";
            [function setImage:[UIImage imageNamed:@"btn_peng_you_quan"] forState:UIControlStateNormal];
        }else if (i == 1) {
            titleLab.text = @"微信好友";
            [function setImage:[UIImage imageNamed:@"btn_weixin"] forState:UIControlStateNormal];
        }else {
            titleLab.text = @"新浪微博";
            [function setImage:[UIImage imageNamed:@"btn_sina_weibo"] forState:UIControlStateNormal];
        }
    }
    _tapGestureType = 0;
    _chatConY = _chatContentView.y;
    _messageArrays = [[NSMutableArray alloc] init];

    if (self.isLiveMode) {
        GLPublisherVideoPreset *preset = [GLPublisherVideoPreset
                                          presetWithResolution:GLPublisherVideoResolutionCustom];
        preset.videoSize = CGSizeMake(368, 640);
        preset.fps = 24;
        preset.bps = 720;
        _publisher.videoPreset = preset;
        _publisher.delegate = self;
        _smoothSkinFilter = [GLSmoothSkinFilter new];
        _smoothSkinFilter.factor = 4.0;
        _isHeartFlyView = NO;
        _startRec.hidden = NO;
        _timeLabel.hidden = NO;
        _presentBut.hidden = YES;
        _cameraBut.hidden = NO;
        _whitenBut.hidden = NO;
        _carousel.scrollEnabled = NO;
//        [self applyWatermark];//水印
        _whitenBut.x = _cameraBut.x-60;
        [_publisher startPreview:_playView success:^{
            NSLog(@"preview success");
            [self hideIndicator];
        } failure:^(NSError *error) {
            NSLog(@"preview failed. %@", error);
        }];


    } else {
        _player.delegate = self;
        _playView.fillMode = GLPlayerViewFillModeAspectFill;
        [_player playWithView:_playView];
        [self showIndicator];
        _presentBut.x = _shareBut.x-60;
        _whitenBut.hidden = YES;
        _isHeartFlyView = YES;
        _startRec.hidden = YES;
        _timeLabel.hidden = YES;
        _presentBut.hidden = NO;
        _cameraBut.hidden = YES;
    }
    
    [_chatKit addObserver:self];
}


#pragma mark - private
- (void)showMyPresent:(NSString *)nickName imageName:(NSString *)imageName inter:(NSInteger)index
{
    UIView *myPresent = [[UIView alloc] initWithFrame:CGRectMake(-ScreenWidth, 30 + 65*index, ScreenWidth-100, 60)];
    myPresent.backgroundColor = COLOR(53,146,226,0.3);
    myPresent.layer.cornerRadius = 20;
    [_chatSuperView addSubview:myPresent];
    UILabel *shareLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, myPresent.width-100, 60)];
    shareLabel.text = [NSString stringWithFormat:@"%@赠送",nickName];
    shareLabel.textColor = WHITE_COLOR;
    shareLabel.numberOfLines = 0;
    shareLabel.font = [UIFont systemFontOfSize:15.0];
    shareLabel.backgroundColor = [UIColor clearColor];
    [myPresent addSubview:shareLabel];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(myPresent.width-80, 0, 60, 60)];
    imageView.image = [UIImage imageNamed:imageName];
    [myPresent addSubview:imageView];

    [UIView animateWithDuration:0.2 delay:0.f options:UIViewAnimationOptionCurveLinear  animations:^{
        myPresent.x = 50;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:2.0f options:UIViewAnimationOptionCurveLinear  animations:^{
            myPresent.x = -ScreenWidth;
        } completion:^(BOOL finished) {
            [myPresent removeFromSuperview];
        }];
    }];
}

- (void)initflowerView
{
    for (int i = 0; i < 4; i++) {
        UIButton *flower = [UIButton buttonWithType:UIButtonTypeCustom];
        flower.frame = CGRectMake(i*(ScreenWidth-20)/4+20, 10, 50, 50);
        flower.layer.cornerRadius = 3;
        flower.tag = 1100+i;
        flower.backgroundColor = [UIColor clearColor];
        [_presentView addSubview:flower];
        [flower addTarget:self action:@selector(flowerBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        UILabel *titleLab = [[UILabel alloc] initWithFrame:CGRectMake(i*(ScreenWidth-20)/4, 70, (ScreenWidth-20)/4, 20)];
        titleLab.textColor = WHITE_COLOR;
        titleLab.textAlignment = NSTextAlignmentCenter;
        titleLab.font = [UIFont systemFontOfSize:13.0];
        titleLab.backgroundColor = [UIColor clearColor];
        [_presentView addSubview:titleLab];
        
        if (i == 0) {
            titleLab.text = @"一朵花";
            [flower setImage:[UIImage imageNamed:@"a-flowers"] forState:UIControlStateNormal];
        }else if (i == 1) {
            titleLab.text = @"钻石";
            [flower setImage:[UIImage imageNamed:@"a-masonry"] forState:UIControlStateNormal];
        }else if (i == 2) {
            titleLab.text = @"一束花";
            [flower setImage:[UIImage imageNamed:@"a-more-flowers"] forState:UIControlStateNormal];
        }else {
            titleLab.text = @"跑车";
            [flower setImage:[UIImage imageNamed:@"a-Sports-car"] forState:UIControlStateNormal];
        }
    }
}


- (void)functionBtnClick:(UIButton *)button
{
    [_session getClientUrlsOnSuccess:^(GLClientUrl *clientUrl) {
        NSString *shareUrl = clientUrl.educVisitorUrl;

        switch (button.tag) {
            case 1000:
                [self shareToWeiXin:shareUrl inScene:WXSceneTimeline];
                break;
            case 1001:
                [self shareToWeiXin:shareUrl inScene:WXSceneSession];
                break;
            case 1002:
                [self shareToSinaWeibo:shareUrl];
                break;
            default:
                break;
        }
    } failure:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"获取分享url出错！" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
    }];
    

}

- (void)flowerBtnClick:(UIButton *)button
{
    switch (button.tag) {
            
        case 1100:
        {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
            [params setObject:AppDelegateInstance.userInfo.userName forKey:@"account"];
            [params setObject:@"3"  forKey:@"msgid"];
            [params setObject:_nickName  forKey:@"nickname"];
            NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:1];
            [data setObject:@(1)  forKey:@"eventid"];
            [params setObject:data  forKey:@"data"];
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
            NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self payQinCoin:1];
            [self sendClick:@"" json:sssss];
        }
            break;
        case 1101:
        {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
            [params setObject:AppDelegateInstance.userInfo.userName forKey:@"account"];
            [params setObject:@"3"  forKey:@"msgid"];
            [params setObject:_nickName  forKey:@"nickname"];
            NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:1];
            [data setObject:@(2)  forKey:@"eventid"];
            [params setObject:data  forKey:@"data"];
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
            NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self payQinCoin:10];
            [self sendClick:@"" json:sssss];
        }
            break;
        case 1102:
        {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
            [params setObject:AppDelegateInstance.userInfo.userName forKey:@"account"];
            [params setObject:@"3"  forKey:@"msgid"];
            [params setObject:_nickName  forKey:@"nickname"];
            NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:1];
            [data setObject:@(3)  forKey:@"eventid"];
            [params setObject:data  forKey:@"data"];
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
            NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self payQinCoin:100];
            [self sendClick:@"" json:sssss];
        }
            break;
        case 1103:
        {
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
            [params setObject:AppDelegateInstance.userInfo.userName forKey:@"account"];
            [params setObject:@"3"  forKey:@"msgid"];
            [params setObject:_nickName  forKey:@"nickname"];
            NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:1];
            [data setObject:@(4)  forKey:@"eventid"];
            [params setObject:data  forKey:@"data"];
            NSError *parseError = nil;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
            NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self payQinCoin:1000];
            [self sendClick:@"" json:sssss];
        }
            break;
        default:
            break;
    }
}


- (void)_loginPublisherWithForce:(BOOL)force callback:(void(^)(NSError *error))callback
{
    [_publisher loginWithForce:force success:^{
        if (callback) {
            callback(nil);
        }
    } failure:^(NSError *error) {
        if (callback) {
            callback(error);
        }
    }];
}

- (void)hud:(MBProgressHUD *)hud showError:(NSString *)error
{
    hud.detailsLabelText = @"网络异常";
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:1];
}


- (void)_enterChatRoomWithRoomId:(NSString *)roomId password:(NSString *)password callback:(void(^)(NSError *error, NSString *account, NSString *nickname))callback
{
    [_chatKit loginOnSuccess:^(NSString *account, NSString *nickname) {
        
        [_chatKit sendNotify:@"enter" extra:nil success:nil failure:nil];
        
        double delayInSeconds = 20.0;
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC, 0.0);
        dispatch_source_set_event_handler(_timer, ^{
            
            [self updateRoomUserCount];
        });  
        dispatch_resume(_timer);
        
        callback(nil, account, nickname);
    } failure:^(NSError *error) {
        if (callback) {
            callback(error, nil, nil);
        }
    }];
}

-(void)showTheLove
{
    if (_isHeartFlyView) {
        int x = (arc4random() % 5)+1;
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
        [params setObject:AppDelegateInstance.userInfo.userName forKey:@"account"];
        [params setObject:@"2"  forKey:@"msgid"];
        [params setObject:_nickName  forKey:@"nickname"];
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:1];
        [data setObject:@(x)  forKey:@"eventid"];
        [params setObject:data  forKey:@"data"];
        NSError *parseError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
        NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self sendClick:@"" json:sssss];
        _tapGesture.enabled = NO;
        [self performSelector:@selector(isTapGesture) withObject:self afterDelay:0.2];
    }else {
    }
    [_inputField resignFirstResponder];
    if (_tapGestureType == 1) {
        _tapGestureType = 0;
        [UIView animateWithDuration:0.3 animations:^{
            _shareView.y = ScreenHeight;
        } completion:nil];
    }else if (_tapGestureType == 2) {
        _tapGestureType = 0;
        [UIView animateWithDuration:0.3 animations:^{
            _presentView.y = ScreenHeight;
        } completion:nil];
    }else {
        
    }
}

- (void)isTapGesture
{
     _tapGesture.enabled = YES;
}

- (void)applyWatermark
{
    [_publisher clearWatermark];
    
    CGSize videoSize = _publisher.videoPreset.videoSize;
    CGSize watermarkSize = CGSizeMake(114, 36);
    [_publisher addWatermark:[UIImage imageNamed:@"watermark"] withFrame:CGRectMake(videoSize.width - watermarkSize.width - 10, videoSize.height - watermarkSize.height - 10, watermarkSize.width, watermarkSize.height)];
}

- (void)showIndicator
{
    _indicator.hidden = NO;
    [_indicator startAnimating];
}

- (void)hideIndicator
{
    _indicator.hidden = YES;
    [_indicator stopAnimating];
}

- (void)setTip:(NSString *)tip
{
    _manCount.text = tip;
}

- (void)keyboardWillshow:(NSNotification *)note
{
    NSDictionary *userInfo = note.userInfo;
    CGRect keyFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [UIView animateWithDuration:0.3 animations:^{
        _chatContentView.y = _chatConY - keyFrame.size.height;
        _inputField.y = ScreenHeight-keyFrame.size.height-40;
    } completion:nil];
}

- (void)keyboardWillhide:(NSNotification *)note
{
    [UIView animateWithDuration:0.3 animations:^{
        _chatContentView.y = _chatConY;
        _inputField.y = -100;
    } completion:nil];
}
- (void)forceLogout
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"你的账号在别处登录了！" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self closeClick:nil];
    }];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateRoomUserCount
{
    [_chatKit.roomSession getLiveContextOnSuccess:^(GLLiveContext *liveContext) {
        if (_player.state == GLPlayerStateStarted || _publisher.state == GLPublisherStatePublished) {
            [self setTip:[NSString stringWithFormat:@"观看人数: %ld", (long)liveContext.playUserCount]];
        }
        
    } failure:^(NSError *error) {
        NSLog(@"getLiveContext %@", error);
    }];
}

- (NSString *)timeFormatted:(int)totalSeconds
{
    
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    int hours = totalSeconds / 3600;
    
    return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
}

- (void)startPublishTimer
{
    if (_publishTimer) {
        return;
    }
    
    _publishTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updatePublishTime) userInfo:nil repeats:YES];
    [_publishTimer fire];
}

- (void)stopPublishTimer
{
    [_publishTimer invalidate];
    _publishTimer = nil;
}

- (void)updatePublishTime
{
    _timeLabel.text = [self timeFormatted:(int)_totalPublishSeconds++];
    if (_totalPublishSeconds % 60 == 0) {
        [self updateRoomUserCount];
    }
}

- (void)publishDidStop
{
    _startRec.enabled = YES;
    _startRec.selected = NO;
    [_startRec setImage:[UIImage imageNamed:@"btn_start"] forState:UIControlStateNormal];
    
    _timeLabel.hidden = YES;
    _totalPublishSeconds = 0;
    [self stopPublishTimer];
    [self hideIndicator];
}

- (void)sendClick:(NSString *)text json:(NSString *)json
{
    [_chatKit sendText:json extra:nil success:^{
//        if (text.length == 0) {
        
            NSData *da= [json dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithData:da options:NSJSONReadingMutableContainers error:&error];
            if ([jsonObject isKindOfClass:[NSDictionary class]]){
                
                NSDictionary *dictionary = (NSDictionary *)jsonObject;
                NSString *msgid = [dictionary objectForKey:@"msgid"];
                if ([msgid intValue] == 1) {
                    NSDictionary *data = [dictionary objectForKey:@"data"];
                    NSString *msgText = [data objectForKey:@"msg"];
                    [self showPopSubtitle:msgText nickName:AppDelegateInstance.userInfo.nickName];
                    [_messageArrays addObject:json];
                    [_chatTableView reloadData];
                    NSLog(@"------");
                    [_chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messageArrays.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                }else if ([msgid intValue] == 2) {
                    NSString *nic = [dictionary objectForKey:@"nickname"];
                    if ([nic isEqualToString:AppDelegateInstance.userInfo.nickName]) {
                        DMHeartFlyView* heart = [[DMHeartFlyView alloc]initWithFrame:CGRectMake(0, 0, 36, 36)];
                        [_chatSuperView addSubview:heart];
                        CGPoint fountainSource = CGPointMake(200, self.view.bounds.size.height - 36/2.0 - 10);
                        heart.center = fountainSource;
                        [heart animateInView:_chatSuperView];
                    }else {
                        
                    }
                    
                }else if ([msgid intValue] == 3) {
                    [_messageArrays addObject:json];
                    [_chatTableView reloadData];
                    [_chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messageArrays.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
                    NSDictionary *data = [dictionary objectForKey:@"data"];
                    NSString *eventid = [data objectForKey:@"eventid"];
                    if ([eventid intValue] == 1) {
                        [self showMyPresent:AppDelegateInstance.userInfo.nickName imageName:@"a-flowers" inter:1];
                    }else if ([eventid intValue] == 2) {
                        [self showMyPresent:AppDelegateInstance.userInfo.nickName imageName:@"a-masonry" inter:2];
                    }else if ([eventid intValue] == 3) {
                        [self showMyPresent:AppDelegateInstance.userInfo.nickName imageName:@"a-more-flowers" inter:3];
                    }else {
                        [self showMyPresent:AppDelegateInstance.userInfo.nickName imageName:@"a-Sports-car" inter:4];
                    }
                }else {
                    
                }
            }else {
                
            }
//        }else {
//            
//        }
    } failure:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"发送失败" message:@"网络异常" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
    }];
}

- (void)shareToWeiXin:(NSString *)url inScene:(enum WXScene)scene
{
    WXMediaMessage *message = [[WXMediaMessage alloc]init];
    message.title = @"亲加视频直播";
    message.description = @"这是一个直播";
    [message setThumbImage:[UIImage imageNamed:@"AppIcon60x60"]];
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = url;
    message.mediaObject = ext;
    
    SendMessageToWXReq *req = [SendMessageToWXReq new];
    req.bText = NO;
    req.message = message;
    req.scene = scene;
    
    [WXApi sendReq:req];
}

- (void)shareToSinaWeibo:(NSString *)url
{
    WBMessageObject *message = [WBMessageObject message];
    
    WBWebpageObject *webpage = [WBWebpageObject object];
    webpage.objectID = @"identifier1";
    webpage.title = @"亲加视频直播";
    webpage.description = @"这是一个直播";
    webpage.thumbnailData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"AppIcon60x60@2x" ofType:@"png"]];
    webpage.webpageUrl = url;
    message.mediaObject = webpage;
    message.text = @"#亲加直播#";
    
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.scope = @"all";
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:message authInfo:authRequest access_token:nil];
    
    [WeiboSDK sendRequest:request];
}

- (void) dimissAlert:(UIAlertView *)alert
{
    if(alert) {
        
        [alert dismissWithClickedButtonIndex:[alert cancelButtonIndex] animated:YES];
    }
}

#pragma mark - 弹幕
- (void)showPopSubtitle:(NSString *)text nickName:(NSString *)nickName
{
    
    CGFloat speed = 100;
    int x = (arc4random() % 5);
    int top = x * 40+ScreenHeight/2-100;
    QMZBBubbleView *item = [[QMZBBubbleView alloc] initWithFrame:CGRectMake(ScreenWidth, top, 10, 30)];
    [item setPresenterWithNickname:nickName withContent:text];
    [_chatSuperView addSubview:item];
    
    CGFloat time = (item.width+ScreenWidth) / speed;
    [UIView animateWithDuration:time delay:0.f options:UIViewAnimationOptionCurveLinear  animations:^{
        item.x = -item.width;
    } completion:^(BOOL finished) {
        [item removeFromSuperview];
    }];
    
}


#pragma mark - 点击事件
- (IBAction)closeClick:(id)sender
{
    [_player stop];
    [_publisher stop];
    [_chatKit logout];
    [_chatKit removeObserver:self];
    [_messageArrays removeAllObjects];
    [self stopPublishTimer];
    [_pushLiveStreamTimer invalidate];
    if (_timer) {
        
        dispatch_source_cancel(_timer);
    }
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromRight;
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
    if (_isLiveMode == 1) {
        [self PushLiveStreamOff];
        [[NSNotificationCenter defaultCenter]  postNotificationName:NotificationUpdateTab object:[NSString stringWithFormat:@"%ld", (long)_itemTag]];
    }else {
        
    }

}

- (IBAction)recButClick:(id)sender
{
    BOOL isLiving = _startRec.selected;
    if (isLiving) {
        [_publisher unpublish];
        [self publishDidStop];
        [self setTip:nil];
        [_pushLiveStreamTimer invalidate];
        [self PushLiveStreamOff];
    } else {
        _startRec.enabled = NO;
        [self showIndicator];
        [_publisher publish];
    }
}

- (IBAction)showChatFiled:(id)sender
{
    [_inputField becomeFirstResponder];
}

- (IBAction)showShareView:(id)sender
{
//    _isHeartFlyView = NO;
    _tapGestureType = 1;
    [UIView animateWithDuration:0.3 animations:^{
        _shareView.y = ScreenHeight/2;
    } completion:nil];
}

- (IBAction)showLiWu:(id)sender
{
    _tapGestureType = 2;
    [UIView animateWithDuration:0.3 animations:^{
        _presentView.y = ScreenHeight-150;
    } completion:nil];
}

- (IBAction)cameraClick:(id)sender
{
    [_publisher toggleCamera];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (IBAction)whitenClick:(UIButton *)sender
{
    BOOL selected =  sender.selected = !sender.selected;
    if (selected) {
        [_whitenBut setImage:[UIImage imageNamed:@"meibai_on"] forState:UIControlStateNormal];
        _publisher.filter = _smoothSkinFilter;
    }else {
        [_whitenBut setImage:[UIImage imageNamed:@"meibai_off"] forState:UIControlStateNormal];
        _publisher.filter = nil;
    }
}

#pragma mark - textField代理


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    
    [textField resignFirstResponder];
    if (textField.text.length>0) {
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
        [params setObject:AppDelegateInstance.userInfo.userName forKey:@"account"];
        [params setObject:@"1"  forKey:@"msgid"];
        [params setObject:_nickName  forKey:@"nickname"];
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:1];
        [data setObject:textField.text forKey:@"msg"];
        [params setObject:data  forKey:@"data"];
        NSError *parseError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
        NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self sendClick:textField.text json:sssss];
    }else {
        
    }
    textField.text = @"";
    return  YES;
}


#pragma mark - 聊天回调


- (void)chatClient:(GLChatSession *)chatSession didReceiveMessage:(GLChatMessage *)msg
{
    if (msg.type == GLChatMessageTypeNotify && [msg.text isEqualToString:@"enter"]) {
        [self updateRoomUserCount];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
        [params setObject:@"0"  forKey:@"msgid"];
        [params setObject:msg.sendName  forKey:@"nickname"];
        NSError *parseError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
        NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [_messageArrays addObject:sssss];
        [_chatTableView reloadData];
        [_chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messageArrays.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    } else {
        NSData *da= [msg.text dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:da options:NSJSONReadingMutableContainers error:&error];
        if ([jsonObject isKindOfClass:[NSDictionary class]]){
            
            NSDictionary *dictionary = (NSDictionary *)jsonObject;
            NSString *msgid = [dictionary objectForKey:@"msgid"];
            if ([msgid intValue] == 1) {
                NSDictionary *data = [dictionary objectForKey:@"data"];
                NSString *msgText = [data objectForKey:@"msg"];
                [self showPopSubtitle:msgText nickName:msg.sendName];
                [_messageArrays addObject:msg.text];
                [_chatTableView reloadData];
                [_chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messageArrays.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }else if ([msgid intValue] == 2) {
                DMHeartFlyView* heart = [[DMHeartFlyView alloc]initWithFrame:CGRectMake(0, 0, 36, 36)];
                [_chatSuperView addSubview:heart];
                CGPoint fountainSource = CGPointMake(200, self.view.bounds.size.height - 36/2.0 - 10);
                heart.center = fountainSource;
                [heart animateInView:_chatSuperView];
            }else if ([msgid intValue] == 3) {
                NSDictionary *data = [dictionary objectForKey:@"data"];
                NSString *eventid = [data objectForKey:@"eventid"];
                if ([eventid intValue] == 1) {
                    [self showMyPresent:msg.sendName imageName:@"a-flowers" inter:1];
                }else if ([eventid intValue] == 2) {
                    [self showMyPresent:msg.sendName imageName:@"a-masonry" inter:2];
                }else if ([eventid intValue] == 3) {
                    [self showMyPresent:msg.sendName imageName:@"a-more-flowers" inter:3];
                }else {
                    [self showMyPresent:msg.sendName imageName:@"a-Sports-car" inter:4];
                }
                [_messageArrays addObject:msg.text];
                [_chatTableView reloadData];
                [_chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messageArrays.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }else {
                
            }
        }else {
            
        }
    }
}

- (void)chatClientDidForceLogout:(NSString *)roomId;
{
    [self forceLogout];
}

#pragma mark - 视频播放回调

- (void)playerDidConnect:(GLPlayer *)player;
{
    _player.playerView.backgroundColor = [UIColor blackColor];
    [self hideIndicator];
    [self setTip:nil];
    [self updateRoomUserCount];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES] ;
}

- (void)playerReconnecting:(GLPlayer *)player;
{
    NSLog(@"playerReconnecting");
    [self setTip:@"重新连线中..."];
    [self showIndicator];
}

- (void)playerDidDisconnected:(GLPlayer *)player
{
    NSLog(@"playerDidDisconnected");
    [self setTip:@"直播已结束！"];
    [self hideIndicator];
}

- (void)playerStatusDidUpdate:(GLPlayer *)player
{

}


- (void)player:(GLPlayer *)player onError:(NSError *)error;
{
    NSLog(@"playerOnError: %@ ", error);
    
    [self hideIndicator];
    [self setTip:error.localizedDescription];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
}

#pragma mark - 视频直播回调

- (void)publisherDidConnect:(GLPublisher *)publisher;
{
    _startRec.enabled = YES;
    _startRec.selected = YES;
    [_startRec setImage:[UIImage imageNamed:@"btn_stop"] forState:UIControlStateNormal];
    _timeLabel.hidden = NO;

    [_publisher beginRecording];
    [self startPublishTimer];
    [self hideIndicator];
    [self setTip:nil];
    [self updateRoomUserCount];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES] ;
    
    _pushLiveStreamTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(PushLiveStream) userInfo:nil repeats:YES];
    [_pushLiveStreamTimer fire];
}

- (void)publisher:(GLPublisher *)publisher onError:(NSError *)error;
{
    [self publishDidStop];
    [self hideIndicator];
    [self setTip:error.localizedDescription];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
}

- (void)publisherReconnecting:(GLPublisher *)publisher;
{
    [self setTip:@"重新连线中..."];
    [self showIndicator];
}

- (void)publisherDidForceLogout:(GLRoomPublisher *)publisher;
{
    [self publishDidStop];
    [self forceLogout];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
}

- (void)publisherDidDisconnected:(GLPublisher *)publisher;
{
    [self publishDidStop];
    [self setTip:nil];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
}


//与服务器交互
- (void)PushLiveStream
{
    int romId = [_roomId intValue];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:@(romId) forKey:@"liveRoomId"];
    [parameters setObject:@(1) forKey:@"status"];
    [parameters setObject:@(60) forKey:@"timeout"];
    
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [_requestClient postddByByUrlPath:@"/live/PushLiveStream" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
            return;
        }
        
        NSDictionary *dics = back;
        NSLog(@"====%@", dics);
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            
        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    [self PushLiveStream];
                }
            }];
            
        }else {
            
        }
    }];
    
}

- (void)PushLiveStreamOff
{
    int romId = [_roomId intValue];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:@(romId) forKey:@"liveRoomId"];
    [parameters setObject:@(0) forKey:@"status"];
    [parameters setObject:@(60) forKey:@"timeout"];
    
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [_requestClient postddByByUrlPath:@"/live/PushLiveStream" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
            return;
        }
        
        NSDictionary *dics = back;
        NSLog(@"%@", dics);
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            
        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    [self PushLiveStreamOff];
                }
            }];
        }else {
            
        }
    }];
    
}

- (void)updataRoomNum
{
    int romId = [_roomId intValue];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:@(romId) forKey:@"liveRoomId"];
    
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [_requestClient postddByByUrlPath:@"/live/GetLiveroomNumber" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
            return;
        }
        
        NSDictionary *dics = back;
        NSLog(@"%@", dics);
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            
            NSString *num = [NSString jsonUtils:[dics objectForKey:@"number"]];
            [self setTip:[NSString stringWithFormat:@"观看人数: %@", num]];
            
        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    [self updataRoomNum];
                }
            }];
            
        }else {
            
        }
    }];
    
}

- (void)payQinCoin:(NSInteger)qinCoin
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:@(qinCoin) forKey:@"qinCoin"];
    [parameters setObject:@(0) forKey:@"anchorAccount"];
    
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [_requestClient postddByByUrlPath:@"/pay/PayQinCoin" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
            return;
        }
        
        NSDictionary *dics = back;
        NSLog(@"%@", dics);
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            [self getMyPayInfo];
        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    [self payQinCoin:qinCoin];
                }
            }];
        }else if (result_type  == 10401) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:[NSString jsonUtils:[dics objectForKey:@"status"]] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
            return;
        }else {
            
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
            [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
            return;
        }
        
        NSDictionary *dics = back;
        NSLog(@"---%@", dics);
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            
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


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
//    NSLog(@"-----%@",touch.view.class);
    if (touch.view == _presentView) {
        return NO;
    }
    return YES;
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
        view = _chatSuperView;
    }else {
        view = [[UIView alloc] initWithFrame:carousel.bounds];
        
        UIButton *function = [UIButton buttonWithType:UIButtonTypeCustom];
        function.frame = CGRectMake((ScreenWidth-60), 20, 50, 50);
        function.backgroundColor = [UIColor clearColor];
        [function addTarget:self action:@selector(closeClick:) forControlEvents:UIControlEventTouchUpInside];
        [function setImage:[UIImage imageNamed:@"btn-close-2"] forState:UIControlStateNormal];
        [view addSubview:function];
        
    }
    view.backgroundColor = [UIColor clearColor];
    
    
    return view;
}

- (void)carouselDidScroll:(iCarousel *)carousel
{
    
}

- (void)carouselDidEndScrollingAnimation:(iCarousel *)carousel
{
    
}

- (void)dealloc
{
    [_presentView removeFromSuperview];
    [_shareView removeFromSuperview];
    [_messageArrays removeAllObjects];
    [_chatTableView removeFromSuperview];
    dispatch_source_cancel(_timer);
    [[NSNotificationCenter defaultCenter]removeObserver:self];
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
    return _messageArrays.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //每个单元格的视图
    static NSString *itemCell = @"MessageCell";
    MessageCell *cell = [tableView dequeueReusableCellWithIdentifier:itemCell];
    if (cell == nil) {
        cell = [[MessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemCell];
    }
    cell.backgroundColor = [UIColor clearColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;  
    NSString *obj = _messageArrays[indexPath.row];
    [cell fillCellWithObject:obj Width:_chatTableView.width];
    
    return cell;
}


@end
