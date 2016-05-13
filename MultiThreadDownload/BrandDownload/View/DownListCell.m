//
//  DownListCell.m
//  obdDownloader
//
//  Created by andylau on 16/1/25.
//  Copyright © 2016年 andylau. All rights reserved.
//
//typedef enum {
//    NETWORK_TYPE_NONE= 0,
//    NETWORK_TYPE_2G= 1,
//    NETWORK_TYPE_3G= 2,
//    NETWORK_TYPE_4G= 3,
//    NETWORK_TYPE_5G= 4,//  5G目前为猜测结果
//    NETWORK_TYPE_WIFI= 5,
//}NETWORK_TYPE;

#import "DXAlertView.h"
#import "DownListCell.h"
#import "AIFileDownloaderManager.h"
#import "DownLoadMission.h"
#import "DownloadMissionList.h"
//#import "MBProgressHUD+MJ.h"
#import "OBDDownloadList.h"
#import "Util.h"
@interface DownListCell ()
@property (weak, nonatomic) IBOutlet UILabel *brandTitle;
@property (weak, nonatomic) IBOutlet UILabel *brandSize;

@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;

@end


@implementation DownListCell

- (void)awakeFromNib{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeCellStatus:) name:AIOBDDownloadChangeCellStatusNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTaskStatus) name:AIOBDDownloadAllTaskChangeStatusNotification object:nil];

    [AINoteCenter addObserver:self selector:@selector(didDownloadFailed:) name:AIOBDDownloadFailedNotification object:nil];
}

- (void)didDownloadFailed:(NSNotification *)note{
    
    DownListModel *model = note.userInfo[@"MODEL"];
    if (model) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![model.errorDescription isEqualToString:@"存储空间不足"]) {
                [Util showTips:[NSString stringWithFormat:@"%@",model.errorDescription] forSecond:1.0 onView:nil];
            }
        });
    }
    /** 出现错误，移除所有待下载任务，并改变所有任务状态 */
    NSArray *allDownloadArray = [DownloadMissionList shareDownload].allTasks;
    for (DownLoadMission *task in allDownloadArray) {
        [[OBDDownloadList shareDownloadList].statusDict setObject:@"33333" forKey:task.model.brandName];
    }
    [[DownloadMissionList shareDownload] removeAllMission];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        OBDDownloadList *listTable = [OBDDownloadList shareDownloadList];
        [listTable.obdListTable reloadData];
    });
    
    AIFileDownloaderManager *manager = [AIFileDownloaderManager sharedDownloaderManager];
    manager.downloaderCache = nil;
    manager.failedBlock = nil;
    [manager.downloader clearBlockData];

}

- (void)changeCellStatus:(NSNotification *)note{
    if ([note.userInfo[@"uid"] isEqualToString:self.downModal.uniqueMark]) {
        CGFloat progress = ((NSNumber *)note.userInfo[@"progress"]).floatValue;
        self.downloadProgress.progress = progress;
        NSString *brandSize = self.downModal.brandSize;
        self.brandSize.text = [NSString stringWithFormat:@"正在下载%.1fM/%@M",progress * [brandSize floatValue] ,brandSize];
        self.brandSize.textColor = [UIColor blueColor];
        [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%f",progress] forKey:self.downModal.brandName];
        [self layoutIfNeeded];
    }
}

- (void)changeTaskStatus{
    OBDDownloadList *downloadMgr = [OBDDownloadList shareDownloadList];
    NSArray *allDownloadArray = [DownloadMissionList shareDownload].allTasks;
    for (DownLoadMission *task in allDownloadArray) {
        if ([self.downModal.uniqueMark isEqualToString:task.UID]) {
            [self.downloadBtn setBackgroundImage:[UIImage imageNamed:@"下载中"] forState:UIControlStateNormal];
            [self.downloadBtn setTitle:@"暂停" forState:UIControlStateNormal];
            NSString *brandSize = self.downModal.brandSize;
            self.brandSize.text = [NSString stringWithFormat:@"等待下载%.1fM/%@M",self.downloadProgress.progress * [brandSize floatValue],brandSize];
            [downloadMgr.statusDict setObject:@"22222" forKey:self.downModal.brandName];
            self.brandSize.textColor = [UIColor blueColor];
            [self layoutIfNeeded];
            break;
        }
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDownModal:(DownListModel *)downModal{
    _downModal = downModal;
    self.brandTitle.text = downModal.brandName;
    self.brandSize.text = downModal.brandSize;
    self.downloadProgress.progress = [downModal.brandProgress floatValue];
    
    /** 每次重新初始化，只有是有进度条的，才会被置为暂停中的状态，所有尚未开始下载的一律置为未下载状态 */
    if ([downModal.brandProgress floatValue] > 0) {
        self.downloadBtn.tag = 33333;
    }
    
    /** 程序运行中的时候，以statusDict中保存的状态为准 */
    NSString *statusTag = [[OBDDownloadList shareDownloadList].statusDict objectForKey:downModal.brandName];
    if(statusTag){
        self.downloadBtn.tag = [statusTag integerValue];
    }
    
    
    if(self.downloadBtn.tag == 11111){
        /** 默认 */
        [self.downloadBtn setBackgroundImage:[UIImage imageNamed:@"未下载"] forState:UIControlStateNormal];
        [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
        self.brandSize.text = @"";
        self.brandSize.textColor = [UIColor blackColor];
    }else if (self.downloadBtn.tag == 22222){
        /** 下载 */
        [self.downloadBtn setBackgroundImage:[UIImage imageNamed:@"下载中"] forState:UIControlStateNormal];
        [self.downloadBtn setTitle:@"暂停" forState:UIControlStateNormal];
        NSString *brandSize = downModal.brandSize;
        self.brandSize.text = [NSString stringWithFormat:@"等待下载%.1fM/%@M",self.downloadProgress.progress * [brandSize floatValue] ,brandSize];
        self.brandSize.textColor = [UIColor blueColor];
    }else if (self.downloadBtn.tag == 33333){
        /** 暂停 */
        [self.downloadBtn setBackgroundImage:[UIImage imageNamed:@"暂停中"] forState:UIControlStateNormal];
        [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
        NSString *brandSize = downModal.brandSize;
        self.brandSize.text = [NSString stringWithFormat:@"已暂停%.1fM/%@M",self.downloadProgress.progress * [brandSize floatValue] ,brandSize];
        self.brandSize.textColor = [UIColor redColor];
    }
    NSMutableArray *allTasks = [DownloadMissionList shareDownload].allTasks;
    
    /** 全部下载时修改状态 */
    for (DownLoadMission *task in allTasks) {
        if ([task.UID isEqualToString:downModal.uniqueMark]) {
            [self.downloadBtn setBackgroundImage:[UIImage imageNamed:@"下载中"] forState:UIControlStateNormal];
            [self.downloadBtn setTitle:@"暂停" forState:UIControlStateNormal];
            
            NSString *brandSize = downModal.brandSize;
            self.brandSize.text = [NSString stringWithFormat:@"等待下载%.1fM/%@M",self.downloadProgress.progress * [brandSize floatValue] ,brandSize];
            self.brandSize.textColor = [UIColor blueColor];
            break;
        }
    }
    
}


- (IBAction)btnDidClick:(UIButton *)button {
    __block typeof(self) weakSelf = self;
//    NSLog(@"点击了下载按钮－%@",self.downModal.brandName);
    if ([button.titleLabel.text isEqualToString:@"下载"]) {
    
        if([Util getNetworkTypeFromStatusBar] == 0){
            [Util showTips:@"似乎已断开与互联网的连接" forSecond:1.0 onView:nil];
//            [MBProgressHUD show:@"似乎已断开与互联网的连接" duration:1.0];
            return;
        }else if([Util getNetworkTypeFromStatusBar] != 5){
            DXAlertView *alert = [[DXAlertView alloc] initWithTitle:@"警告" contentText:@"确定要使用手机流量进行下载吗？" leftButtonTitle:@"确定" rightButtonTitle:@"取消"];
            [alert show];
            alert.leftBlock = ^(){
//                NSLog(@"left---");
                [weakSelf permitDownloadWithButton:button];
            };
        }else{
            NSLog(@"确定要使用WIFI进行下载吗？");
            [self permitDownloadWithButton:button];
        }

    }else if ([button.titleLabel.text isEqualToString:@"暂停"]) {
        button.tag = 33333;
         NSMutableArray *allTasks = [DownloadMissionList shareDownload].allTasks;
        for (DownLoadMission *task in allTasks) {
            if ([task.UID isEqualToString:self.downModal.uniqueMark]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:AIOBDDownloadPauseUploadTaskNotification object:nil userInfo:@{@"uid":self.downModal.uniqueMark}];
                break;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [button setTitle:@"下载" forState:UIControlStateNormal];
                [button setBackgroundImage:[UIImage imageNamed:@"暂停中"] forState:UIControlStateNormal];
                NSString *brandSize = weakSelf.downModal.brandSize;
                weakSelf.brandSize.text = [NSString stringWithFormat:@"已暂停%.1fM/%@M",weakSelf.downloadProgress.progress * [brandSize floatValue],brandSize];
                [[OBDDownloadList shareDownloadList].statusDict setObject:@"33333" forKey:weakSelf.downModal.brandName];
                weakSelf.brandSize.textColor = [UIColor redColor];
                
            });
        });
    }

}

- (void)permitDownloadWithButton:(UIButton *)button{

    if(![Util haveEnoughSpace]){
        //  todo  main UI
        DXAlertView *alert = [[DXAlertView alloc]initWithTitle:@"存储空间不足" contentText:@"请清理空间后重试" leftButtonTitle:nil rightButtonTitle:@"确定"];
        [alert show];
        DownListModel *model = [[DownListModel alloc] init];
        model.errorDescription = @"存储空间不足";
        [AINoteCenter postNotificationName:AIOBDDownloadFailedNotification object:self userInfo:@{@"MODEL":model}];
        return;
    }
    
    [button setTitle:@"暂停" forState:UIControlStateNormal];
    button.tag = 22222;
    [button setBackgroundImage:[UIImage imageNamed:@"下载中"] forState:UIControlStateNormal];
    DownLoadMission *mission = [[DownLoadMission alloc]initWithUID:self.downModal.uniqueMark];
    mission.model = self.downModal;
    
    [[DownloadMissionList shareDownload] addMission:mission];
    __block typeof(self)weakSelf = self;
    
    NSString *brandSize = self.downModal.brandSize;
    self.brandSize.text = [NSString stringWithFormat:@"等待下载%.1fM/%@M",self.downloadProgress.progress * [brandSize floatValue],brandSize];
    self.brandSize.textColor = [UIColor blueColor];
    [[OBDDownloadList shareDownloadList].statusDict setObject:@"22222" forKey:self.downModal.brandName];

    [mission changeValueText:^(CGFloat progressValue, DownListModel *model) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:AIOBDDownloadChangeCellStatusNotification object:nil userInfo:@{@"uid":model.uniqueMark, @"progress":@(progressValue)} ];
            
        });
    }];
    
    
    [mission didFinishDownload:^(DownListModel *finishModal) {
        NSLog(@"下载完毕 %@-%@",finishModal.brandName,finishModal.brandSize);
        [weakSelf dataDidFinishDownload:finishModal];
    }];
}

- (void)dataDidFinishDownload:(DownListModel *)model{
    [[NSNotificationCenter defaultCenter] postNotificationName:AIOBDDownloadDeleteUploadCellNotification object:nil userInfo:@{@"model":self.downModal}];
}

//#pragma mark -netWorkType
//
//-(NETWORK_TYPE)getNetworkTypeFromStatusBar {
//    UIApplication *app = [UIApplication sharedApplication];
//    NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
//    NSNumber *dataNetworkItemView = nil;
//    for (id subview in subviews) {
//        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]])     {
//            dataNetworkItemView = subview;
//            break;
//        }
//    }
//    NETWORK_TYPE nettype = NETWORK_TYPE_NONE;
//    NSNumber * num = [dataNetworkItemView valueForKey:@"dataNetworkType"];
//    nettype = [num intValue];
//    return nettype;
//}

@end
