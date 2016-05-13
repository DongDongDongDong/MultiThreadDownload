//
//  ThreadSafetyArray.h
//  CheckAuto3-0
//
//  Created by andylau on 16/5/11.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void(^forinBlock) (NSObject *obj,BOOL *stop);

@interface ThreadSafetyArray : NSObject{
    @private
    NSMutableArray *_array;
}

@property (readonly) NSUInteger count;

- (void)addObject:(NSObject *)anObject;

- (void)removeObject:(NSObject *)anObjet;

- (void) removeObjectAtIndex:(NSUInteger)index;

- (void)removeAllObjects;

- (NSUInteger)indexOfObject:(NSObject *)anObject;

- (NSObject *)objectAtIndex:(NSUInteger)index;

- (NSMutableArray *)copyCurrentArray;

- (void)traversal:(forinBlock)forinBlock;
@end
