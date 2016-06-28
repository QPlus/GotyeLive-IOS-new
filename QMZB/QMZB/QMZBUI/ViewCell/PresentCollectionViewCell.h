//
//  PresentCollectionViewCell.h
//  QMZB
//
//  Created by Jim on 16/4/20.
//  Copyright © 2016年 yangchuanshuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PresentCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UIImageView *bgImageView;
@property (strong, nonatomic) IBOutlet UILabel *nameLabel;


- (void)fillCollectionCellWithImage:(NSString *)imageName Name:(NSString *)name;

@end
