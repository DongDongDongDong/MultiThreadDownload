//
//  StorageSpace.m
//  CheckAuto3-0
//
//  Created by andylau on 16/4/18.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import "StorageSpace.h"
#import "DownListModel.h"
#import "OBDDownloadList.h"
@interface StorageSpace ()

@end

@implementation StorageSpace

- (IBAction)refreshStorage:(id)sender {
    
    
    CGFloat usedStorage = 0;
//    for (DownListModel *model in [OBDDownloadList shareDownloadList].downloadedListArray) {
    for (DownListModel *model in [[OBDDownloadList shareDownloadList].downloadedListArray copyCurrentArray]) {
        usedStorage += [model.brandSize floatValue];
    }
    
    NSDictionary *fsAttr = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    float diskFreeSize = [fsAttr[NSFileSystemFreeSize] doubleValue] / (1024 * 1024 * 1024.00);

    self.spaceLabel.text = [NSString stringWithFormat:@"已下载%.fM,手机剩余空间%.1fG",usedStorage,diskFreeSize];

}

@end
