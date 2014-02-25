//
//  GameScene.m
//  SKInvaders
//

//  Copyright (c) 2013 RepublicOfApps, LLC. All rights reserved.
//

#import "GameScene.h"
#import <CoreMotion/CoreMotion.h>

#pragma mark - Custom Type Definitions

#pragma mark - Private GameScene Properties

@interface GameScene ()
@property BOOL contentCreated;
@end


@implementation GameScene

#pragma mark Object Lifecycle Management

#pragma mark - Scene Setup and Content Creation

- (void)didMoveToView:(SKView *)view
{
    if (!self.contentCreated) {
        [self createContent];
        self.contentCreated = YES;
    }
}

- (void)createContent
{
    SKSpriteNode* invader = [SKSpriteNode spriteNodeWithImageNamed:@"InvaderA_00.png"];
    invader.position = CGPointMake(self.size.width/2, self.size.height/2);
    [self addChild:invader];
}

#pragma mark - Scene Update

- (void)update:(NSTimeInterval)currentTime
{
}

#pragma mark - Scene Update Helpers

#pragma mark - Invader Movement Helpers

#pragma mark - Bullet Helpers

#pragma mark - User Tap Helpers

#pragma mark - HUD Helpers

#pragma mark - Physics Contact Helpers

#pragma mark - Game End Helpers

@end
