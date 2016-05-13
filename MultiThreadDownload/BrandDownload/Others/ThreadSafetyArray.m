//
//  ThreadSafetyArray.m
//  CheckAuto3-0
//
//  Created by andylau on 16/5/11.
//  Copyright © 2016年 youxinpai. All rights reserved.
//

#import "ThreadSafetyArray.h"

@implementation ThreadSafetyArray

- (instancetype)init{
    if (self = [super init]) {
        if (self) {
            _array = [[NSMutableArray alloc] init];
        }
    }
    return self;
}

- (NSUInteger)count{
    @synchronized (self) {
        return [_array count];
    }
}

- (NSObject *)objectAtIndex:(NSUInteger)index{
    @synchronized (self) {
        return _array[index];
    }
}

- (void)addObject:(NSObject *)anObject{
    @synchronized (self) {
        [_array addObject:anObject];
    }
}

- (void)removeObject:(NSObject *)anObjet{
    @synchronized (self) {
        [_array removeObject:anObjet];
    }
}

- (NSUInteger)indexOfObject:(NSObject *)anObject{
    @synchronized (self) {
        return [_array indexOfObject:anObject];
    }
}

- (void) removeObjectAtIndex:(NSUInteger)index{
    @synchronized (self) {
        [_array removeObjectAtIndex:index];
    }
}

- (void)removeAllObjects{
    @synchronized (self) {
        [_array removeAllObjects];
    }
}


- (void)traversal:(forinBlock)forinBlock{
    @synchronized (self) {
        BOOL  stop = NO;
        for (NSObject *obj in _array) {
            forinBlock(obj,&stop);
            if (stop) {
                break;
            }
        }
    }
}


- (NSMutableArray *)copyCurrentArray{
    return [_array mutableCopy];
}
@end
