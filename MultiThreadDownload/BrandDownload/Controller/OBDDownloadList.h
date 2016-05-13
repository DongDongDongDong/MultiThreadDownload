//
//  OBDDownloadListViewController.h
//  obdDownloader
//
//  Created by andylau on 16/1/25.
//  Copyright © 2016年 andylau. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThreadSafetyArray.h"
@interface OBDDownloadList : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *obdListTable;

+ (OBDDownloadList *)shareDownloadList;

/** 品牌下载NO  已下载YES */
@property (nonatomic, assign) BOOL isDownloaded;


/** 品牌下载列表数据 */
@property (nonatomic, strong) ThreadSafetyArray *downListArray;


/** 已下载列表数据 */
@property (nonatomic, strong) ThreadSafetyArray *downloadedListArray;

/** 当前下载状态 */
@property (nonatomic, strong) NSMutableDictionary *statusDict;


@end
