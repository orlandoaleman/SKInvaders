//
//  YouWinScene
//  SpaceInvadersTraditional
//
//

#import "YouWinScene.h"
#import "GameScene.h"


@interface YouWinScene ()
@property BOOL contentCreated;
@end

@implementation YouWinScene

- (void)didMoveToView:(SKView *)view
{
    if (!self.contentCreated) {
        [self createContent];
        self.contentCreated = YES;
    }
}

- (void)createContent
{
    SKLabelNode *youWinLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    youWinLabel.fontSize = 50;
    youWinLabel.fontColor = [SKColor whiteColor];
    youWinLabel.text = @"You Win!";
    youWinLabel.position = CGPointMake(self.size.width / 2, 2.0 / 3.0 * self.size.height);
    [self addChild:youWinLabel];
    
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    scoreLabel.fontSize = 18;
    scoreLabel.fontColor = [SKColor whiteColor];
    scoreLabel.text = [NSString stringWithFormat:@"Score: %05u", [self.userData[@"score"] unsignedIntegerValue]];
    scoreLabel.position = CGPointMake(self.size.width / 2, youWinLabel.frame.origin.y - youWinLabel.frame.size.height - 10);
    [self addChild:scoreLabel];

    SKLabelNode *tapLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    tapLabel.fontSize = 25;
    tapLabel.fontColor = [SKColor whiteColor];
    tapLabel.text = [NSString stringWithFormat:@"(Tap to Play Level %i)", [self.userData[@"numberOfInvaderRows"] integerValue] + 1];
    tapLabel.position = CGPointMake(self.size.width / 2, scoreLabel.frame.origin.y - scoreLabel.frame.size.height - 40);
    [self addChild:tapLabel];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Intentional no-op
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Intentional no-op
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Intentional no-op
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    GameScene *gameScene = [[GameScene alloc] initWithSize:self.size];
    gameScene.scaleMode = SKSceneScaleModeAspectFill;
    gameScene.numberOfInvaderRows = [self.userData[@"numberOfInvaderRows"] unsignedIntegerValue] + 1;
    gameScene.shipHealth = [self.userData[@"shipHealth"] doubleValue];
    gameScene.score = [self.userData[@"score"] unsignedIntegerValue];
    [self.view presentScene:gameScene transition:[SKTransition doorsCloseHorizontalWithDuration:1.0]];
}


@end
