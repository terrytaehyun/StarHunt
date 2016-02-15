//
//  Level.h
//  StarHunt
//
//  Created by Tae Hyun Kim on 2015. 12. 29..
//  Copyright (c) 2015년 Tae Hyun Kim. All rights reserved.
//

#import "Cookie.h"
#import "Tile.h"
#import "MySwap.h"
#import "Chain.h"

static const NSInteger NumColumns = 9;
static const NSInteger NumRows = 9;

@interface Level : NSObject

@property (assign, nonatomic) NSUInteger targetScore;
@property (assign, nonatomic) NSUInteger maximumMoves;

- (NSSet *)shuffle;
- (Cookie *)cookieAtColumn:(NSInteger)column row:(NSInteger)row;
- (instancetype)initWithFile:(NSString *)filename;
- (Tile *)tileAtColumn:(NSInteger)column row:(NSInteger)row;

// Used for creating set of possible matches
// Match will only accepted if it exists in the set creted in this method
// May be used for hinting players
- (void)detectPossibleSwaps;

- (void)performSwap:(MySwap *)swap;
- (BOOL)isPossibleSwap:(MySwap *)swap;

// Used for removing matched (>3 consecutive cookies)
- (NSSet *)removeMatches;
// Used to make top region cookies to fall down once cookies at bottom region clears out
- (NSArray *)fillHoles;
// Used for filling in empty cookies at the top
- (NSArray *)topUpCookies;

- (void)resetComboMultiplier;
@end