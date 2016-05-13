//
//  Util.m
//  MultiThreadDownload
//
//  Created by andylau on 16/5/13.
//  Copyright © 2016年 andylau. All rights reserved.
//



#import "Util.h"
#import "MBProgressHUD.h"
@implementation Util

+ (UIColor *) colorWithHex:(UInt64)hex
{
    // Scan values
    unsigned int r = (hex >> 16) & 0XFF;
    unsigned int g = (hex >> 8) & 0XFF;
    unsigned int b = (hex >> 0) & 0XFF;
    if (r == 0 && g == 0 && b == 0)
    {
        return [UIColor colorWithRed:((float) r / 255.0f)
                               green:((float) g / 255.0f)
                                blue:((float) b / 255.0f)
                               alpha:0.0f];
    }
    else
    {
        return [UIColor colorWithRed:((float) r / 255.0f)
                               green:((float) g / 255.0f)
                                blue:((float) b / 255.0f)
                               alpha:1.0f];
    }
}

+ (NETWORK_TYPE)getNetworkTypeFromStatusBar{
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
    NSNumber *dataNetworkItemView = nil;
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]])     {
            dataNetworkItemView = subview;
            break;
        }
    }
    NETWORK_TYPE nettype = NETWORK_TYPE_NONE;
    NSNumber * num = [dataNetworkItemView valueForKey:@"dataNetworkType"];
    nettype = [num intValue];
    return nettype;
}


+ (void)showTips:(NSString *)tips forSecond:(CGFloat)second onView:(UIView *)view
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication].windows objectAtIndex:0] animated:YES];
    
    // Configure for text only and offset down
    hud.mode = MBProgressHUDModeText;
    hud.labelText = tips;
    hud.margin = 10.f;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:second];
    
}

+ (BOOL)haveEnoughSpace
{
    NSDictionary *fsAttr = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    //    float diskSize = [fsAttr[NSFileSystemSize] doubleValue] / 1073741824.f;
    float diskFreeSize = [fsAttr[NSFileSystemFreeSize] doubleValue] / (1024*1024);
    //    float diskUsedSize = diskSize - diskFreeSize;
    //    return [NSString stringWithFormat:@"%0.1f GB of %0.1f GB", diskUsedSize, diskSize];
    //200MB
    if (diskFreeSize <= 200) {
        return NO;
    } else {
        return YES;
    }
}

@end
