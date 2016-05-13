//
//  AIFileDownloaderManager.h
//  obdDownloader
//
//  Created by andylau on 16/1/18.
//  Copyright © 2016年 andylau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "downListModel.h"
#import "AIFileDownloader.h"
@interface AIFileDownloaderManager : NSObject

/** 下载操作缓冲池 */
@property (nonatomic, strong) NSMutableDictionary *downloaderCache;

@property (nonatomic, copy) void (^failedBlock) (NSString *);


@property (nonatomic, strong) AIFileDownloader *downloader;
+ (instancetype)sharedDownloaderManager;

- (void)downloadWithModel:(DownListModel *)model progress:(void (^)(float progress))progress completion:(void (^)(NSString *filePath))completion failed:(void (^)(NSString *errorMessage))failed;

- (void)pauseWithURL:(NSURL *)url;
@end
