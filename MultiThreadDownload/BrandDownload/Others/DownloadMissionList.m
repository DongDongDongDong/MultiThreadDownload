//
//  DownloadQueue.m
//  obdDownloader
//
//  Created by andylau on 16/1/26.
//  Copyright © 2016年 andylau. All rights reserved.
//


#define MAX_DOWNLOAD_COUNT 1
#import "DownloadMissionList.h"
#import <AVFoundation/AVFoundation.h>
#import "DXAlertView.h"
#import "DownListModel.h"

@interface DownloadMissionList ()<AVAudioPlayerDelegate>

@property (nonatomic, strong) NSMutableArray *runningMissionList;
@property (nonatomic, strong) NSMutableArray *missionList;

@property (nonatomic, strong)AVAudioPlayer *audioPlayer;

@end
@implementation DownloadMissionList

- (NSMutableArray *)runningMissionList{
    if (_runningMissionList == nil) {
        _runningMissionList = [NSMutableArray array];
    }
    return _runningMissionList;
}

- (NSMutableArray *)missionList{
    if (_missionList == nil) {
        _missionList = [NSMutableArray array];
    }
    return _missionList;

}

+ (instancetype)shareDownload{
    static DownloadMissionList *queue = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[DownloadMissionList alloc]init];
        NSLog(@"Only Once Initqueue");
        [queue fakeAudio];
    });
    return queue;

}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishTask:) name:AIOBDDownloadFinishUploadNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishTask:) name:@"NOTIFICATION_REMOVE_FAIL_TASK" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseTask:) name:AIOBDDownloadPauseUploadTaskNotification object:nil];
    }
    return self;
}

- (void)pauseTask:(NSNotification *)notificaion{
    NSDictionary *info = notificaion.userInfo;
    NSString *uid = info[@"uid"];
    for (DownLoadMission *mission in self.runningMissionList) {
        if ([mission.UID isEqualToString:uid]) {
            [mission pause];
            [self.runningMissionList removeObject:mission];
            
            
            if (self.missionList.count > 0) {
                BOOL runSuccess = [self downloadMission:[self.missionList objectAtIndex:0]];
                if (runSuccess) {
                    [self.missionList removeObjectAtIndex:0];
                }
            }

            
            break;
        }
    }
    
    for (DownLoadMission *mission in self.missionList) {
        if ([mission.UID isEqualToString:uid]) {
            [self.missionList removeObject:mission];
            break;
        }
    }

    
}

- (void)finishTask:(NSNotification *)notificaion
{
    NSDictionary *info = notificaion.userInfo;
    NSString *uid = info[@"uid"];
    for (DownLoadMission *mission in self.runningMissionList) {
        if ([mission.UID isEqualToString:uid]) {
            [self.runningMissionList removeObject:mission];
            break;
        }
    }
    
    if (self.missionList.count > 0) {
        
        if(![Util haveEnoughSpace]){
            DXAlertView *alert = [[DXAlertView alloc]initWithTitle:@"存储空间不足" contentText:@"请清理空间后重试" leftButtonTitle:nil rightButtonTitle:@"确定"];
            [alert show];
            DownListModel *model = [[DownListModel alloc] init];
            model.errorDescription = @"存储空间不足";
            [AINoteCenter postNotificationName:AIOBDDownloadFailedNotification object:self userInfo:@{@"MODEL":model}];
            return;
        }

        BOOL runSuccess = [self downloadMission:[self.missionList objectAtIndex:0]];
        if (runSuccess) {
            [self.missionList removeObjectAtIndex:0];
        }
    }
}

- (BOOL)downloadMission:(DownLoadMission *)mission{
    @synchronized(self)
    {
        if (self.runningMissionList.count >= MAX_DOWNLOAD_COUNT) {
            return NO;
        }
        
        [self.runningMissionList addObject:mission];
        
        [mission download];
        
        return YES;
    }
}


- (void)addMission:(DownLoadMission *)mission {
    if (self.runningMissionList.count < MAX_DOWNLOAD_COUNT) {
        if (![self downloadMission:mission]) {
            [self.missionList addObject:mission];
        }
    }else {
        [self.missionList addObject:mission];
    }
   
}

- (void)removeAllMission{
    [self.runningMissionList removeAllObjects];
    
    [self.missionList removeAllObjects];
}

- (NSMutableArray *)allTasks
{
    NSMutableArray *result = [NSMutableArray new];
    [result addObjectsFromArray:self.runningMissionList];
    [result addObjectsFromArray:self.missionList];
    return result;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark fakeAudio
- (void)fakeAudio
{
    dispatch_queue_t dispatchQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(dispatchQueue, ^(void) {
        NSError *audioSessionError = nil;
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&audioSessionError]){
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
