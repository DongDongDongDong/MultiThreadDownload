//
//  DownloadQueue.h
//  obdDownloader
//
//  Created by andylau on 16/1/26.
//  Copyright © 2016年 andylau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownLoadMission.h"
@interface DownloadMissionList : NSObject

+ (instancetype)shareDownload;

- (void)addMission:(DownLoadMission *)mission;

- (BOOL)downloadMission:(DownLoadMission *)mission;

- (void)removeAllMission;
@property (nonatomic, strong, readonly) NSMutableArray *allTasks;


@end
