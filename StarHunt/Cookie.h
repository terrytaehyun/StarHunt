//
//  Cookie.h
//  StarHunt
//
//  Created by Tae Hyun Kim on 2015. 12. 28..
//  Copyright (c) 2015년 Tae Hyun Kim. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

static const NSUInteger NumCookieTypes = 6;

@interface Cookie : NSObject

@property (assign, nonatomic) NSInteger column;
@property (assign, nonatomic) NSInteger row;
@property (assign, nonatomic) NSUInteger cookieType;
@property (strong, nonatomic) SKSpriteNode *sprite;

- (NSString *)spriteName;
- (NSString *)highlightedSpriteName;

@end
