//
//  MyScene.h
//  StarHunt
//
//  Created by Tae Hyun Kim on 2015. 12. 28..
//  Copyright (c) 2015년 Tae Hyun Kim. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class Level;
@class MySwap;

@interface MyScene : SKScene
@property (strong, nonatomic) Level* level;
@property (copy, nonatomic) void(^swipeHandler)(MySwap *swap);

// These values will store column/row number of a sprite
// When it is touched
@property (assign, nonatomic) NSInteger swipeFromColumn;
@property (assign, nonatomic) NSInteger swipeFromRow;

// For highlighting sprite
@property (strong, nonatomic) SKSpriteNode *selectionSprite;

// For sound effects
@property (strong, nonatomic) SKAction *swapSound;
@property (strong, nonatomic) SKAction *invalidSwapSound;
@property (strong, nonatomic) SKAction *matchSound;
@property (strong, nonatomic) SKAction *fallingCookieSound;
@property (strong, nonatomic) SKAction *addCookieSound;

- (void)addSpritesForCookies:(NSSet *)cookies;
- (void)addTiles;

- (void)animateSwap:(MySwap *)swap completion:(dispatch_block_t)completion;
- (void)animateInvalidSwap:(MySwap *)swap completion:(dispatch_block_t)completion;
- (void)animateMatchedCookies:(NSSet *)chains completion:(dispatch_block_t)completion;
- (void)animateFallingCookies:(NSArray *)columns completion:(dispatch_block_t)completion;
- (void)animateNewCookies:(NSArray *)columns completion:(dispatch_block_t)completion;
- (void)animateGameOver;
- (void)animateBeginGame;

- (void)removeAllCookieSprite;

@end

