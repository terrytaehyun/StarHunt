//
//  Chain.m
//  StarHunt
//
//  Created by Tae Hyun Kim on 2016. 1. 3..
//  Copyright (c) 2016년 Tae Hyun Kim. All rights reserved.
//

#import "Chain.h"

@implementation Chain {
    NSMutableArray *_cookies;
}

- (void)addCookie:(Cookie *)cookie {
    if (_cookies == nil) {
        _cookies = [NSMutableArray array];
    }
    [_cookies addObject:cookie];
}

// Note that in header, the cookie array is defined as NSArray,
// while the implementation actually uses NSMutableArray
// This is a trick that we can use to force the array to be read only
// to the users of the class
- (NSArray *)cookies {
    return _cookies;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld cookies:%@", (long)self.chainType, self.cookies];
}

@end