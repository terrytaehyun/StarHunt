//
//  Chain.h
//  StarHunt
//
//  Created by Tae Hyun Kim on 2016. 1. 3..
//  Copyright (c) 2016년 Tae Hyun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Cookie;

typedef NS_ENUM(NSUInteger, ChainType) {
    ChainTypeHorizontal,
    ChainTypeVertical,
};

@interface Chain : NSObject

@property (strong, nonatomic, readonly) NSArray *cookies;
@property (assign, nonatomic) ChainType chainType;
@property (assign, nonatomic) NSUInteger score;

- (void)addCookie:(Cookie *)cookie;

@end