//
//  DownLoadTask.h
//  obdDownloader
//
//  Created by andylau on 16/1/25.
//  Copyright © 2016年 andylau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownListModel.h"


typedef void(^downloadProgressBlock)(CGFloat progressValue,DownListModel *model);
typedef void(^downloadFinishBlock)(DownListModel *finishModel);

@interface DownLoadMission : NSObject

@property (nonatomic, strong) DownListModel *model;

@property (nonatomic, copy) NSString *UID;
@property (nonatomic) CGFloat currentProgress;


@property (nonatomic, copy) downloadProgressBlock progressBlock;
@property (nonatomic, copy) downloadFinishBlock finishBlock;


- (void)changeValueText:(downloadProgressBlock)progressBlock;

- (void)didFinishDownload:(downloadFinishBlock)finishBlock;

- (instancetype)initWithUID:(NSString *)uid;

- (void)download;
- (void)pause;
@end
