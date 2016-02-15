//
//  Level.m
//  StarHunt
//
//  Created by Tae Hyun Kim on 2015. 12. 29..
//  Copyright (c) 2015년 Tae Hyun Kim. All rights reserved.
//

#import "Level.h"

// What is difference between this @implementation usage vs. @interface in .m file?
// Seems it does the same thing...
// > Private property?
@interface Level()
// Will be used to evaluate whether user has made a valid move OR
// Give hint to the user
@property (strong, nonatomic) NSSet *possibleSwaps;
@property (assign, nonatomic) NSUInteger comboMultiplier;
@end

@implementation Level{
    Cookie *_cookies[NumColumns][NumRows];
    Tile *_tiles[NumColumns][NumRows];
}

- (Cookie *)cookieAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1((column >= 0) && (column < NumColumns), @"Invalid column: %ld", (long)column);
    NSAssert1((row >=0) && (row < NumRows), @"Invalid row: %ld", (long)row);
    
    return _cookies[column][row];
}

- (NSSet *)shuffle {
    NSSet *set;
    
    do {
        set = [self createInitialCookies];
        
        [self detectPossibleSwaps];
        
        NSLog(@"Possible swaps: %@", self.possibleSwaps);
    } while ([self.possibleSwaps count] == 0);
    
    return set;
}
- (void)detectPossibleSwaps {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            Cookie *cookie = _cookies[column][row];
            if (cookie != nil) {
                //Detection logic
                // 1) Check for boundary
                if (column < NumColumns - 1) {
                    // 2) Is there a cookie on the right side?
                    Cookie *other = _cookies[column +1][row];
                    if (other != nil) {
                        // 3) swap them
                        _cookies[column][row] = other;
                        _cookies[column + 1][row] = cookie;
                        
                        // 4) does swapping make a chain?
                        if ([self hasChainAtColumn:column + 1 row:row] ||
                            [self hasChainAtColumn:column row:row]) {
                            MySwap *swap = [[MySwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        // 5) Restore the board
                        _cookies[column][row] = cookie;
                        _cookies[column + 1][row] = other;
                    }
                }
                
                // Same logic for row now - cookie at above
                if (row < NumRows - 1) {
                    Cookie *other = _cookies[column][row + 1];
                    if (other != nil) {
                        // swapping
                        _cookies[column][row] = other;
                        _cookies[column][row + 1] = cookie;
                        
                        if ([self hasChainAtColumn:column row:row + 1] ||
                            [self hasChainAtColumn:column row:row]) {
                            MySwap *swap = [[MySwap alloc] init];
                            swap.cookieA = cookie;
                            swap.cookieB = other;
                            [set addObject:swap];
                        }
                        
                        _cookies[column][row] = cookie;
                        _cookies[column][row + 1] = other;
                    }
                }
            }
        }
    }
    
    self.possibleSwaps = set;
}

- (BOOL)hasChainAtColumn:(NSInteger)column row:(NSInteger)row {
    NSUInteger cookieType = _cookies[column][row].cookieType;
    
    NSUInteger horzLength = 1;
    for (NSInteger i = column - 1; i >= 0 && _cookies[i][row].cookieType == cookieType; i--, horzLength++) ;
    for (NSInteger i = column + 1; i < NumColumns && _cookies[i][row].cookieType == cookieType; i++, horzLength++);
    if (horzLength >= 3) { // WHERE THE GAME DETECTS NUMBER OF COOKIES IN THE MATCH
        return YES;
    }
    
    NSUInteger vertLength = 1;
    for (NSInteger i = row - 1 ; i >= 0 && _cookies[column][i].cookieType == cookieType; i--, vertLength++) ;
    for (NSInteger i = row + 1 ; i < NumRows && _cookies[column][i].cookieType == cookieType; i++, vertLength++) ;
    return (vertLength >= 3);
    
}

- (NSSet *)createInitialCookies {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if (_tiles[column][row] != nil) {
                NSUInteger cookieType;
                do {
                    cookieType = arc4random_uniform(NumCookieTypes) + 1;
                } while ((column >= 2 &&
                        _cookies[column - 1][row].cookieType == cookieType &&
                        _cookies[column - 2][row].cookieType == cookieType)
                       ||
                       (row >= 2 &&
                        _cookies[column][row - 1].cookieType == cookieType &&
                        _cookies[column][row - 2].cookieType));
                
                Cookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                [set addObject:cookie];
            }
        }
    }
    return set;
}

- (instancetype)initWithFile:(NSString *)filename {
    self = [super init];
    if (self != nil) {
        NSDictionary *dictionary = [self LoadJSON:filename];
        
        // Loop through the rows
        [dictionary[@"tiles"] enumerateObjectsUsingBlock:^(NSArray *array, NSUInteger row, BOOL *stop){
            // Loop through the columns in the current row
            [array enumerateObjectsUsingBlock:^(NSNumber *value, NSUInteger column, BOOL *stop) {
                
                // Note: In Sprite kit (0,0) is at the bottom of the screen,
                // so we need to read this file upside down.
                NSInteger tileRow = NumRows - row - 1;
                
                // If the value is 1, create a tile object.
                if ([value integerValue] == 1) {
                    _tiles[column][tileRow] = [[Tile alloc] init];
                    self.targetScore = [dictionary[@"targetScore"] unsignedIntegerValue];
                    self.maximumMoves = [dictionary[@"moves"] unsignedIntegerValue];
                }
            }];
        }];
    }
    
    return self;
}

// Peeks into the array and returns corresponding Tile object
- (Tile *)tileAtColumn:(NSInteger)column row:(NSInteger)row {
    NSAssert1((column >= 0) && (column < NumColumns), @"Invalid column: %ld", (long)column);
    NSAssert1((row >= 0) && (row < NumRows), @"Invalid row: %ld", (long)row);
    
    return _tiles[column][row];
}

- (void)performSwap:(MySwap *)swap {
    NSInteger columnA = swap.cookieA.column;
    NSInteger rowA = swap.cookieA.row;
    
    NSInteger columnB = swap.cookieB.column;
    NSInteger rowB = swap.cookieB.row;
    
    _cookies[columnA][rowA] = swap.cookieB;
    swap.cookieB.column = columnA;
    swap.cookieB.row = rowA;
    
    _cookies[columnB][rowB] = swap.cookieA;
    swap.cookieA.column = columnB;
    swap.cookieA.row = rowB;
}

- (BOOL)isPossibleSwap:(MySwap *)swap {
    return [self.possibleSwaps containsObject:swap];
}

- (NSSet *)removeMatches {
    NSSet *horizontalChains = [self detectHorizontalMatches];
    NSSet *verticalChains = [self detectVerticalMatches];
    
    [self removeCookies:horizontalChains];
    [self removeCookies:verticalChains];
    
    [self calculateScores:horizontalChains];
    [self calculateScores:verticalChains];
//    NSLog(@"Horizontal matches: %@", horizontalChains);
//    NSLog(@"Vertical matches: %@", verticalChains);
    
    // combines two set into single set
    return [horizontalChains setByAddingObjectsFromSet:verticalChains];
}

- (NSArray *)fillHoles {
    NSMutableArray *columns = [NSMutableArray array];
    
    // Traversing bottom to up
    for (NSInteger column = 0; column < NumColumns; column++) {
        NSMutableArray *array;
        
        for (NSInteger row = 0; row < NumRows; row++) {
            // we have to consider emtpy tile (shape of level) as well
            if (_tiles[column][row] != nil && _cookies[column][row] == nil) {
                // if empty region is found, use lookup var.
                // to traverse upward and switch with the empty region.
                // At the end of the loop, empty region will be at the top of the column
                for (NSInteger lookup = row + 1; lookup < NumRows; lookup++) {
                    Cookie *cookie = _cookies[column][lookup];
                    if (cookie != nil) {
                        // 4
                        _cookies[column][lookup] = nil;
                        _cookies[column][row] = cookie;
                        cookie.row = row;
                        
                        // var. array will be unique for each column.
                        // This array is later used for animation of dropping the cookies down.
                        // The order is important.
                        if (array == nil) {
                            array = [NSMutableArray array];
                            [columns addObject:array];
                        }
                        [array addObject:cookie];
                        
                        // 6
                        break;
                    }
                }
            }
        }
    }
    return columns;
}

- (NSArray *)topUpCookies {
    NSMutableArray *columns = [NSMutableArray array];
    
    NSUInteger cookieType = 0;
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        NSMutableArray *array;
        
        // 1 - start traversing each column from bottom to up
        // until you find the empty space
        for (NSInteger row = NumRows - 1; row >= 0 && _cookies[column][row] == nil; row--) {
            // 2 - make sure the found empty space is due to map shape
            if (_tiles[column][row] != nil) {

                // 3 - new cookie generated will not be same as cookie generated previously
                NSUInteger newCookieType;
                do {
                    newCookieType = arc4random_uniform(NumCookieTypes) + 1;
                } while (newCookieType == cookieType);
                cookieType = newCookieType;
                
                //4
                Cookie *cookie = [self createCookieAtColumn:column row:row withType:cookieType];
                
                // 5 - Store the newly generated cookie into a array per column for animation (done in method animateNewCookies)
                if (array == nil) {
                    array = [NSMutableArray array];
                    [columns addObject:array];
                }
                [array addObject:cookie];
            }
        }
    }
    return columns;
}





- (Cookie *)createCookieAtColumn:(NSInteger)column row:(NSInteger)row withType:(NSUInteger)cookieType{
    Cookie *cookie = [[Cookie alloc] init];
    
    cookie.cookieType = cookieType;
    cookie.column = column;
    cookie.row = row;
    
    _cookies[column][row] = cookie;
    
    return cookie;
}

- (NSDictionary *)LoadJSON:(NSString *)filename {
    NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@"json"];
    if (path == nil) {
        NSLog(@"Could not find level file: %@", filename);
    }
    
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:path options:0 error:&error];
    if (data == nil) {
        NSLog(@"Could not load level file: '%@', error: %@", filename, error);
        return nil;
    }
    
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (dictionary == nil || ![dictionary isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Level file '%@' is not valid JSON: %@", filename, error);
        return nil;
    }
    
    return dictionary;
}

// Scanning the board for any horizontal matching chains
- (NSSet *)detectHorizontalMatches {
    // 1
    NSMutableSet *set = [NSMutableSet set];
    
    // Iterate through to check horizontal matches
    // Last two columns doesn't need to be checked (as a first cookie of the chain)
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns - 2; ) {
            //3
            if (_cookies[column][row] != nil) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                //4
                if (_cookies[column + 1][row].cookieType == matchType &&
                    _cookies[column + 2][row].cookieType == matchType) {
                    // 5
                    Chain *chain = [[Chain alloc] init];
                    chain.chainType = ChainTypeHorizontal;
                    
                    do {
                        [chain addCookie:_cookies[column][row]];
                        column += 1;
                    } while (column < NumColumns && _cookies[column][row].cookieType == matchType);
                    
                    [set addObject:chain];
                    continue;
                }
            }
            
            // 6
            column += 1;
        }
    }
    
    return set;
}

// Scanning the board for any vertical matching chains
- (NSSet *)detectVerticalMatches {
    NSMutableSet *set = [NSMutableSet set];
    
    for (NSInteger column = 0; column < NumColumns; column++) {
        for (NSInteger row = 0; row < NumRows -2; ) {
            if (_cookies[column][row] != nil) {
                NSUInteger matchType = _cookies[column][row].cookieType;
                
                if (_cookies[column][row+1].cookieType == matchType &&
                    _cookies[column][row+2].cookieType == matchType) {
                    Chain *chain = [[Chain alloc] init];
                    chain.chainType = ChainTypeVertical;
                    do {
                        [chain addCookie:_cookies[column][row]];
                        row += 1;
                    } while (row < NumRows && _cookies[column][row].cookieType == matchType);
                    [set addObject:chain];
                    continue;
                }
            }
            row += 1;
        }
    }
    
    return set;
}

- (void) removeCookies:(NSSet *)chains {
    for (Chain *chain in chains) {
        for (Cookie *cookie in chain.cookies) {
            _cookies[cookie.column][cookie.row] = nil;
        }
    }
}

- (void)calculateScores:(NSSet *)chains {
    for (Chain *chain in chains) {
        chain.score = 60 * ([chain.cookies count] - 2) * self.comboMultiplier;
        self.comboMultiplier++;
    }
}

- (void)resetComboMultiplier {
    self.comboMultiplier = 1;
}

@end