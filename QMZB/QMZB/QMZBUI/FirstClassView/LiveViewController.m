//
//  LiveViewController.m
//  QMZB
//
//  Created by 刘淦 on 5/5/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import "LiveViewController.h"
#import "FXBlurView.h"
#import "GLPlayer.h"
#import "GLCore.h"
#import "UIView+Extension.h"
#import "GLPublisher.h"
#import "GLPublisherDelegate.h"
#import "GLPlayerView.h"
#import "GLPublisherDelegate.h"
#import "GLChatObserver.h"
#import "GLChatSession.h"
#import "GLRoomPlayer.h"
#import "GLRoomPublisher.h"
#import "QMZBNetwork.h"
#import "QMZBUIUtil.h"
#import "MBProgressHUD.h"
#import "SettingMenuView.h"
#import "NSString+Extension.h"
#import "DMHeartFlyView.h"
#import "MessageCell.h"
#import "GiftView.h"
#import "NumView.h"
#import "WXApiObject.h"
#import "WXApi.h"
#import "GLClientUrl.h"
#import "WeiboSDK.h"
#import "UIImageView+WebCache.h"
#import "QMZBLiveListModel.h"
#import "GLRoomPublisherDelegate.h"
#import "CollectionViewCellRoomMember.h"

@interface LiveViewController ()<GLPlayerDelegate,GLRoomPlayerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, GLRoomPublisherDelegate, UITextFieldDelegate, GLChatObserver>

@property (nonatomic,copy)GLRoomPublisher *publisher;

@property (nonatomic,copy)GLPlayer *player;

@property (nonatomic,copy)GLChatSession *chatKit;

@property (nonatomic,copy)GLRoomSession * session;

@property(nonatomic ,strong) QMZBNetwork *requestClient;


@end

@implementation LiveViewController
{
    NSMutableArray *_messageArrays;
    dispatch_source_t _timer;//定时获取了聊天室人数
    NSTimer *_pushLiveStreamTimer;
    GLSmoothSkinFilter *_smoothSkinFilter;

    NSInteger userCount, heartType;
    
    BOOL inited;
    IBOutlet UIImageView *imageViewPrev, *imageViewCurrent, *imageViewNext;
    IBOutlet UITableView *_chatTableView;
    IBOutlet UILabel *labelUserCount;
    IBOutlet UITextField *textFieldMessage;
    IBOutlet UICollectionView *collectionViewMembers;
    IBOutlet UIScrollView *scrollViewInteractive, *scrollViewMain;
    IBOutlet FXBlurView *blurView, *blurViewTop, *blurViewBottom, *blurViewBack;
    IBOutlet UIButton *buttonVideoBack, *buttonMusic, *buttonSettings, *buttonSend, *buttonExit;
    IBOutlet UIImageView *imageViewAvatarLive, *imageViewbackground;
    IBOutlet GLPlayerView *viewPlayer;
    IBOutlet SettingMenuView *viewMenu;
    IBOutlet UIView *viewPreview, *viewInteractive, *viewPresenter, *viewToolPanel, *viewEdit, *viewSharePanel, *viewPlayerLayer;
    IBOutlet UIView *viewTop, *viewBottom, *viewCurrent, *viewMain, *viewSettingShade;
    IBOutlet UIView *viewWeibo, *viewWeixin, *viewTimeline, *viewQQ, *viewQZone, *viewGift;
}

- (BOOL)prefersStatusBarHidden
{
    // iOS7后,[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    // 已经不起作用了
    return YES;
}

- (void)viewDidLoad {
        [super viewDidLoad];
    
        //scrollViewMain.alpha = 0.f;
        _chatTableView.hidden = YES;
        userCount = 0;
        vf(self.view) = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        _messageArrays = [NSMutableArray arrayWithCapacity: 0];

        [[self navigationController] setNavigationBarHidden:YES animated:NO];
        // Do any additional setup after loading the view from its nib.
        [collectionViewMembers registerNib:[UINib nibWithNibName:@"CollectionViewCellRoomMember" bundle:nil] forCellWithReuseIdentifier: @"CollectionViewCellRoomMember"];
        blurView.blurRadius = 15;
        blurViewTop.blurRadius = 15;
        blurViewBack.blurRadius = 15;
        blurViewBottom.blurRadius = 15;
        MakeCornerRound(buttonSend, 5);
        MakeCornerRound(viewPresenter, vh(viewPresenter) / 2);
        MakeCornerRound(imageViewAvatarLive, vh(imageViewAvatarLive) / 2);
        
        [self initScrollViewMain];
        [self initScrollViewInteractive];
        [self updateBackgroundImages: YES];
        _session = [GLCore sessionWithType:GLRoomSessionTypeDefault roomId:_roomId password:_password nickname:_nickName bindAccount:AppDelegateInstance.userInfo.userName];
        _chatKit = [[GLChatSession alloc] initWithSession:_session];

        [_chatKit addObserver:self];

        if(self.isLiveMode){
            [self initPublisher];
        }else{
            [self initPlayer];
        }
        
        [hud hide:YES];
        
        [_session authOnSuccess:^(GLAuthToken *authToken) {
            if (authToken.role == GLAuthTokenRolePresenter) {
                
                
                [self _loginPublisherWithForce:NO callback:^(NSError *error) {
                    
                    if (!error) {
                        [self _enterChatRoomWithRoomId:_roomId password:_password callback:^(NSError *error, NSString *account, NSString *nickname) {
                            if (error) {
                                //[self hud:hud showError:error.localizedDescription];
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



- (void)updateBackgroundImages:(BOOL)updateCurrent
{
    if(self.isLiveMode || !_curItem || !_playlist){
        return;
    }
    
//    imageViewNext.hidden = YES;
//    imageViewPrev.hidden = YES;
//    imageViewCurrent.hidden = YES;
//    blurView.hidden = YES;
//    blurViewTop.hidden = YES;
//    blurViewBottom.hidden = YES;
    
    QMZBLiveListModel *_listModel = _curItem;
    if ([_listModel.anchorIcon intValue]==0) {
        imageViewAvatarLive.image = [UIImage imageNamed:@"load"];
    }else {
        [imageViewAvatarLive setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
        [imageViewCurrent setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
    }

    NSInteger prev, next;
    NSInteger curIndex = [self.playlist indexOfObject: self.curItem];

    if(curIndex > 0){
            prev = curIndex - 1;
        }else{
            prev = self.playlist.count - 1;
        }

    if(curIndex < self.playlist.count - 1){
            next = curIndex + 1;
    }else{
            next = 0;
    }

    _listModel = self.playlist[prev];
    if ([_listModel.anchorIcon intValue]!=0) {
        [imageViewPrev setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
    }
    
    _listModel = self.playlist[next];
    if ([_listModel.anchorIcon intValue]!=0) {
        [imageViewNext setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
    }
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

- (void)updateRoomUserCount
{
    [_chatKit.roomSession getLiveContextOnSuccess:^(GLLiveContext *liveContext) {
        if (_player.state == GLPlayerStateStarted || _publisher.state == GLPublisherStatePublished) {
            userCount = liveContext.playUserCount;
            [collectionViewMembers reloadData];
            labelUserCount.text = [NSString stringWithFormat:@"%ld", (long)liveContext.playUserCount];
        }
        
    } failure:^(NSError *error) {
        NSLog(@"getLiveContext %@", error);
    }];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillhide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillshow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)initPublisher
{
    viewMenu = [[SettingMenuView alloc] init];
    CGRect frame = vf(viewSettingShade);
    viewMenu.frame = frame;
    [viewInteractive addSubview: viewMenu];
    viewMenu.hidden = YES;
    [self attachLiveMenuEvent];

    viewPlayer.hidden = YES;
    viewPreview.hidden = NO;
    [buttonMusic setImage:[UIImage imageNamed:@"icon_live_music"] forState: UIControlStateNormal];
    [buttonSettings setImage:[UIImage imageNamed:@"icon_live_settings"] forState: UIControlStateNormal];
    
    _publisher = [[GLRoomPublisher alloc] initWithSession:_session];
    
    GLPublisherVideoPreset *preset = [GLPublisherVideoPreset
                                      presetWithResolution:GLPublisherVideoResolutionCustom];
    preset.videoSize = CGSizeMake(368, 640);
    preset.fps = 24;
    preset.bps = 720;
    _publisher.videoPreset = preset;
    _publisher.delegate = self;
    _smoothSkinFilter = [GLSmoothSkinFilter new];
    _smoothSkinFilter.factor = 10.99f;
    _publisher.filter = _smoothSkinFilter;
    
    [_publisher startPreview:viewPreview success:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_publisher publish];
        });
    } failure:^(NSError *error) {
    }];
}

- (void)attachLiveMenuEvent
{
    [viewMenu.buttonShare addTarget:self action:@selector(onButtonMenuClick:) forControlEvents:UIControlEventTouchUpInside];
    [viewMenu.buttonLampSwitch addTarget:self action:@selector(onButtonMenuClick:) forControlEvents:UIControlEventTouchUpInside];
    [viewMenu.buttonCameraSwitch addTarget:self action:@selector(onButtonMenuClick:) forControlEvents:UIControlEventTouchUpInside];
    [viewMenu.buttonMagic addTarget:self action:@selector(onButtonMenuClick:) forControlEvents:UIControlEventTouchUpInside];
    [viewMenu.buttonLayer1 addTarget:self action:@selector(onButtonMenuClick:) forControlEvents:UIControlEventTouchUpInside];
    [viewMenu.buttonLayer2 addTarget:self action:@selector(onButtonMenuClick:) forControlEvents:UIControlEventTouchUpInside];
    [viewMenu.buttonLayer3 addTarget:self action:@selector(onButtonMenuClick:) forControlEvents:UIControlEventTouchUpInside];
    [viewMenu.buttonLayer4 addTarget:self action:@selector(onButtonMenuClick:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)initPlayer
{
    _player = [[GLPlayer alloc] initWithUrl:_playUrl];
    GLRoomSession *sess = [[GLRoomSession alloc] initWithType:GLRoomSessionTypeDefault roomId:_roomId password:_password nickname:_nickName bindAccount:nil];
    _player.roomSession = sess;
    _player.delegate = self;
    
    viewPlayer = [[GLPlayerView alloc] initWithFrame: vf(viewPlayerLayer)];
    viewPlayer.backgroundColor = [UIColor clearColor];
    [viewPlayerLayer addSubview: viewPlayer];
    viewPlayer.fillMode = GLPlayerViewFillModeAspectFill;
    [_player playWithView:viewPlayer];
}

- (void)initScrollViewInteractive
{
    CGSize size = CGSizeMake(2 * kScreenWidth, kScreenHeight);
    scrollViewInteractive.contentSize = size;
    CGRect frame = vf(viewInteractive);
    fx(frame) = kScreenWidth;
    vf(viewInteractive) = frame;
    CGPoint offset = CGPointMake(kScreenWidth, 0);
    scrollViewInteractive.contentOffset = offset;
}

- (void)initScrollViewMain
{
    scrollViewMain.delegate = self;
    CGSize size = CGSizeMake(kScreenWidth, 3 * kScreenHeight);
    scrollViewMain.contentSize = size;
    CGRect frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    vf(viewTop) = frame;
    fy(frame) += kScreenHeight;
    vf(viewCurrent) = frame;
    fy(frame) += kScreenHeight;
    vf(viewBottom) = frame;
    scrollViewMain.contentOffset = CGPointMake(0, kScreenHeight);
    if(self.isLiveMode){
        scrollViewMain.scrollEnabled = NO;
    }
}

- (void)updateScrollViewMain
{
    
}

- (void)keyboardWillshow:(NSNotification *)note
{
    NSDictionary *userInfo = note.userInfo;
    CGRect keyFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect frame = vf(viewInteractive);
    if(fy(frame) == - fh(keyFrame)){
        return;
    }
    
    beginAnimation(0, .3f, UIViewAnimationCurveEaseOut);
    frame = vf(viewInteractive);
    fy(frame) =  - fh(keyFrame);
    vf(viewInteractive) = frame;
    endAnimation;
}

- (void)keyboardWillhide:(NSNotification *)note
{
    //NSDictionary *userInfo = note.userInfo;
    //CGRect keyFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    viewEdit.hidden = YES;
    viewToolPanel.hidden = NO;
    
    beginAnimation(0, .3f, UIViewAnimationCurveEaseOut);
    
    CGRect frame = vf(viewInteractive);
    fy(frame) = 0;
    vf(viewInteractive) = frame;
    
    endAnimation;
}

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


- (IBAction)functionBtnClick:(UIButton *)button
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
            case 1003:
            case 1004:
            {
                UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"提示" message:@"目前只支持微博，微信，朋友圈分享功能"
                                                              delegate: nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
                [view show];
            }
                break;
            default:
                break;
        }
    } failure:^(NSError *error) {
        
    }];
    
    
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
                //[self showPopSubtitle:msgText nickName:AppDelegateInstance.userInfo.nickName];
                [_messageArrays addObject:json];
                _chatTableView.hidden = NO;
                [_chatTableView reloadData];
                NSLog(@"------");
                [_chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messageArrays.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];

            }else if ([msgid intValue] == 2) {
                NSString *nic = [dictionary objectForKey:@"nickname"];
                if ([nic isEqualToString:AppDelegateInstance.userInfo.nickName]) {
                    NSDictionary *data = [dictionary objectForKey:@"data"];
                    int index = [[data objectForKey:@"eventid"] intValue];
                    DMHeartFlyView* heart = [[DMHeartFlyView alloc]initWithFrame:CGRectMake(0, 0, kWidthHeart, kWidthHeart) index: index];
                    [viewInteractive addSubview:heart];
                    CGPoint fountainSource = buttonSettings.center;
                    fountainSource.y = buttonSettings.y + buttonSettings.superview.frame.origin.y;
                    heart.center = fountainSource;
                    [heart animateInView:viewInteractive];
                }else {
                    
                }
                
            }else if ([msgid intValue] == 3) {
                //[_messageArrays addObject:json];

                NSDictionary *data = [dictionary objectForKey:@"data"];
                NSString *eventid = [data objectForKey:@"eventid"];
                [self showGiftView:[eventid integerValue] - 1 nickname: AppDelegateInstance.userInfo.nickName];
                if ([eventid intValue] == 1) {
                    //[self showMyPresent:AppDelegateInstance.userInfo.nickName imageName:@"a-flowers" inter:1];
                }else if ([eventid intValue] == 2) {
                    //[self showMyPresent:AppDelegateInstance.userInfo.nickName imageName:@"a-masonry" inter:2];
                }else if ([eventid intValue] == 3) {
                    //[self showMyPresent:AppDelegateInstance.userInfo.nickName imageName:@"a-more-flowers" inter:3];
                }else {
                    //[self showMyPresent:AppDelegateInstance.userInfo.nickName imageName:@"a-Sports-car" inter:4];
                }
            }else {
                
            }
        }else {
            
        }
        //        }else {
        //
        //        }
    } failure:^(NSError *error) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"发送失败" message:@"网络异常" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//        [alert show];
//        [self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
    }];
}
#pragma mark - 送礼物动画
- (void)showGiftView:(NSInteger)index nickname:(NSString*)nickname
{
    if(index < 0 || index > 3) index = 0;
    NSArray *list = @[@"a-flowers", @"a-masonry", @"a-more-flowers", @"a-Sports-car"];
    GiftView *giftView = [[GiftView alloc] init];
    giftView.imageViewGift.image = [UIImage imageNamed:list[index]];
    giftView.labelNickname.text = nickname;
    if(index == 1){
        giftView.labelAction.text = @"送一颗钻石";
    }else if(index == 3){
        giftView.labelAction.text = @"送一辆跑车";
    }
    
    [viewInteractive addSubview: giftView];
    CGRect frame = vf(giftView);
    fx(frame) = -vw(giftView);
    fy(frame) = (kScreenHeight - vh(giftView)) / 2;
    vf(giftView) = frame;
    
    beginAnimation(0, .2f, UIViewAnimationCurveEaseOut);
    fx(frame) = 8;
    vf(giftView) = frame;
    [UIView setAnimationDelegate: giftView];
    [UIView setAnimationDidStopSelector: @selector(addNumView)];
        
    endAnimation;
    
    beginAnimation(5.f, .5f, UIViewAnimationCurveEaseIn);
    frame = vf(giftView);
    fy(frame) = fy(frame) / 2;
    giftView.frame = frame;
    giftView.alpha = 0.f;
    [UIView setAnimationDelegate: giftView];
    [UIView setAnimationDidStopSelector: @selector(onGiftViewDisappear)];
    endAnimation;
}

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
        _chatTableView.hidden = NO;
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
                //[self showPopSubtitle:msgText nickName:msg.sendName];
                [_messageArrays addObject:msg.text];
                _chatTableView.hidden = NO;
                [_chatTableView reloadData];
                [_chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messageArrays.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }else if ([msgid intValue] == 2) {
                NSDictionary *data = [dictionary objectForKey:@"data"];
                int index = [[data objectForKey:@"eventid"] intValue];
                DMHeartFlyView* heart = [[DMHeartFlyView alloc]initWithFrame:CGRectMake(0, 0, kWidthHeart, kWidthHeart) index: index];
                [viewInteractive addSubview:heart];
                CGPoint fountainSource = buttonSettings.center;
                fountainSource.y = buttonSettings.y + buttonSettings.superview.frame.origin.y;
                heart.center = fountainSource;
                [heart animateInView:viewInteractive];
            }else if ([msgid intValue] == 3) {
                NSDictionary *data = [dictionary objectForKey:@"data"];
                NSString *eventid = [data objectForKey:@"eventid"];
                
                [self showGiftView:[eventid integerValue] - 1 nickname: AppDelegateInstance.userInfo.nickName];

                if ([eventid intValue] == 1) {
                    //[self showMyPresent:msg.sendName imageName:@"a-flowers" inter:1];
                }else if ([eventid intValue] == 2) {
                    //[self showMyPresent:msg.sendName imageName:@"a-masonry" inter:2];
                }else if ([eventid intValue] == 3) {
                    //[self showMyPresent:msg.sendName imageName:@"a-more-flowers" inter:3];
                }else {
                    //[self showMyPresent:msg.sendName imageName:@"a-Sports-car" inter:4];
                }
                [_messageArrays addObject:msg.text];
                _chatTableView.hidden = NO;
                [_chatTableView reloadData];
                [_chatTableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messageArrays.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
            }else {
                
            }
        }else {
            
        }
    }
}


- (void) dimissAlert:(UIAlertView *)alert
{
    if(alert) {
        
        [alert dismissWithClickedButtonIndex:[alert cancelButtonIndex] animated:YES];
    }
}



- (IBAction)onButtonVideoClick:(id)sender
{
    buttonExit.hidden = NO;
    viewToolPanel.hidden = NO;

    if(!self.isLiveMode && !viewGift.hidden){
        beginAnimation(0, .3f,  UIViewAnimationCurveEaseIn);
        CGRect frame = vf(viewGift);
        fy(frame) = kScreenHeight;
        viewGift.alpha = 0.f;
        vf(viewGift) = frame;
        [UIView setAnimationDelegate: self];
        [UIView setAnimationDidStopSelector: @selector(onAnimationViewGiftEnd)];
        
        viewToolPanel.alpha = 1.f;
        frame = vf(viewToolPanel);
        fy(frame) = kScreenHeight - fh(viewToolPanel);
        vf(viewToolPanel) = frame;
        
        endAnimation;
    }
    
    [self closeMenu];
    if(textFieldMessage.isFirstResponder){
        [textFieldMessage resignFirstResponder];
    }
    
    if(!viewSharePanel.hidden){
        buttonExit.hidden = NO;
        beginAnimation(0, .3f, UIViewAnimationCurveEaseOut);
        viewSharePanel.alpha = 0.f;
        [UIView setAnimationDelegate: self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStop)];
        endAnimation;
    }
    
    if (!self.isLiveMode) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
        [params setObject:AppDelegateInstance.userInfo.userName forKey:@"account"];
        [params setObject:@"2"  forKey:@"msgid"];
        [params setObject:_nickName  forKey:@"nickname"];
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:1];
        heartType = arc4random() % 8;
        [data setObject:@(heartType)  forKey:@"eventid"];
        [params setObject:data  forKey:@"data"];
        NSError *parseError = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
        NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [self sendClick:@"" json:sssss];
    }
}

- (void)onAnimationViewGiftEnd
{
    viewGift.hidden = YES;
}

- (void)animationDidStop
{
    viewSharePanel.hidden = YES;
}

- (IBAction)onButtonExitClick:(id)sender
{
    [_player stop];
    [_publisher stop];
    [_chatKit logout];
    [_pushLiveStreamTimer invalidate];
    _pushLiveStreamTimer = nil;
    if (_timer) {
        
        dispatch_source_cancel(_timer);
    }

    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.3;
    animation.timingFunction = UIViewAnimationCurveEaseInOut;
    animation.type = kCATransitionPush;
    animation.subtype = kCATransitionFromLeft;
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
    if (_isLiveMode == 1) {
        [self PushLiveStreamOff];
        [[NSNotificationCenter defaultCenter]  postNotificationName:NotificationUpdateTab object:[NSString stringWithFormat:@"%ld", (long)_itemTag]];
    }else {
        
    }
}

- (IBAction)onButtonSendClick:(id)sender
{
    [self textFieldShouldReturn: textFieldMessage];
}

- (IBAction)onButtonEditClick:(id)sender
{
    [self closeMenu];
    viewEdit.hidden = NO;
    viewToolPanel.hidden = YES;
    [textFieldMessage becomeFirstResponder];
}

- (IBAction)onButtonSettingsClick:(id)sender
{
    if(self.isLiveMode){
        if(viewMenu.hidden){
            viewMenu.alpha = .0f;
            viewMenu.hidden = NO;
            beginAnimation(0, .2f, UIViewAnimationCurveEaseOut);
            viewMenu.alpha = 1.f;
            viewMenu.frame = viewSettingShade.frame;
            viewMenu.labelLampSwitch.text = self.publisher.torchOn?@"关闪光":@"开闪光";
            viewMenu.labelMagic.text = self.publisher.filter?@"关美颜":@"开美颜";

            endAnimation;
        }else{
            [self closeMenu];
        }
    }else{
        viewGift.alpha = 0.f;
        viewGift.hidden = NO;
        buttonExit.hidden = YES;
        
        CGRect frame = vf(viewGift);
        fy(frame) = kScreenHeight;
        vf(viewGift) = frame;
        
        beginAnimation(0, .3f,  UIViewAnimationCurveEaseOut);
        frame = vf(viewGift);
        fy(frame) -= fh(frame);
        viewGift.alpha = 1.f;
        vf(viewGift) = frame;
        
        frame = vf(viewToolPanel);
        fy(frame) = kScreenHeight;
        vf(viewToolPanel) = frame;
        viewToolPanel.alpha = 0.f;
        [UIView setAnimationDelegate: self];
        [UIView setAnimationDidStopSelector:@selector(onAnimationShowGiftStop)];

        endAnimation;
    }
}

- (IBAction)onButtonGiftClick:(id)sender
{
    UIButton *button = sender;
    if(!self.isLiveMode && !viewGift.hidden){
        beginAnimation(0, .3f,  UIViewAnimationCurveEaseIn);
        CGRect frame = vf(viewGift);
        fy(frame) = kScreenHeight;
        viewGift.alpha = 0.f;
        vf(viewGift) = frame;
        [UIView setAnimationDelegate: self];
        [UIView setAnimationDidStopSelector: @selector(onAnimationViewGiftEnd)];
        
        buttonExit.hidden = NO;
        viewToolPanel.hidden = NO;
        viewToolPanel.alpha = 1.f;
        frame = vf(viewToolPanel);
        fy(frame) = kScreenHeight - fh(viewToolPanel);
        vf(viewToolPanel) = frame;
        
        endAnimation;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:4];
    [params setObject:AppDelegateInstance.userInfo.userName forKey:@"account"];
    [params setObject:@"3"  forKey:@"msgid"];
    [params setObject:_nickName  forKey:@"nickname"];
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithCapacity:1];
    [data setObject:@([button tag])  forKey:@"eventid"];
    [params setObject:data  forKey:@"data"];
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&parseError];
    NSString *sssss = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [self sendClick:@"" json:sssss];
}


- (void)onAnimationShowGiftStop
{
    viewToolPanel.hidden = YES;
}

- (void)closeMenu
{
    if(!viewMenu || viewMenu.hidden)return;
    
    viewMenu.alpha = 1.f;
    beginAnimation(0, .2f, UIViewAnimationCurveEaseIn);
    [UIView setAnimationDelegate: self];
    [UIView setAnimationDidStopSelector:@selector(onAnimationSettingStop)];
    viewMenu.alpha = 0.f;
    CGRect frame = buttonSettings.frame;
    fy(frame) = vy(buttonSettings.superview);
    frame = CGRectInset(frame, fw(frame)/3.f, fw(frame)/3.f);
    
    viewMenu.frame = frame;
    endAnimation;

}

- (void)onAnimationSettingStop
{
    viewMenu.hidden = YES;
}

- (void)onButtonMenuClick:(id)sender
{
    UIButton *button = sender;
    if(!self.isLiveMode) return;
    
    switch ([button tag]) {
        case kTagShare:
        {
            
        }
            break;
            
        case kTagLamp:
        {
            self.publisher.torchOn = !self.publisher.torchOn;
            viewMenu.labelLampSwitch.text = self.publisher.torchOn?@"关闪光":@"开闪光";
        }
            break;
            
        case kTagSwitch:
        {
            [self.publisher toggleCamera];
        }
            break;
            
        case kTagOptimize:
        {
            if(self.publisher.filter){
                self.publisher.filter = nil;
            }else{
                self.publisher.filter = _smoothSkinFilter;
            }
            
            viewMenu.labelMagic.text = self.publisher.filter?@"关美颜":@"开美颜";

        }
            break;
            
        default:
            break;
    }
}


- (IBAction)onButtonShareClick:(id)sender
{
    if(!self.isLiveMode){
        buttonExit.hidden = YES;
        viewSharePanel.alpha = 0.f;
        viewSharePanel.hidden = NO;
        
        beginAnimation(0, .2f, UIViewAnimationCurveEaseOut);
        viewSharePanel.alpha = 1;
        endAnimation;
        
        NSArray *list = @[viewWeibo, viewWeixin, viewTimeline, viewQQ, viewQZone];
        
        for(int i = 0; i < 5; i++){
            UIView *view = list[i];
            CGRect frame = vf(view);
            fy(frame) += fh(frame);
            vf(view) = frame;
            beginAnimation(i * 0.03f, .18f, UIViewAnimationCurveEaseOut);
            fy(frame) -= fh(frame);
            vf(view) = frame;
            endAnimation;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//            [alert show];
            //[self performSelector:@selector(dimissAlert:) withObject:alert afterDelay:1.0];
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



#pragma mark - UICollectionViewDataSource&UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return userCount;
}

// 配置section中的collectionViewCell的显示
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectionViewCellRoomMember *cell = [CollectionViewCellRoomMember cellWithCollectionView:collectionView indexPath:indexPath];
    
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView == scrollViewMain){
        NSInteger curIndex = [self.playlist indexOfObject: self.curItem];
        if(scrollView.contentOffset.y > kScreenHeight){
            if(scrollView.tag != 1){
                if(curIndex < self.playlist.count - 1){
                    curIndex++;
                }else{
                    curIndex = 0;
                }
                
                QMZBLiveListModel *_listModel = self.playlist[curIndex];
                if ([_listModel.anchorIcon intValue]!=0) {
                    [imageViewbackground setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
                }
                NSLog(@"!!!!!!!!!!!!!!!!!!!!!!!");
                scrollView.tag = 1;
            }
        }else if(scrollView.contentOffset.y < kScreenHeight){
            if(scrollView.tag != 2){
                if(curIndex > 0){
                    curIndex--;
                }else{
                    curIndex = self.playlist.count - 1;
                }
                
                QMZBLiveListModel *_listModel = self.playlist[curIndex];
                if ([_listModel.anchorIcon intValue]!=0) {
                    [imageViewbackground setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
                }
                NSLog(@"iiiiiiiiiiiiiiiiiiiii");

                scrollView.tag = 2;
            }
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if(scrollView == scrollViewMain){
        CGPoint offset = scrollView.contentOffset;
        if(offset.y != kScreenHeight){
            BOOL prev = (offset.y == 0);
            
            NSInteger curIndex = [self.playlist indexOfObject: self.curItem];
            if(prev){
                if(curIndex > 0){
                    curIndex--;
                }else{
                    curIndex = self.playlist.count - 1;
                }
            }else{
                if(curIndex < self.playlist.count - 1){
                    curIndex++;
                }else{
                    curIndex = 0;
                }
            }
            
            scrollView.tag = 0;
//            QMZBLiveListModel *_listModel = self.playlist[curIndex];
//            if ([_listModel.anchorIcon intValue]!=0) {
//            [imageViewbackground setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
//            }
            
//            QMZBLiveListModel *_listModel = self.playlist[curIndex];
//            if ([_listModel.anchorIcon intValue]!=0) {
//                [imageViewCurrent setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
//                    [imageViewPrev setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
//                [imageViewNext setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,_listModel.anchorIcon]] placeholderImage:[UIImage imageNamed:@"load"]];
//            }
            //scrollViewMain.alpha = 0.f;
            viewMain.alpha = 0.0f;
            self.curItem = self.playlist[curIndex];

            [self updateBackgroundImages:NO];

            [scrollView setContentOffset: CGPointMake(0, kScreenHeight)];
            beginAnimation(0, .3f, UIViewAnimationCurveEaseOut);
            viewMain.alpha = 1.f;
            //scrollViewMain.alpha = 1.f;
            endAnimation;
            
            if(self.playlist.count == 1) return;
            

            viewPlayer.alpha = 0.f;
            [viewPlayer removeFromSuperview];
            viewPlayer = nil;
            _player.delegate = nil;
            [_player stop];
            [_chatKit logout];
            if (_timer) {
                dispatch_source_cancel(_timer);
            }
            
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            
            
//            self.curItem = self.playlist[curIndex];
//            [self updateBackgroundImages];

            QMZBLiveListModel *obj = self.curItem;
            
            self.roomId = obj.liveRoomId;
            self.password = obj.liveRoomUserPwd;
            self.playUrl = obj.playFlvUrl;

            userCount = 0;
            
            [_messageArrays removeAllObjects];
            _chatTableView.hidden = YES;
            [_chatTableView reloadData];
            
            _session = [GLCore sessionWithType:GLRoomSessionTypeDefault roomId:_roomId password:_password nickname:_nickName bindAccount:AppDelegateInstance.userInfo.userName];
            _chatKit = [[GLChatSession alloc] initWithSession:_session];
            
            [_chatKit addObserver:self];
            
            [self initPlayer];
            
            [_session authOnSuccess:^(GLAuthToken *authToken) {
                if (authToken.role == GLAuthTokenRolePresenter) {
                    
                    
                    [self _loginPublisherWithForce:NO callback:^(NSError *error) {
                        
                        if (!error) {
                            [self _enterChatRoomWithRoomId:_roomId password:_password callback:^(NSError *error, NSString *account, NSString *nickname) {
                                if (error) {
                                    //[self hud:hud showError:error.localizedDescription];
                                } else {
                                    
                                }
                            }];
                            return;
                        }
                    }];
                } else {
                    [self _enterChatRoomWithRoomId:_roomId password:_password callback:^(NSError *error, NSString *account, NSString *nickname) {
                        if (error) {
                        } else {
                            
                        }
                    }];
                }
                
                
            } failure:^(NSError *error) {
                NSLog(@"====%@",error.localizedDescription);
            }];
        }
                           
    }
                           
}

#pragma mark - GLRoomPublisherDelegate

- (void)publisherDidConnect:(GLPublisher *)publisher;
{
    [_publisher beginRecording];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES] ;
    
    _pushLiveStreamTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(PushLiveStream) userInfo:nil repeats:YES];
    [_pushLiveStreamTimer fire];
}

- (void)publisher:(GLPublisher *)publisher onError:(NSError *)error;
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
}

- (void)publisherReconnecting:(GLPublisher *)publisher;
{
}

- (void)publisherDidForceLogout:(GLRoomPublisher *)publisher;
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
}

- (void)publisherDidDisconnected:(GLPublisher *)publisher;
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
}

#pragma mark - 视频播放回调

- (void)playerDidConnect:(GLPlayer *)player;
{
    [self updateRoomUserCount];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES] ;
}

- (void)playerReconnecting:(GLPlayer *)player;
{
    NSLog(@"playerReconnecting");
}

- (void)playerDidDisconnected:(GLPlayer *)player
{
    NSLog(@"playerDidDisconnected");
}

- (void)playerStatusDidUpdate:(GLPlayer *)player
{
    
}


- (void)player:(GLPlayer *)player onError:(NSError *)error;
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO] ;
}

- (void)playerBuffering:(GLPlayer *)player
{
}

- (void)playerBufferCompleted:(GLPlayer *)player
{
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

- (CGFloat)mesureCellHeight:(NSIndexPath*)indexPath
{
    UITextView *textView = [[UITextView alloc] init];
     textView.frame = CGRectMake(0, 0, _chatTableView.width, 10);
    id obj = _messageArrays[indexPath.row];
    
    NSData *da= [obj dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:da options:NSJSONReadingMutableContainers error:&error];
    if ([jsonObject isKindOfClass:[NSDictionary class]]){
        NSMutableAttributedString *str;
        NSDictionary *dictionary = (NSDictionary *)jsonObject;
        NSString *msgid = [dictionary objectForKey:@"msgid"];
        NSString *nickName = [dictionary objectForKey:@"nickname"];
        
        if ([msgid intValue]==0) {
            str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:大家好!",nickName]];
        }else if ([msgid intValue]==1) {
            NSDictionary *data = [dictionary objectForKey:@"data"];
            NSString *msgText = [data objectForKey:@"msg"];
            str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:%@",nickName,msgText]];
        }else if ([msgid intValue]==2) {
            
        }else if ([msgid intValue]==3) {
            NSDictionary *data = [dictionary objectForKey:@"data"];
            NSString *eventid = [data objectForKey:@"eventid"];
            if ([eventid intValue] == 1) {
                str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:我送了一朵花!",nickName]];
            }else if ([eventid intValue] == 2) {
                str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:我送了一枚钻石!",nickName]];
            }else if ([eventid intValue] == 3) {
                str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:我送了一束花!",nickName]];
            }else {
                str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@:我送了一辆跑车!",nickName]];
            }
        }else {
            
        }
        if(str){
            [str addAttribute:NSFontAttributeName value:kMessageFont range:NSMakeRange(0, str.length)];
            textView.attributedText = str;
        }
    }
    
    CGSize size = textView.contentSize;
    return MAX(size.height, kNormalHeight);
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [self mesureCellHeight: indexPath];
    NSLog(@"actual height[%ld]: %f", indexPath.row, height);
    return height;
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
