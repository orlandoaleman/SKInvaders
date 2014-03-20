//
//  GameScene.h
//  SpaceInvaders
//  Orlando Aleman @orlandoaleman
//

#import <SpriteKit/SpriteKit.h>

@interface GameScene : SKScene <SKPhysicsContactDelegate>

@property NSUInteger numberOfInvaderRows;
@property CGFloat shipHealth;
@property NSUInteger score;
@end
