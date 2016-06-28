//
//  CollectionViewCellRoomMember.m
//  QMZB
//
//  Created by 刘淦 on 5/5/16.
//  Copyright © 2016 yangchuanshuai. All rights reserved.
//

#import "CollectionViewCellRoomMember.h"

@implementation CollectionViewCellRoomMember

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

+ (instancetype)cellWithCollectionView:(UICollectionView *)collectionView indexPath:(NSIndexPath*)indexPath
{
    static NSString *cellId = @"CollectionViewCellRoomMember";
    CollectionViewCellRoomMember *cell = [collectionView dequeueReusableCellWithReuseIdentifier: cellId forIndexPath: indexPath];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed: cellId owner:self options:nil] lastObject];
    }
    
    MakeCornerRound(cell.imageViewAvatar, vh(cell.imageViewAvatar)/2);
    
    return  cell;

}

@end
