//
//  CollectionViewCellRoomMember.h
//  QMZB
//
//  Created by 刘淦 on 5/5/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CollectionViewCellRoomMember : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *imageViewAvatar;

+ (instancetype)cellWithCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath*)indexPath;
@end
