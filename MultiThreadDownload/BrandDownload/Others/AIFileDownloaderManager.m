//
//  AIFileDownloaderManager.m
//  obdDownloader
//
//  Created by andylau on 16/1/18.
//  Copyright © 2016年 andylau. All rights reserved.
//

#import "AIFileDownloaderManager.h"

@interface AIFileDownloaderManager()
@end

@implementation AIFileDownloaderManager

+ (instancetype)sharedDownloaderManager {
    static id instance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSMutableDictionary *)downloaderCache {
    if (_downloaderCache == nil) {
        _downloaderCache = [[NSMutableDictionary alloc] init];
    }
    return _downloaderCache;
}

- (void)downloadWithModel:(DownListModel *)model progress:(void (^)(float progress))progress completion:(void (^)(NSString *filePath))completion failed:(void (^)(NSString *errorMessage))failed{

    self.failedBlock = failed;
    self.downloader = self.downloaderCache[model.downloadUrl];
    if (self.downloader != nil) {
        if (failed) {
            failed(@"下载操作已经存在，正在下载中....");
        }
        return;
    }
    
    self.downloader = [[AIFileDownloader alloc] init];
    if (model.downloadUrl) {
        [self.downloaderCache setObject:self.downloader forKey:model.downloadUrl];
    }
    [self.downloader downloadWithModel:model progress:progress completion:^(NSString *filePath) {
        if (model.downloadUrl) {
            [self.downloaderCache removeObjectForKey:model.downloadUrl];
        }
        if (completion) {
            completion(filePath);
        }
    } failed:failed];
}

- (void)pauseWithURL:(NSURL *)url {
    AIFileDownloader *download = self.downloaderCache[[url absoluteString]];
    
    if (download == nil) {
        if (self.failedBlock) {
            self.failedBlock(@"操作不存在，无需暂停");
        }
        return;
    }
    [download pause];
    
    if ([url absoluteString]) {
        [self.downloaderCache removeObjectForKey:[url absoluteString]];
    }
}

@end