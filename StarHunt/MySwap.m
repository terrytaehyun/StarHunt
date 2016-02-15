//
//  MySwap.m
//  StarHunt
//
//  Created by Tae Hyun Kim on 2016. 1. 1..
//  Copyright (c) 2016년 Tae Hyun Kim. All rights reserved.
//

#import "MySwap.h"
#import "Cookie.h"

@implementation MySwap

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ swap %@ with %@", [super description], self.cookieA, self.cookieB];
}

// Need to override isEqual to compare the actual content of the two sets
// [set containsObject:obj] calls isEqual to evaluate possible moves
// w/o overriding, the isEqual method will compare the pointer values.
- (BOOL)isEqual:(id)object {
    // This method must only be used for MySwap objects
    if (![object isKindOfClass:[MySwap class]]) return NO;
    
    // Two swaps are equal if they contain the same cookie, but it doens't
    // matter whether they're called A in one and B in the other.
    MySwap *other = (MySwap *)object;
    return (other.cookieA == self.cookieA && other.cookieB == self.cookieB) ||
    (other.cookieB == self.cookieA && other.cookieA == self.cookieB);
}

// When overriding isEqual, we must provide implementation of the hash method
- (NSUInteger) hash {
    return [self.cookieA hash] ^ [self.cookieB hash];
}

@end