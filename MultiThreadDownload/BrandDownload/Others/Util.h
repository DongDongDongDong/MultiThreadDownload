//
//  Util.h
//  MultiThreadDownload
//
//  Created by andylau on 16/5/13.
//  Copyright © 2016年 andylau. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef enum {
    NETWORK_TYPE_NONE= 0,
    NETWORK_TYPE_2G= 1,
    NETWORK_TYPE_3G= 2,
    NETWORK_TYPE_4G= 3,
    NETWORK_TYPE_5G= 4,//  5G为猜测结果
    NETWORK_TYPE_WIFI= 5,
}NETWORK_TYPE;


@interface Util : NSObject

+ (void)showTips:(NSString *)tips forSecond:(CGFloat)second onView:(UIView *)view;

+ (NETWORK_TYPE)getNetworkTypeFromStatusBar;

+ (BOOL)haveEnoughSpace;

+ (UIColor *) colorWithHex:(UInt64)hex;

@end

