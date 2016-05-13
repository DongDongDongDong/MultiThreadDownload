//
//  DownListCell.h
//  obdDownloader
//
//  Created by andylau on 16/1/25.
//  Copyright © 2016年 andylau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DownListModel.h"
@interface DownListCell : UITableViewCell


@property (nonatomic, strong) DownListModel *downModal;

@property (weak, nonatomic) IBOutlet UIProgressView *downloadProgress;



@end
