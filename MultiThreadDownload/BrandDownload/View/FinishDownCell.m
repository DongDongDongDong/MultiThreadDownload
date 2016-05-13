//
//  FinishDownCell.m
//  CheckAuto3-0
//
//  Created by andylau on 16/4/15.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import "FinishDownCell.h"

@interface FinishDownCell ()
@property (weak, nonatomic) IBOutlet UILabel *brandName;
@property (weak, nonatomic) IBOutlet UILabel *brandSize;

@end

@implementation FinishDownCell

- (void)setDownModel:(DownListModel *)downModel{
    _downModel = downModel;
    self.brandName.text = downModel.brandName;
    self.brandSize.text = [NSString stringWithFormat:@"%@M",downModel.brandSize];
}
@end
