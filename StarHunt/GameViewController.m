//
//  GameViewController.m
//  StarHunt
//
//  Created by Tae Hyun Kim on 2015. 12. 26..
//  Copyright (c) 2015년 Tae Hyun Kim. All rights reserved.
//

// Using @import, Xcode will add the framework to the project automatically
// While using #import, we have to do this manually
@import AVFoundation;

#import "GameViewController.h"
#import "MyScene.h"
#import "Level.h"

// This @interface at .m file allows us to hide any internal variables
// Catagory name can be placed in the bracket, works are a namespace
// To use the catafory, the @implementation GameViewController(CAT_NAME)
@interface GameViewController ()
    @property (strong, nonatomic) AVAudioPlayer *backgrounMusic;

    @property (strong, nonatomic) MyScene *scene;
    @property (strong, nonatomic) Level *level;

    @property (assign, nonatomic) NSUInteger movesLeft;
    @property (assign, nonatomic) NSUInteger score;

    @property (weak, nonatomic) IBOutlet UILabel *targetLabel;
    @property (weak, nonatomic) IBOutlet UILabel *movesLabel;
    @property (weak, nonatomic) IBOutlet UILabel *scoreLabel;

    @property (weak, nonatomic) IBOutlet UIImageView *gameOverPanel;
    @property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

    @property (weak, nonatomic) IBOutlet UIButton *shuffleButton;
@end


@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Configure the view
    SKView *skView = (SKView *)self.view;
    skView.multipleTouchEnabled = NO;
    
    // Create and configure the scene
    self.scene = [MyScene sceneWithSize:skView.bounds.size];
    self.scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Load the level
    self.level = [[Level alloc] initWithFile:@"Level_3"];
    self.scene.level = self.level;
    [self.scene addTiles];
    
    id block = ^(MySwap *swap) {
        self.view.userInteractionEnabled = NO;
        if ([self.level isPossibleSwap:swap]) {
            [self.level performSwap:swap];
            [self.scene animateSwap:swap completion:^{
                [self handleMatches];
            }];
        } else {
            [self.scene animateInvalidSwap:swap completion:^{
                self.view.userInteractionEnabled = YES;
            }];
        }
        
    };
    
    self.scene.swipeHandler = block;
    
    // Hiding the game over panel at the start of the game
    self.gameOverPanel.hidden = YES;
    
    // Present the Scene
    [skView presentScene:self.scene];
    
    // Play the BGM
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Mining by Moonlight" withExtension:@"mp3"];
    self.backgrounMusic = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    self.backgrounMusic.numberOfLoops = -1;
    [self.backgrounMusic play];
    
    // Start Game
    [self beginGame];
    
}

- (void)beginGame {
    self.movesLeft = self.level.maximumMoves;
    self.score = 0;
    [self updateLabels];
    [self.level resetComboMultiplier];
    
    // Show the game layer - make the game layer to appear with animation
    [self.scene animateBeginGame];
    
    [self shuffle];
}

- (void)shuffle {
    // Clear all cookie sprites from previous game
    [self.scene removeAllCookieSprite];
    
    NSSet *newCookies = [self.level shuffle];
    [self.scene addSpritesForCookies:newCookies];
}

- (void)handleMatches {
    NSSet *chains = [self.level removeMatches];
    
    // End condition for handleMatches recursion
    if ([chains count] == 0) {
        [self beginNextTurn];
        return;
    }
    
    [self.scene animateMatchedCookies:chains completion:^{
        
        for (Chain *chain in chains) {
            self.score += chain.score;
        }
        [self updateLabels];
        
        NSArray *columns = [self.level fillHoles];
        [self.scene animateFallingCookies:columns completion:^{
            NSArray *columns = [self.level topUpCookies];
            [self.scene animateNewCookies:columns completion:^{
                // recursively call handleMatches until no chain is present
                [self handleMatches];
            }];
        }];
    }];
}

- (void) beginNextTurn {
    [self.level resetComboMultiplier];
    // new set of cookies have created - need to recalculate possible swaps
    [self.level detectPossibleSwaps];
    [self decrementMoves];
    self.view.userInteractionEnabled = YES;
}

- (void)updateLabels {
    self.targetLabel.text = [NSString stringWithFormat:@"%lu", (long)self.level.targetScore];
    self.movesLabel.text = [NSString stringWithFormat:@"%lu", (long)self.movesLeft];
    self.scoreLabel.text = [NSString stringWithFormat:@"%lu", (long)self.score];
}

- (void)decrementMoves {
    self.movesLeft--;
    [self updateLabels];
    
    // Checks for game ending condition, and sets image to the UIImage view
    // accordingly
    if (self.score >= self.level.targetScore) {
        self.gameOverPanel.image = [UIImage imageNamed:@"LevelComplete"];
        [self showGameOver];
    } else if (self.movesLeft == 0) {
        self.gameOverPanel.image = [UIImage imageNamed:@"GameOver"];
        [self showGameOver];
    }
}

- (void)showGameOver {
    [self.scene animateGameOver];
    
    self.gameOverPanel.hidden = NO;
    self.scene.userInteractionEnabled = NO;
    
    self.shuffleButton.hidden = YES;
    
    // user interaction is restricted to tap only
    // Once user tabs, hideGameOver will be called to restart the game
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideGameOver)];
    [self.view addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)hideGameOver {
    [self.view removeGestureRecognizer:self.tapGestureRecognizer];
    self.tapGestureRecognizer = nil;
    
    self.gameOverPanel.hidden = YES;
    self.scene.userInteractionEnabled = YES;
    
    self.shuffleButton.hidden = NO;

    [self beginGame];
}

- (IBAction)shuffleButtonPressed:(id)sender {
    [self shuffle];
    [self decrementMoves];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
