//
//  AIFileDownloader.m
//  obdDownloader
//
//  Created by andylau on 16/1/17.
//  Copyright © 2016年 andylau. All rights reserved.
//

#import "AIFileDownloader.h"



#define kTimeOut    20.0


@interface AIFileDownloader() <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURL *downloadURL;
@property (nonatomic, strong) NSURLConnection *downloadConnection;

/** 文件总大小 */
@property (nonatomic, assign) long long expectedContentLength;
/** 本地文件当前大小 */
@property (nonatomic, assign) long long currentLength;

/** 文件保存在本地的路径 */
@property (nonatomic, copy) NSString *filePath;

@property (nonatomic, strong) NSOutputStream *fileStrem;
@property (nonatomic, assign) CFRunLoopRef downloadRunloop;

@property (nonatomic, copy) void (^progressBlock)(float);
@property (nonatomic, copy) void (^completionBlock)(NSString *);
@property (nonatomic, copy) void (^failedBlock)(NSString *);

@property (nonatomic, strong) DownListModel *model;

@end

@implementation AIFileDownloader


- (void)downloadWithModel:(DownListModel *)model progress:(void (^)(float progress))progress completion:(void (^)(NSString *filePath))completion failed:(void (^)(NSString *errorMessage))failed{
    self.model = model;
//    NSString *encodingUrl = [model.downloadUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.downloadURL = [NSURL URLWithString:model.downloadUrl];
    
    self.progressBlock = progress;
    self.completionBlock = completion;
    self.failedBlock = failed;
    
//    self.expectedContentLength = (long long)([model.brandSize floatValue] * 1024);
//    NSLog(@"-----文件大小%lld",self.expectedContentLength);
//    NSString *Path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
//    self.filePath = [Path stringByAppendingPathComponent:model.originName];

    [self serverFileInfoWithURL:[NSURL URLWithString:model.downloadUrl] andCompletion:completion];
//        NSLog(@"%lld %@", self.expectedContentLength, self.filePath);
//        if (![self checkLocalFileInfo]) {
//            if (completion) {
//                completion(self.filePath);
//            }
//            return;
//        };
//        NSLog(@"需要下载文件，从 %lld开始继续下载", self.currentLength);
//        [self downloadFile];
    
    
}

- (void)pause {
    [self.downloadConnection cancel];
}

#pragma mark - 下载文件
- (void)downloadFile {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.downloadURL cachePolicy:1 timeoutInterval:kTimeOut];
        NSString *rangeStr = [NSString stringWithFormat:@"bytes=%lld-", self.currentLength];
        [request setValue:rangeStr forHTTPHeaderField:@"Range"];
        
        self.downloadConnection = [NSURLConnection connectionWithRequest:request delegate:self];
        
        [self.downloadConnection start];
        
        self.downloadRunloop = CFRunLoopGetCurrent();
        CFRunLoopRun();
    });
}

#pragma mark - NSURLConnectionDataDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//   BOOL iscreat = [[NSFileManager defaultManager] createFileAtPath:self.filePath
//                                            contents:@"" attributes:nil];
//    NSLog(@"是否创建成功%d",iscreat);
    self.fileStrem = [[NSOutputStream alloc] initToFileAtPath:self.filePath append:YES];
    [self.fileStrem open];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    [self.fileStrem write:data.bytes maxLength:data.length];
    
    self.currentLength += data.length;
    float progress = (float)self.currentLength / self.expectedContentLength;
    
    if (self.progressBlock) {
        self.progressBlock(progress);
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.fileStrem close];
    
    CFRunLoopStop(self.downloadRunloop);
    
    if (self.completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^ {
            self.completionBlock(self.filePath);
        });
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.fileStrem close];
    CFRunLoopStop(self.downloadRunloop);
    self.model.errorDescription = error.localizedDescription;
    [AINoteCenter postNotificationName:AIOBDDownloadFailedNotification object:self userInfo:@{@"MODEL":self.model}];

    NSLog(@"出现错误%@", error.localizedDescription);
    
    if (self.failedBlock) {
        self.failedBlock(error.localizedDescription);
    }
}

#pragma mark - 私有方法

- (BOOL)checkLocalFileInfo {
    
    long long fileSize = 0;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.filePath]) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:NULL];
        fileSize = [attributes fileSize];
    }
    

    if (fileSize > self.expectedContentLength) {
        [[NSFileManager defaultManager] removeItemAtPath:self.filePath error:NULL];
        fileSize = 0;
    }
    
    self.currentLength = fileSize;
    if (fileSize == self.expectedContentLength) {
        return NO;
    }
    return YES;
}

- (void)serverFileInfoWithURL:(NSURL *)url andCompletion:(void (^)(NSString *filePath))completion{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:1 timeoutInterval:kTimeOut];
    request.HTTPMethod = @"HEAD";
    
    __block typeof(self) weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse * _Nullable response, NSData * _Nullable data, NSError * _Nullable connectionError) {
        if (connectionError) {
            NSLog(@"HEAD-ERROR--%@",connectionError.description);
            
            /** 请求服务器失败错误处理 */
            DownListModel *model = [[DownListModel alloc] init];
            model.errorDescription = @"当前网速过慢，请稍后重试";
            [AINoteCenter postNotificationName:AIOBDDownloadFailedNotification object:self userInfo:@{@"MODEL":model}];
            return;
            // error- pause task&continue next task
//            [[NSNotificationCenter defaultCenter] postNotificationName:@"NOTIFICATION_PAUSE_UPLOAD_TASK" object:nil userInfo:@{@"uid":weakSelf.model.uniqueMark}];
            // error- change current cell status
//            weakSelf.model.errorDescription = @"网络连接失败";
//            [AINoteCenter postNotificationName:AIOBDDownloadFailedNotification object:nil userInfo:@{@"MODEL":weakSelf.model}];

        }else{
            weakSelf.expectedContentLength = response.expectedContentLength;
            int expectedL = (int)weakSelf.expectedContentLength;
            if(!expectedL){
                NSLog(@"Give UP Download,HEAD REsult = %lld-%d",weakSelf.expectedContentLength,expectedL);
                return ;
            }
            NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"XTOOL"];
            BOOL creatXtool = [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
            NSAssert(creatXtool, @"创建XTOOL文件夹失败");
            weakSelf.filePath = [filePath stringByAppendingPathComponent:response.suggestedFilename];
            
            NSLog(@"%lld %@", weakSelf.expectedContentLength, weakSelf.filePath);
            if (![weakSelf checkLocalFileInfo]) {
                if (completion) {
                    completion(weakSelf.filePath);
                }
                return;
            };
            NSLog(@"需要下载文件，从 %lld开始继续下载", self.currentLength);
            [weakSelf downloadFile];
        }
    }];
//    NSURLResponse *response = nil;

//    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
//    self.expectedContentLength = response.expectedContentLength;
//    NSString *filePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"XTOOL"];
//    BOOL creatXtool = [[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
//    NSAssert(creatXtool, @"创建XTOOL文件夹失败");
//    self.filePath = [filePath stringByAppendingPathComponent:response.suggestedFilename];
//    
//    return;
}

- (void)clearBlockData{
    NSLog(@"Clear  Block ---- ");
    self.failedBlock = nil;
    self.progressBlock = nil;
    self.completionBlock = nil;
}

@end
