//
//  GameScene.m
//  SKInvaders
//

//  Copyright (c) 2013 RepublicOfApps, LLC. All rights reserved.
//

#import "GameScene.h"
#import <CoreMotion/CoreMotion.h>
#import "UIImage+Extras.h"


#pragma mark - Custom Type Definitions

typedef NS_ENUM (NSUInteger, InvaderType) {
    InvaderTypeA,
    InvaderTypeB,
    InvaderTypeC
};


#define kInvaderName        @"invader"
#define kInvaderSize        CGSizeMake(24, 16)
#define kInvaderGridSpacing CGSizeMake(12, 12)
#define kInvaderRowCount    6
#define kInvaderColCount    6

#define kShipName           @"ship"
#define kShipSize           CGSizeMake(30, 16)



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
    [self setupInvaders];
    [self setupShip];
}


- (void)setupInvaders
{
    CGPoint baseOrigin = CGPointMake(kInvaderSize.width / 2, 180);
    
    for (NSUInteger row = 0; row < kInvaderRowCount; ++row) {
        InvaderType invaderType;
        
        if (row % 3 == 0) invaderType = InvaderTypeA;
        else if (row % 3 == 1) invaderType = InvaderTypeB;
        else invaderType = InvaderTypeC;
        
        CGPoint invaderPosition = CGPointMake(baseOrigin.x, row * (kInvaderGridSpacing.height + kInvaderSize.height) + baseOrigin.y);
        
        for (NSUInteger col = 0; col < kInvaderColCount; ++col) {
            SKNode *invader = [self makeInvaderOfType:invaderType];
            invader.position = invaderPosition;
            [self addChild:invader];
            invaderPosition.x += kInvaderSize.width + kInvaderGridSpacing.width;
        }
    }
}


- (SKSpriteNode *)makeInvaderOfType:(InvaderType)invaderType
{
    SKColor *invaderColor;

    switch (invaderType) {
        case InvaderTypeA:
            invaderColor = [SKColor redColor];
            break;

        case InvaderTypeB:
            invaderColor = [SKColor greenColor];
            break;

        case InvaderTypeC:
        default:
            invaderColor = [SKColor blueColor];
            break;
    }


    UIImage *image = [UIImage imageNamed:@"InvaderA_00.png"];
    SKTexture *texture = [SKTexture textureWithImage:[image imageTintedOfColor:invaderColor]];
    
    SKSpriteNode *invader = [SKSpriteNode spriteNodeWithTexture:texture size:kInvaderSize];
    invader.name = kInvaderName;
    return invader;
}


-(void)setupShip
{
    SKNode* ship = [self makeShip];
    ship.position = CGPointMake(self.size.width / 2.0f, kShipSize.height/2.0f);
    [self addChild:ship];
}


- (SKNode*)makeShip
{
    SKNode* ship = [SKSpriteNode spriteNodeWithImageNamed:kShipName];
    ship.name = kShipName;
    return ship;
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
