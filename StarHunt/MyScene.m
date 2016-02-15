//
//  MyScene.m
//  StarHunt
//
//  Created by Tae Hyun Kim on 2015. 12. 28..
//  Copyright (c) 2015년 Tae Hyun Kim. All rights reserved.
//

#import "MyScene.h"
#import "Cookie.h"
#import "Level.h"
#import "MySwap.h"

static const CGFloat TileWidth = 32.0;
static const CGFloat TileHeight = 36.0;

@interface MyScene ()

@property (strong, nonatomic) SKNode *gameLayer;
@property (strong, nonatomic) SKNode *cookiesLayer;
@property (strong, nonatomic) SKNode *tilesLayer;

// To make cookies drop behind the background.
@property (strong, nonatomic) SKCropNode *cropLayer;
@property (strong, nonatomic) SKNode *maskLayer;

@end

@implementation MyScene

- (id)initWithSize:(CGSize)size {
    if ((self = [super initWithSize:size])) {
        
        // Adding Background picture to the scene
        self.anchorPoint = CGPointMake(0.5, 0.5);
        
        SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"Background"];
        [self addChild:background];
        
        // Adding Game layer to the scene - centered on the screen
        // Game layer will be container for other layers
        self.gameLayer = [SKNode node];
        self.gameLayer.hidden = YES; // So that appear animation will work
        [self addChild:self.gameLayer];
        
        // Adding Tiles Layer to the scene
        // This must be done before adding cookie layer
        // As z-position of sprite are drawn in order of how they were added.
        CGPoint layerPosition = CGPointMake(-TileWidth*NumColumns/2, -TileHeight*NumRows/2);

        self.tilesLayer = [SKNode node];
        self.tilesLayer.position = layerPosition;
        [self.gameLayer addChild:self.tilesLayer];
        
        // For making cookies drop behind the background
        self.cropLayer = [SKCropNode node];
        [self.gameLayer addChild:self.cropLayer];
        
        self.maskLayer = [SKNode node];
        self.maskLayer.position = layerPosition;
        self.cropLayer.maskNode = self.maskLayer;
        
        // Adding Cookie Layer to the scene
        self.cookiesLayer = [SKNode node];
        self.cookiesLayer.position = layerPosition;
        
        [self.cropLayer addChild:self.cookiesLayer];
        
        // Initializing Swipe data
        self.swipeFromColumn = self.swipeFromRow = NSNotFound;
        
        // Creating selection sprite for hightlights
        self.selectionSprite = [SKSpriteNode node];
        
        // Loading sound effects
        [self preloadResources];
    }
    return self;
}

// Difference btwn SKSpriteNode and SKNode:
//  - SKSpriteNode is a subclass of SKNode
//  - SKNode does not provide any visual content,
//    and is the fundamental building block of most SpriteKit content.
- (void)addSpritesForCookies:(NSSet *)cookies {
    for (Cookie *cookie in cookies) {
        SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
        sprite.position = [self pointForColumn:cookie.column row:cookie.row];
        [self.cookiesLayer addChild:sprite];
        cookie.sprite = sprite;
        
        // Adding fade-in animation with random duration.
        // Scaling size from 0.5 to 1, with duration 0.25, variation +0.5
        cookie.sprite.alpha = 0;
        cookie.sprite.xScale = cookie.sprite.yScale = 0.5;
        
        [cookie.sprite runAction:[SKAction sequence:@[
                                                      [SKAction waitForDuration:0.25 withRange:0.5],
                                                      [SKAction group:@[
                                                                        [SKAction fadeInWithDuration:0.25],
                                                                        [SKAction scaleTo:1.0 duration: 0.25]
                                                                        ]]]]];
    }
}

- (void)addTiles {
    for (NSInteger row = 0; row < NumRows; row++) {
        for (NSInteger column = 0; column < NumColumns; column++) {
            if ([self.level tileAtColumn:column row:row] != nil) {
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:@"MaskTile"];
                tileNode.position = [self pointForColumn:column row:row];
                [self.maskLayer addChild:tileNode];
            }
        }
    }
    
    // For making corner tiles round tiles
    for (NSInteger row = 0; row <= NumRows; row++) {
        for (NSInteger column = 0; column <= NumColumns; column++) {
            BOOL topLeft     = (column > 0) && (row < NumRows)
                                            && [self.level tileAtColumn:column - 1 row:row];
            BOOL bottomLeft  = (column > 0) && (row > 0)
                                            && [self.level tileAtColumn:column - 1 row:row - 1];
            BOOL topRight    = (column < NumColumns) && (row < NumRows)
                                                     && [self.level tileAtColumn:column row:row];
            BOOL bottomRight = (column < NumColumns) && (row > 0)
                                                     && [self.level tileAtColumn:column row:row - 1];
            
            // The tiles are named from 0 to 15, according to the bitmask that is
            // made by combining these four values
            NSUInteger value = topLeft | topRight << 1 | bottomLeft << 2 | bottomRight << 3;
            
            // Values 0 (no tiles), 6 and 9 (two opposite tiles) are not drawn.
            if (value != 0 && value != 6 && value != 9) {
                NSString *name = [NSString stringWithFormat:@"Tile_%lu", (long)value];
                SKSpriteNode *tileNode = [SKSpriteNode spriteNodeWithImageNamed:name];
                CGPoint point = [self pointForColumn:column row:row];
                point.x -= TileWidth/2;
                point.y -= TileHeight/2;
                tileNode.position = point;
                [self.tilesLayer addChild:tileNode];
            }
        }
    }
    
}

// Touch recognition methods
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // When user touches parts other than the game board after selecting a cookie,
    // remove highlighted cookie sprite
    if (self.selectionSprite.parent != nil && self.swipeFromColumn != NSNotFound) {
        [self hideSelectionIndicator];
    }
    
    // When gesture ends, reset the swipe values to initial value
    self.swipeFromColumn = self.swipeFromRow = NSNotFound;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Converts the touch location to a point relative to the cookies layer
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    // Find out if the touch is inside a squre on the level grid
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        
        // Validate that the touch is on a cookie rather than on an empty square
        Cookie *cookie = [self.level cookieAtColumn:column row:row];
        if (cookie != nil) {
            // Store the start location of the touch
            // which will be used later to decide direction of the swipe
            self.swipeFromColumn = column;
            self.swipeFromRow = row;
            
            // Highlight the selected cookie
            [self showSelectionIndicatorForCookie:cookie];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.swipeFromColumn == NSNotFound) {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self.cookiesLayer];
    
    NSInteger column, row;
    if ([self convertPoint:location toColumn:&column row:&row]) {
        NSInteger horzDelta = 0, vertDelta = 0;
        
        if (column < self.swipeFromColumn) {
            horzDelta = -1; // Swipe left
        } else if (column > self.swipeFromColumn) {
            horzDelta = 1; // Swipe right
        } else if (row < self.swipeFromRow) {
            vertDelta = -1; // Swipe down
        } else if (row > self.swipeFromRow) {
            vertDelta = 1; // Swipe up
        }
        
        if (horzDelta != 0 || vertDelta != 0) {
            [self trySwapHorizontal:horzDelta vertical:vertDelta];
            // Remove highlighted cookie sprite
            [self hideSelectionIndicator];
            // The game will ignore the rest of the swipe motion
            self.swipeFromColumn = NSNotFound;
        }
    }
}

- (void)trySwapHorizontal:(NSInteger)horzDelta vertical:(NSInteger)vertDelta {
    NSInteger toColumn = self.swipeFromColumn + horzDelta;
    NSInteger toRow = self.swipeFromRow + vertDelta;
    
    // Checks if the "to" coordinates falls outside of the gameboard
    if ((toColumn < 0) || (toColumn >= NumColumns)) {
        return;
    }
    if ((toRow < 0) || (toRow) >= NumRows) {
        return;
    }
    
    // Checks for empty slot (a wall)
    Cookie *toCookie = [self.level cookieAtColumn:toColumn row:toRow];
    if (toCookie == nil) {
        return;
    }
    
    // Valid swap
    Cookie *fromCookie = [self.level cookieAtColumn:self.swipeFromColumn row:self.swipeFromRow];
    
    // NSLog(@"*** Swipping %@ with %@", fromCookie, toCookie);
    if (self.swipeHandler != nil) {
        MySwap *swap = [[MySwap alloc] init];
        swap.CookieA = fromCookie;
        swap.CookieB = toCookie;
        
        self.swipeHandler(swap);
    }
}

- (CGPoint)pointForColumn:(NSInteger)column row:(NSInteger)row {
    return CGPointMake(column*TileWidth + TileWidth/2, row*TileHeight + TileHeight/2);
}

- (BOOL)convertPoint:(CGPoint)point toColumn:(NSInteger *)column row:(NSInteger *)row {
    // Checks if column or row is nil
    NSParameterAssert(column);
    NSParameterAssert(row);
    
    // Checking if the point is residing in the valid region
    if ((point.x >= 0) && (point.x < NumColumns*TileWidth) &&
        (point.y >= 0) && (point.y < NumRows*TileHeight)) {
        // Calculating corresponding row and column number
        *column = point.x / TileWidth;
        *row = point.y / TileHeight;
        return YES;
    } else {
        // Indicates point is in invalid region
        *column = NSNotFound;
        *row = NSNotFound;
        return NO;
    }

}

// dispatch_block_t is a blokc that returns void and takes no params
- (void)animateSwap:(MySwap *)swap completion:(dispatch_block_t)completion {
    // Put the startking cookie on the top
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.3;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.TimingMode = SKActionTimingEaseOut;
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, [SKAction runBlock:completion]]]];
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    [swap.cookieB.sprite runAction:moveB];
    
    // Sound effect
    [self runAction:self.swapSound];
}

- (void)animateInvalidSwap:(MySwap *)swap completion:(dispatch_block_t)completion {
    swap.cookieA.sprite.zPosition = 100;
    swap.cookieB.sprite.zPosition = 90;
    
    const NSTimeInterval Duration = 0.2;
    
    SKAction *moveA = [SKAction moveTo:swap.cookieB.sprite.position duration:Duration];
    moveA.timingMode = SKActionTimingEaseOut;
    
    SKAction *moveB = [SKAction moveTo:swap.cookieA.sprite.position duration:Duration];
    moveB.timingMode = SKActionTimingEaseOut;
    
    [swap.cookieA.sprite runAction:[SKAction sequence:@[moveA, moveB, [SKAction runBlock:completion]]]];
    // Swap back right after
    [swap.cookieB.sprite runAction:[SKAction sequence:@[moveB, moveA]]];
    
    // Sound effect
    [self runAction:self.invalidSwapSound];
}

- (void)animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion {
    for (Chain *chain in chains) {
        
        [self animateScoreForChain:chain];
        
        for (Cookie *cookie in chain.cookies) {
            
            // Point 1:Cookie *cookie could be part of two chains (horz, and vert)
            // We only want to add one animation to the sprite
            // This checks for this situation
            if (cookie.sprite != nil) {
                
                // Perform shrink animation, and remove the sprite from cookie layer
                SKAction *scaleAction = [SKAction scaleTo:0.1 duration:0.3];
                scaleAction.timingMode = SKActionTimingEaseOut;
                [cookie.sprite runAction:[SKAction sequence:@[scaleAction, [SKAction removeFromParent]]]];
                
                // Remove link btwn Cookie and its sprite as soon as you add the animation.
                // This prevents the situation in point 1
                cookie.sprite = nil;
            }
        }
    }
    
    [self runAction:self.matchSound];
    
    // Continue on with the game
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:0.3],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion {
    // 1 - We don't know how many cookies have to fall down
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        [array enumerateObjectsUsingBlock:^(Cookie *cookie, NSUInteger idx, BOOL *stop) {
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            
            //2 - higher up the cookie, more delay required
            NSTimeInterval delay = 0.05 + 0.15 * idx;
            
            //3 - duration of cookie falling down a tile is 0.1 seconds
            NSTimeInterval duration = ((cookie.sprite.position.y - newPosition.y) / TileHeight) * 0.1;
            
            //4 - calculate longest duration for step #6
            longestDuration = MAX(longestDuration, duration + delay);
            
            //5 - perform animation with delay, movement, and sound effect
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseOut;
            [cookie.sprite runAction:[SKAction sequence:@[
                                                          [SKAction waitForDuration:delay],
                                                          [SKAction group:@[moveAction, self.fallingCookieSound]]]]];
        }];
    }
    
    // 6 - Wait unil all cookies fall down, then continue the game
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:longestDuration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion {
    // 1 - game cannot be continued until the new cookies are created
    // Need to calculate longestDuration dynaically depending on the number of cookies being generated
    // __block keyword tells compiler to treat the var. in special way
    // any modifications done to the var. will be visible outside of the block
    __block NSTimeInterval longestDuration = 0;
    
    for (NSArray *array in columns) {
        //2 - New cookie generation must start just above the first tile in this column
        NSInteger startRow = ((Cookie *)[array firstObject]).row + 1;
        
        [array enumerateObjectsUsingBlock:^(Cookie *cookie, NSUInteger idx, BOOL *stop) {
            // 3 - Creating new sprite for the cookie
            SKSpriteNode *sprite = [SKSpriteNode spriteNodeWithImageNamed:[cookie spriteName]];
            sprite.position = [self pointForColumn:cookie.column row:startRow];
            [self.cookiesLayer addChild:sprite];
            cookie.sprite = sprite;
            
            // 4
            NSTimeInterval delay = 0.1 + 0.2 * ([array count] - idx - 1);
            
            // 5
            NSTimeInterval duration = (startRow - cookie.row) * 0.1;
            longestDuration = MAX(longestDuration, duration + delay);
            
            // 6
            CGPoint newPosition = [self pointForColumn:cookie.column row:cookie.row];
            SKAction *moveAction = [SKAction moveTo:newPosition duration:duration];
            moveAction.timingMode = SKActionTimingEaseInEaseOut;
            cookie.sprite.alpha = 0;
            [cookie.sprite runAction:[SKAction sequence:@[
                                                          [SKAction waitForDuration:delay],
                                                          [SKAction group:@[
                                                                            [SKAction fadeInWithDuration:0.05], moveAction, self.addCookieSound]]]]];
        }];
    }
    
    // 7
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:longestDuration],
                                         [SKAction runBlock:completion]
                                         ]]];
}

- (void)animateScoreForChain:(Chain *)chain {
    // Figure out what the midpoint of the chain is.
    Cookie *firstCookie = [chain.cookies firstObject];
    Cookie *lastCookie = [chain.cookies lastObject];
    CGPoint centerPosition = CGPointMake(
        (firstCookie.sprite.position.x + lastCookie.sprite.position.x)/2,
        (firstCookie.sprite.position.y + lastCookie.sprite.position.y)/2 - 8);
    
    // Add a lable for the score that slowly floats up
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
    scoreLabel.fontSize = 16;
    scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)chain.score];
    scoreLabel.position = centerPosition;
    scoreLabel.zPosition = 300;
    [self. cookiesLayer addChild:scoreLabel];
    
    SKAction *moveAction = [SKAction moveBy:CGVectorMake(0, 3) duration:0.7];
    moveAction.timingMode = SKActionTimingEaseInEaseOut;
    [scoreLabel runAction:[SKAction sequence:@[
                                              moveAction,
                                              [SKAction removeFromParent]
                                              ]]];
    
}

- (void)animateGameOver {
    // Animates entire gameLAyer out of the way
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseIn;
    [self.gameLayer runAction:action];
}

- (void)animateBeginGame {
    // Animates slides the gameLayer back in from the top of the screen.
    self.gameLayer.hidden = NO;
    
    self.gameLayer.position = CGPointMake(0, self.size.height);
    SKAction *action = [SKAction moveBy:CGVectorMake(0, -self.size.height) duration:0.3];
    action.timingMode = SKActionTimingEaseOut;
    [self. gameLayer runAction:action];
}


// Used at the end of the game to remove previous game's sprites
- (void)removeAllCookieSprite {
    [self.cookiesLayer removeAllChildren];
}

- (void)showSelectionIndicatorForCookie:(Cookie *)cookie {
    // If the selection indicator is still visilbue, first remove it
    if (self.selectionSprite.parent != nil) {
        [self.selectionSprite removeFromParent];
    }
    
    // SKTexture vs. SKSpriteNode
    // No rendering engine uses the image resource directly
    // It is always first converted into a texture, which then gets used by the SKSpriteNode.
    // Delcaring a texture is a good way to save memory if multiple sprite uses
    // same image resource.
    // Even if SKSpriteNode's loadImageWithName is used, and no instance of SKTexture was used
    // A SKTexture will be created in background and may be used by future spriteNodes
    // This is known as texture caching.
    // The key for retreiving the Texture is its name.
    SKTexture *texture = [SKTexture textureWithImageNamed:[cookie highlightedSpriteName]];
    self.selectionSprite.size = texture.size;
    [self.selectionSprite runAction:[SKAction setTexture:texture]];
    
    [cookie.sprite addChild:self.selectionSprite];
    self.selectionSprite.alpha = 1.0;
}

- (void)preloadResources {
    self.swapSound = [SKAction playSoundFileNamed:@"Chomp.wav" waitForCompletion:NO];
    self.invalidSwapSound = [SKAction playSoundFileNamed:@"Error.wav" waitForCompletion:NO];
    self.matchSound = [SKAction playSoundFileNamed:@"Ka-Ching.wav" waitForCompletion:NO];
    self.fallingCookieSound = [SKAction playSoundFileNamed:@"Scrape.wav" waitForCompletion:NO];
    self.addCookieSound = [SKAction playSoundFileNamed:@"Drip.wav" waitForCompletion:NO];
    
    // Sprite Kit needs to load the font and convert it to a texture.
    // This only happens once, but it does create a small delay.
    // preload the font to avoid this delay in-game.
    [SKLabelNode labelNodeWithFontNamed:@"GillSans-BoldItalic"];
}

- (void)hideSelectionIndicator {
    [self.selectionSprite runAction:[SKAction sequence:@[
        [SKAction fadeOutWithDuration:0.3],
        [SKAction removeFromParent]]]];
}


@end