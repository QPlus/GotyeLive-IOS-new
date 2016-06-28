//
//  QMZBSettingController.m
//  QuanMingZhiBo
//
//  Created by Jim on 16/3/16.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import "QMZBSettingController.h"
#import "QMZBUIUtil.h"
#import "QMZBContactController.h"
#import "QMZBMySettingController.h"
#import "QMZBRegisterChannelController.h"
#import "QMZBUserInfo.h"
#import "QMZBNetwork.h"
#import "MBProgressHUD.h"
#import "NSString+Extension.h"
#import "QMZBModifyLiveRoomController.h"
#import "QMZBTopUpController.h"
#import "QMZBSettingCollectionCell.h"

@interface QMZBSettingController ()<UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate,UIAlertViewDelegate,MBProgressHUDDelegate,UITableViewDelegate,UITableViewDataSource,UICollectionViewDataSource,UICollectionViewDelegate>
{
    UIButton *_myHeadImage;
    UILabel *_userNameLabel;
    UILabel *_explanationLabel;
    UIButton *_nickNameButton;
    UILabel *_nickNameLabel;

    BOOL _isLoading;
    MBProgressHUD *HUD;
    
    NSString *_nickName;
    
    UITableView *_tableView;
    
    NSString *_zhiboCount;//直播数量
    NSString *_userLevel;
    NSString *_jiaCoin;//收入加元
    NSString *_qinCoin;//剩余亲元

}

@property(nonatomic ,strong) QMZBNetwork *requestClient;

@property (nonatomic, strong) UIScrollView *scrollView;

@property (nonatomic, strong) UICollectionView *collectionView;

@end

@implementation QMZBSettingController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = WHITE_COLOR;

    [self initView];
    
    [self getMyPayInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSeccessNotification:) name:NotificationloginSeccess object:nil];
    [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(updateSelected:) name:NotificationUpdateTab object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeUserInfo:) name:NotificationchangeUserInfo object:nil];

    _zhiboCount = @"0";
    _userLevel = @"1";
    _jiaCoin = @"0";
    _qinCoin = @"0";
}



- (void)changeUserInfo:(NSNotification *)notification
{
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"currentImage.png"];
    UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
    if (img) {
        
        [_myHeadImage setBackgroundImage:img forState:UIControlStateNormal];
    }else {
        
    }
    _nickNameLabel.text = [NSString stringWithFormat:@"%@",AppDelegateInstance.userInfo.nickName];

}

- (void)loginSeccessNotification:(NSNotification *)notification
{
    if ([AppDelegateInstance.userInfo.headerpicId isEqualToString:@"0"]) {
        
    }else {
        
        [self getUserPic];
    }
    [self initView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [[self navigationController] setNavigationBarHidden:YES animated:NO];

}

-(void) updateSelected:(NSNotification *)notification
{
    NSString *itemIndex = (NSString *)[notification object];
    
    if ([itemIndex isEqualToString:@"102"]) {
        [[self navigationController] setNavigationBarHidden:YES animated:NO];
    }else {
        
    }
    
}

- (void)initView
{
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, -20, ScreenWidth, ScreenHeight)];
    _scrollView.bounces = NO;
    _scrollView.contentSize = CGSizeMake(ScreenWidth, 568);
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_scrollView];
    
    UIView *headerBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 220)];
    [_scrollView addSubview:headerBackground];
    
    UIImageView *header_bg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 220)];
//    header_bg.image = [UIImage imageNamed:@"header_bg"];
    header_bg.backgroundColor = COLOR(203, 133, 248, 1);
    [headerBackground addSubview:header_bg];
    
    
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"currentImage.png"];
    UIImage *img = [UIImage imageWithContentsOfFile:fullPath];
    if (img) {
        
    }else {
        
        img = [UIImage imageNamed:@"user_default_head"];
    }
    if ([AppDelegateInstance.userInfo.headerpicId isEqualToString:@"0"]) {
        img = [UIImage imageNamed:@"user_default_head"];
        [self saveImage:img withName:@"currentImage.png"];

    }else {
        
    }
    _myHeadImage = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth/2-35, 50, 70, 70)];
    _myHeadImage.tag = 201;
    [_myHeadImage setBackgroundImage:img forState:UIControlStateNormal];
    _myHeadImage.layer.masksToBounds = YES;
    _myHeadImage.layer.cornerRadius = _myHeadImage.bounds.size.width*0.5;
    _myHeadImage.layer.borderWidth = 2.0;
    _myHeadImage.layer.borderColor = [UIColor clearColor].CGColor;
    [_myHeadImage addTarget:self action:@selector(singleClick:) forControlEvents:UIControlEventTouchUpInside];
    [headerBackground addSubview:_myHeadImage];
    
    
    _nickNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_myHeadImage.frame)+5, ScreenWidth-20, 20)];
    _nickNameLabel.text = [NSString stringWithFormat:@"%@",AppDelegateInstance.userInfo.nickName];
    _nickNameLabel.font = [UIFont systemFontOfSize:18];
    _nickNameLabel.backgroundColor = [UIColor clearColor];
    _nickNameLabel.textAlignment = NSTextAlignmentCenter;
    _nickNameLabel.textColor = WHITE_COLOR;
    [headerBackground addSubview:_nickNameLabel];
    
    
    _userNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_nickNameLabel.frame)+5, ScreenWidth-20, 20)];
    _userNameLabel.text = [NSString stringWithFormat:@"红粉 %@ | 关注 %@",@"1234",@"5678"];
    _userNameLabel.font = [UIFont systemFontOfSize:13];
    _userNameLabel.backgroundColor = [UIColor clearColor];
    _userNameLabel.textColor = BACKGROUND_DARK_COLOR;
    _userNameLabel.textAlignment = NSTextAlignmentCenter;
    [headerBackground addSubview:_userNameLabel];
    
    _nickNameButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _nickNameButton.frame = CGRectMake(ScreenWidth-55, 15, 50, 40);
    _nickNameButton.backgroundColor = [UIColor clearColor];
    [_nickNameButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_nickNameButton setImage:[UIImage imageNamed:@"change_nickName"] forState:UIControlStateNormal];
    _nickNameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [headerBackground addSubview:_nickNameButton];
    _nickNameButton.tag = 202;
    [_nickNameButton addTarget:self action:@selector(singleClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _explanationLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_userNameLabel.frame)+5, ScreenWidth-20, 20)];
    _explanationLabel.text = [NSString stringWithFormat:@"世界那么大，我想去看看......"];
    _explanationLabel.font = [UIFont systemFontOfSize:13];
    _explanationLabel.backgroundColor = [UIColor clearColor];
    _explanationLabel.textColor = WHITE_COLOR;
    _explanationLabel.textAlignment = NSTextAlignmentCenter;
    [headerBackground addSubview:_explanationLabel];
    
    UICollectionViewFlowLayout *flowLayOut = [[UICollectionViewFlowLayout alloc] init];
    float item_width = ScreenWidth/2;
    float item_height = 100.0f;
    flowLayOut.minimumInteritemSpacing = 3;
    flowLayOut.minimumLineSpacing = 5;
    flowLayOut.itemSize = CGSizeMake(item_width-10 , item_height-5);
    // 移动方向的设置
    [flowLayOut setScrollDirection:UICollectionViewScrollDirectionVertical];
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(headerBackground.frame), ScreenWidth, 100.0f*2+5) collectionViewLayout:flowLayOut];
    _collectionView.backgroundColor = BACKGROUND_DARK_COLOR;
    _collectionView.scrollEnabled = NO;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    // 注册cell
    [_collectionView registerClass:[QMZBSettingCollectionCell class] forCellWithReuseIdentifier:@"SettingCollection_cell"];
    [_scrollView addSubview:_collectionView];

    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_collectionView.frame) , ScreenWidth-20, 150) style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.backgroundColor = BACKGROUND_DARK_COLOR;
    _tableView.delegate = self;
    _tableView.scrollEnabled = NO;
    [_scrollView addSubview:_tableView];
}

- (void)getUserPic
{
    
//    [_myHeadImage setBackgroundImage:[UIImage imageNamed:@"watermark"] forState:UIControlStateNormal];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/live/GetUserHeadPic?id=%@",BaseServiceUrl,AppDelegateInstance.userInfo.headerpicId]];

    UIImage * result;
    NSData * data = [NSData dataWithContentsOfURL:url];
    result = [UIImage imageWithData:data];
    [_myHeadImage setBackgroundImage:result forState:UIControlStateNormal];
    
}


- (void)singleClick:(UIButton *)gesture
{
    if (gesture.tag == 201) {
        
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"打开照相机" otherButtonTitles:@"从手机相册获取", nil];
        [actionSheet showInView:self.view];
    }else {

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"昵称" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil , nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert show];
    }
    
    
}

- (void)requestModifyUserNickName
{

    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:_nickName forKey:@"nickName"];
    
    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [self startRequest];
    [_requestClient postddByByUrlPath:@"/live/ModifyUserInfo" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [HUD hide:YES];
            return;
        }
        NSDictionary *dics = back;
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            [HUD hide:YES];
            AppDelegateInstance.userInfo.nickName = _nickName;
            _nickNameLabel.text=_nickName ;

            NSLog(@"%@", dics);
            HUD.mode = MBProgressHUDModeIndeterminate;
            [HUD hide:YES afterDelay:2]; // 延时2s消失
            HUD.labelText = @"修改成功";
        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    _isLoading  = NO;
                    [self requestModifyUserNickName];
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
        _isLoading  = NO;
    }];

}

- (void)requestModifyUserHeadPic:(NSString *)imageString highPic:(NSString *)highPic
{
    
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setObject:AppDelegateInstance.userInfo.sessionId forKey:@"sessionId"];
    [parameters setObject:imageString forKey:@"headPic"];
    [parameters setObject:highPic forKey:@"highPic"];

    if (_requestClient == nil) {
        _requestClient = [[QMZBNetwork alloc] init];
    }
    [self startRequest];
    [_requestClient postddByByUrlPath:@"/live/ModifyUserHeadPic" andParams:parameters andCallBack:^(id back) {
        if ([back isKindOfClass:[NSString class]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:back delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [HUD hide:YES];
            return;
        }
        NSDictionary *dics = back;
        int result_type = [[NSString jsonUtils:[dics objectForKey:@"status"]] intValue];
        if (result_type == 10000) {
            [HUD hide:YES];
            NSLog(@"%@", dics);
            AppDelegateInstance.userInfo.headerpicId = [NSString jsonUtils:[dics objectForKey:@"headPicId"]];
            HUD.mode = MBProgressHUDModeIndeterminate;
            [HUD hide:YES afterDelay:2]; // 延时2s消失
            HUD.labelText = @"修改成功";
        }else if (result_type  == 10003) {
            AppDelegateInstance.userInfo.isLogin = NO;
            [_requestClient reLogin_andCallBack:^(BOOL back) {
                if (back) {
                    
                    _isLoading  = NO;
                    [self requestModifyUserHeadPic:imageString highPic:highPic];
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
        _isLoading  = NO;
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
            _userLevel = [NSString jsonUtils:[dics objectForKey:@"level"]];
            _qinCoin = [NSString jsonUtils:[dics objectForKey:@"qinCoin"]];
            _jiaCoin = [NSString jsonUtils:[dics objectForKey:@"jiaCoin"]];
            [_collectionView reloadData];
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
    _isLoading = YES;
    
    HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.labelText = @"正在加载...";
    HUD.delegate = self;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UITextField *tf=[alertView textFieldAtIndex:0];
    if (tf.text.length == 0) {
        return;
    }
    _nickName = tf.text;
//    _nickNameLabel.text=_nickName ;
    [self requestModifyUserNickName];
    NSLog(@"=====%@",tf.text);
}



#pragma mark - UIActionSheetDelegate
- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex)
    {
        case 0:
        {
            //打开照相机拍照
            [self takePhoto];
            
        }
            break;
        case 1:
        {
            //打开本地相册
            [self LocalPhoto];
        }
            break;
    }
}

//点击 相机 照相
- (void) takePhoto
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        NSLog(@"相机不可用");
        return;
    }
    
    
    UIImagePickerController *ctl = [[UIImagePickerController alloc] init];
    ctl.delegate = self;
    //源
    ctl.sourceType = UIImagePickerControllerSourceTypeCamera;
    //    //类型
    //    ctl.mediaTypes = @[(NSString *)kUTTypeImage];
    ctl.allowsEditing = YES;
    [self presentViewController:ctl animated:YES completion:^{
    }];
    
}

//点击 相册 从相册中选择图片
- (void) LocalPhoto
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        NSLog(@"相册不可用");
        return;
    }
    
    UIImagePickerController *ctl = [[UIImagePickerController alloc] init];
    ctl.delegate = self;
    //源
    ctl.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    //    //类型
    //    ctl.mediaTypes = @[(NSString *)kUTTypeImage];
    ctl.allowsEditing = YES;
    [self presentViewController:ctl animated:YES completion:^{
    }];
    
    
}

#pragma mark - UIImagePickerControllerDelegate,UINavigationControllerDelegate
- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    //    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    [self saveImage:image withName:@"currentImage.png"];
    
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"currentImage.png"];
    
    UIImage *savedImage = [[UIImage alloc] initWithContentsOfFile:fullPath];
    
    UIImage *img = [self imageWithImage:savedImage scaledToSize:CGSizeMake(100, 100)];
    NSString *_encodedImageStr = [UIImageJPEGRepresentation(img,0.5) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSString *highPic = [UIImageJPEGRepresentation(image,1.0) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSLog(@"%@",highPic);
    
    [self requestModifyUserHeadPic:_encodedImageStr highPic:highPic];
    [_myHeadImage setBackgroundImage:img forState:UIControlStateNormal];
}

#pragma mark - 保存图片至沙盒
- (void) saveImage:(UIImage *)currentImage withName:(NSString *)imageName
{
    
    NSData *imageData = UIImageJPEGRepresentation(currentImage, 0.5);
    // 获取沙盒目录
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:imageName];
    // 将图片写入文件
    [imageData writeToFile:fullPath atomically:NO];
}
//压缩图片
-(UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


//当用户点击系统相册的取消时调用
- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

# pragma mark 表格UICollectionViewDataSource , UICollectionViewDelegate 协议方法

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    //返回各个单元格的控件视图
    QMZBSettingCollectionCell  *cell = (QMZBSettingCollectionCell *) [collectionView dequeueReusableCellWithReuseIdentifier:@"SettingCollection_cell" forIndexPath:indexPath];
    cell.image.image = [UIImage imageNamed:[NSString stringWithFormat:@"collection_icon_%ld",(long)indexPath.row]];
    cell.backgroundColor = BACKGROUND_COLOR;
    
    NSMutableAttributedString *str;
    
    if (indexPath.row == 0) {
        str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"直播%@个",_zhiboCount]];
        [str addAttribute:NSForegroundColorAttributeName value:COLOR(133, 230, 248, 1) range:NSMakeRange(2,_zhiboCount.length)];
    }else if (indexPath.row == 1) {
        str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"收益%@个",_jiaCoin]];
        [str addAttribute:NSForegroundColorAttributeName value:COLOR(152, 248, 133, 1) range:NSMakeRange(2,_jiaCoin.length)];
    }else if (indexPath.row == 2) {
        str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"账户%@云币",_qinCoin]];
        [str addAttribute:NSForegroundColorAttributeName value:COLOR(133, 230, 248, 1) range:NSMakeRange(2,_qinCoin.length)];
    }else if (indexPath.row == 3) {
        str = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"等级%@级",_userLevel]];
        [str addAttribute:NSForegroundColorAttributeName value:COLOR(230, 118, 50, 1) range:NSMakeRange(2,_userLevel.length)];
    }else {
        
    }
    cell.name.attributedText = str;

    return cell;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 4;
}

#pragma  表格布局代理方法

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 0) {
        
    }else if (indexPath.row == 1) {
        
    }else if (indexPath.row == 2) {
        QMZBTopUpController *topup = [[QMZBTopUpController alloc] init];
        UINavigationController *topupNavigation = [[UINavigationController alloc] initWithRootViewController:topup];
        CATransition *animation = [CATransition animation];
        animation.duration = 0.3;
        animation.timingFunction = UIViewAnimationCurveEaseInOut;
        animation.type = kCATransitionPush;
        animation.subtype = kCATransitionFromRight;
        [self.view.window.layer addAnimation:animation forKey:nil];
        [self presentViewController:topupNavigation animated:NO completion:nil];
    }else if (indexPath.row == 3) {
        
    }else {
        
    }
    
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(5, ((7)*kScreenWidth/320.f), 5, ((7)*kScreenWidth/320.f));
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
    return 2;

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //每个单元格的视图
    static NSString *itemCell = @"cell_item";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:itemCell];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:itemCell];
    }
    cell.backgroundColor = BACKGROUND_COLOR;
    
    UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(10, 15, 20, 20)];
    image.image = [UIImage imageNamed:[NSString stringWithFormat:@"image_icon_%ld",(long)indexPath.row+1]];
    [cell addSubview:image];
    
    UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(40, 10, 100, 30)];
    text.font = [UIFont systemFontOfSize:13.0];
    text.textColor = TEXT_BLACK_COLOR;
    [cell addSubview:text];
    
    if (indexPath.row == 2) {
        
    }else if (indexPath.row == 0) {
         text.text = @"个人设置";
    }else if (indexPath.row == 1) {
         text.text = @"联系亲加";
    }else {
        
    }
    
    
    UIImageView *arrow = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth-40, 15, 10, 14)];
    arrow.image = [UIImage imageNamed:[NSString stringWithFormat:@"jiaotou_image"]];
    [cell addSubview:arrow];
    
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 单元格被点击的监听
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == 2) {

        
    }else if (indexPath.row == 0) {
        QMZBMySettingController *mySetting = [[QMZBMySettingController alloc] init];
        UINavigationController *mySettingNavigation = [[UINavigationController alloc] initWithRootViewController:mySetting];
        CATransition *animation = [CATransition animation];
        animation.duration = 0.3;
        animation.timingFunction = UIViewAnimationCurveEaseInOut;
        animation.type = kCATransitionPush;
        animation.subtype = kCATransitionFromRight;
        [self.view.window.layer addAnimation:animation forKey:nil];
        [self presentViewController:mySettingNavigation animated:NO completion:nil];
    }else if (indexPath.row == 1) {
        QMZBContactController *contact = [[QMZBContactController alloc] init];
        UINavigationController *contactNavigation = [[UINavigationController alloc] initWithRootViewController:contact];
        CATransition *animation = [CATransition animation];
        animation.duration = 0.3;
        animation.timingFunction = UIViewAnimationCurveEaseInOut;
        animation.type = kCATransitionPush;
        animation.subtype = kCATransitionFromRight;
        [self.view.window.layer addAnimation:animation forKey:nil];
        [self presentViewController:contactNavigation animated:NO completion:nil];
    }else {
        
    }
    
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    // Dispose of any resources that can be recreated.
}


@end

