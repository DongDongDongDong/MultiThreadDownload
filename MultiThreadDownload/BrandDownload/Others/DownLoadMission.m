//
//  DownLoadTask.m
//  obdDownloader
//
//  Created by andylau on 16/1/25.
//  Copyright © 2016年 andylau. All rights reserved.
//



#import "DownLoadMission.h"
#import "AIFileDownloaderManager.h"
#import "DownListModel.h"
#import <AVFoundation/AVFoundation.h>
#import "SSZipArchive.h"
//#import "MBProgressHUD+MJ.h"
#import "DXAlertView.h"
#import "CWStatusBarNotification.h"
#import "Util.h"
@interface DownLoadMission ()<AVAudioPlayerDelegate>
@property (nonatomic, strong)AVAudioPlayer *audioPlayer;
@property (nonatomic, strong)CWStatusBarNotification *notification;
@end

@implementation DownLoadMission

- (CWStatusBarNotification *)notification{
    if (_notification == nil) {
            _notification = [CWStatusBarNotification new];
            _notification.notificationLabelBackgroundColor = [UIColor blueColor];
            _notification.notificationLabelTextColor = [UIColor whiteColor];

    }
    return _notification;
}

- (void)changeValueText:(downloadProgressBlock)progressBlock{
    self.progressBlock = progressBlock;
}
- (void)didFinishDownload:(downloadFinishBlock)finishBlock{
    self.finishBlock = finishBlock;
}


- (instancetype)initWithUID:(NSString *)uid
{
    self = [super init];
    
    if (self) {
        self.UID = uid;        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(@"Only Once Init");
        });
    }
    
    return self;
}



- (void)download{
        [self beginDownload:self.model.downloadUrl];
}

- (void)pause{
    [self pauseWithUrl:self.model.downloadUrl];
}


- (void)pauseWithUrl:(NSString *)url{
    AIFileDownloaderManager *manager = [AIFileDownloaderManager sharedDownloaderManager];
    [manager pauseWithURL:[NSURL URLWithString:url]];
}

- (void)beginDownload:(NSString *)url{

    AIFileDownloaderManager *manager = [AIFileDownloaderManager sharedDownloaderManager];
    NSLog(@"开始下载 %@",url);
    __block typeof(self) weakSelf = self;
    
    [manager downloadWithModel:self.model progress:^(float progress) {
        NSLog(@"下载中%@－－－> %f",weakSelf.model.brandName,progress);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.progressBlock) {
                weakSelf.progressBlock(progress,weakSelf.model);
            }
        });
        
    } completion:^(NSString *filePath) {
        NSLog(@"下载完成 %@",weakSelf.model.downloadUrl);
        [weakSelf unZipVehiclesFileName:[NSString stringWithFormat:@"%@_%@",weakSelf.model.brandName,weakSelf.model.originName]];
        if (self.finishBlock) {
            self.finishBlock(weakSelf.model);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:AIOBDDownloadFinishUploadNotification object:self userInfo:@{@"uid":weakSelf.UID}];

    } failed:^(NSString *errorMessage) {
        NSLog(@"下载错误 %@",self.model.downloadUrl);
    }];
}

#pragma mark - unZip
- (void)unZipVehiclesFileName:(NSString *)fileName{
    NSLog(@"Begin Unzip...");
//    [self.notification displayNotificationWithMessage:[NSString stringWithFormat:@"开始解压%@",fileName] forDuration:1.0f];
    
    __block typeof(self) weakSelf = self;
    NSString *filePath = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents" ]stringByAppendingPathComponent:@"XTOOL"]stringByAppendingPathComponent:fileName];
    NSString *caches = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]stringByAppendingPathComponent:@"XTOOL"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL result = [SSZipArchive unzipFileAtPath:filePath toDestination:caches];
        
        if (result) {
            NSLog(@"解压成功");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.notification displayNotificationWithMessage:[NSString stringWithFormat:@"%@解压成功",fileName] forDuration:1.0f];
            });

            NSFileManager *fileMgr = [NSFileManager defaultManager];
            NSString *zipPath = [caches stringByAppendingPathComponent:fileName];
            BOOL bRet = [fileMgr fileExistsAtPath:zipPath];
            if (bRet) {
                NSError *err;
                BOOL deleteResult = [fileMgr removeItemAtPath:zipPath error:&err];
                if (!deleteResult) {
                    NSLog(@"Delete Zip Failed,unZip Succeed");
                }
            }
            
        }else{
            NSLog(@"解压失败");
//            self.isUnziping = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.notification displayNotificationWithMessage:[NSString stringWithFormat:@"解压失败%@",fileName] forDuration:1.0f];
            });
        }
    });
}


#pragma mark fakeAudio


- (void)fakeAudio
{
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dispatchQueue, ^(void) {
        NSError *audioSessionError = nil;
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession setCategory:AVAudioSessionCategoryPlayback error:&audioSessionError]){
            NSLog(@"Successfully set the audio session.");
        } else {
            NSLog(@"Could not set the audio session");
        }
        
        
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *filePath = [mainBundle pathForResource:@"mySong" ofType:@"mp3"];
        NSData *fileData = [NSData dataWithContentsOfFile:filePath];
        NSError *error = nil;
        
        self.audioPlayer = [[AVAudioPlayer alloc] initWithData:fileData error:&error];
        if (self.audioPlayer != nil){
            self.audioPlayer.delegate = self;
            [self.audioPlayer setNumberOfLoops:-1];
            if ([self.audioPlayer prepareToPlay] && [self.audioPlayer play]){
                NSLog(@"Successfully started playing...");
            } else {
                NSLog(@"Failed to play.");
            }
        } else {
            NSLog(@"Player is nil.");
        }
    });
    
}


@end
