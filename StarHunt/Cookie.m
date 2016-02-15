//
//  Cookie.m
//  StarHunt
//
//  Created by Tae Hyun Kim on 2015. 12. 28..
//  Copyright (c) 2015년 Tae Hyun Kim. All rights reserved.
//

#import "Cookie.h"

@implementation Cookie

- (NSString *)spriteName{
    static NSString* const spriteNames[] = {
        @"Croissant",
        @"Cupcake",
        @"Danish",
        @"Donut",
        @"Macaroon",
        @"SugarCookie",
    };
    
    return spriteNames[self.cookieType - 1];
    
}

- (NSString *)highlightedSpriteName{
    static NSString* const highlightedSpriteNames[] = {
        @"Croissant-Highlighted",
        @"Cupcake-Highlighted",
        @"Danish-Highlighted",
        @"Donut-Highlighted",
        @"Macaroon-Highlighted",
        @"SugarCookie-Highlighted",
    };
    
    return highlightedSpriteNames[self.cookieType - 1];

}


// For Debugging purposes
- (NSString *)description {
    return [NSString stringWithFormat:@"type:%ld square:(%ld, %ld)", (long)self.cookieType, (long)self.column, (long)self.row];
}


@end
