//
//  GameScene.m
//  SKInvaders
//

//

#import "GameScene.h"
#import <CoreMotion/CoreMotion.h>
#import "UIImage+Extras.h"
#import "GameOverScene.h"
#import "YouWinScene.h"


#pragma mark - Custom Type Definitions

typedef enum {
    InvaderTypeA,
    InvaderTypeB,
    InvaderTypeC
} InvaderType;



typedef enum {
    InvaderStrategyRandom,
    InvaderStrategyDistance,
    InvaderStrategyCol,
    InvaderStrategyMotion
} InvaderStrategy;


typedef enum {
    InvaderMovementDirectionRight,
    InvaderMovementDirectionLeft,
    InvaderMovementDirectionDownThenRight,
    InvaderMovementDirectionDownThenLeft,
    InvaderMovementDirectionNone
} InvaderMovementDirection;


typedef enum BulletType {
    ShipFiredBulletType,
    InvaderFiredBulletType
} BulletType;


#pragma mark - Constant Definitions

#define kInvaderSize                    CGSizeMake(24, 16)
#define kInvaderName                    @"invader"
#define kInvaderGridSpacing             CGSizeMake(12, 12)
#define kInvaderRowCountDefault         6
#define kInvaderColCount                6
#define kInvaderMinTimePerMove          0.1f
#define kInvaderMaxTimePerMove          1.f
#define kInvaderReductionOfTime         0.9f
#define kInvaderMinBulletTime           1.0f
#define kInvaderMaxBulletTime           2.0f
#define kInvaderReductionOfBulletTime   0.95f
#define kInvaderBulletTimeAdjustmentInterval 20
#define kInvaderStrategy                InvaderStrategyMotion

#define kShipSize                       CGSizeMake(30, 16)
#define kShipName                       @"ship"
#define kShipSize                       CGSizeMake(30, 16)
#define kShipBurstCapacity              3
#define kShipMaxHealth                  1.0f

#define kBulletSize                     CGSizeMake(4, 8)
#define kShipFiredBulletName            @"shipFiredBullet"
#define kInvaderFiredBulletName         @"invaderFiredBullet"


#define kScoreHudName                   @"scoreHud"
#define kHealthHudName                  @"healthHud"
#define kHealthHudText                  @"Health: %.1f%%"
#define kScoreHudText                   @"Score: %05u"


#define kMinInvaderBottomHeight 2*kShipSize.height // defines the height at which the invaders are considered to have invaded Earth


static const u_int32_t kInvaderCategory            = 0x1 << 0;
static const u_int32_t kShipFiredBulletCategory    = 0x1 << 1;
static const u_int32_t kShipCategory               = 0x1 << 2;
static const u_int32_t kSceneEdgeCategory          = 0x1 << 3;
static const u_int32_t kInvaderFiredBulletCategory = 0x1 << 4;


#pragma mark - Private GameScene Properties

@interface GameScene ()
@property BOOL contentCreated;
@property BOOL gameEnding;
@property CMMotionManager *motionManager;
@property NSMutableArray *tapQueue;
@property NSMutableArray *contactQueue;
@property NSTimeInterval timePerMove;
@property NSTimeInterval timeOfLastMove;
@property NSTimeInterval timeOfLastInvaderBullet;
@property CGFloat timeOfInvaderBullet;
@property InvaderMovementDirection invaderMovementDirection;
@property NSUInteger burstSize;
@property InvaderStrategy invaderStrategy;
@property NSUInteger earlierScore;
@end



@implementation GameScene

#pragma mark - Object Lifecycle Management

- (id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        NSLog(@"Scene Size: %@", NSStringFromCGSize(size));
        
        _tapQueue = [NSMutableArray array];
        _contactQueue = [NSMutableArray array];
        
        _invaderMovementDirection = InvaderMovementDirectionRight;
        _timePerMove = kInvaderMaxTimePerMove;
        _timeOfLastMove = 0.f;
        _timeOfLastInvaderBullet = 0.f;
        _timeOfInvaderBullet = kInvaderMaxBulletTime;
        _burstSize = kShipBurstCapacity;
        _invaderStrategy = kInvaderStrategy;
        _numberOfInvaderRows = kInvaderRowCountDefault;
        _shipHealth = kShipMaxHealth;
    }
    
    return self;
}

#pragma mark - Scene Setup and Content Creation

- (void)didMoveToView:(SKView *)view
{
    if (!self.contentCreated) {
        [self createContent];
        self.earlierScore = self.score;
        self.contentCreated = YES;

        self.motionManager = [[CMMotionManager alloc] init];
        [self.motionManager startAccelerometerUpdates];
    }
}


- (void)createContent
{
    self.userInteractionEnabled = YES;
    self.physicsWorld.contactDelegate = self;
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    self.physicsBody.categoryBitMask = kSceneEdgeCategory;

    [self setupInvaders];
    [self setupShip];
    [self setupHud];
}


- (void)setupInvaders
{
    CGPoint baseOrigin = CGPointMake(kInvaderSize.width / 2, 180);

    for (NSUInteger row = 0; row < self.numberOfInvaderRows; ++row) {
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


- (NSArray *)loadInvaderTexturesOfType:(InvaderType)invaderType
{
    NSString *prefix;
    SKColor *invaderColor;

    switch (invaderType) {
        case InvaderTypeA:
            prefix = @"InvaderA";
            invaderColor = [SKColor redColor];
            break;

        case InvaderTypeB:
            prefix = @"InvaderB";
            invaderColor = [SKColor greenColor];            
            break;

        case InvaderTypeC:
        default:
            prefix = @"InvaderC";
            invaderColor = [SKColor blueColor];
            break;
    }
    
    UIImage *image = [[UIImage imageNamed:[NSString stringWithFormat:@"%@_00.png", prefix] ] imageTintedOfColor:invaderColor];
    SKTexture *texture_00 = [SKTexture textureWithImage:[image imageByScalingToSize:kInvaderSize]];
    image = [[UIImage imageNamed:[NSString stringWithFormat:@"%@_01.png", prefix] ] imageTintedOfColor:invaderColor];
    SKTexture *texture_01 = [SKTexture textureWithImage:[image imageByScalingToSize:kInvaderSize]];

    return @[texture_00, texture_01];
}


- (SKNode *)makeInvaderOfType:(InvaderType)invaderType
{
    NSArray *invaderTextures = [self loadInvaderTexturesOfType:invaderType];

    SKSpriteNode *invader = [SKSpriteNode spriteNodeWithTexture:[invaderTextures firstObject]];
    invader.name = kInvaderName;

    [invader runAction:[SKAction repeatActionForever:[SKAction animateWithTextures:invaderTextures timePerFrame:self.timePerMove]]];

    invader.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:invader.frame.size];
    invader.physicsBody.dynamic = NO;
    invader.physicsBody.categoryBitMask = kInvaderCategory;
    invader.physicsBody.contactTestBitMask = 0x0;
    invader.physicsBody.collisionBitMask = 0x0;
    invader.physicsBody.restitution = 0.0;
    
    return invader;
}


- (void)setupShip
{
    SKNode *ship = [self makeShip];
    ship.position = CGPointMake(self.size.width / 2.0f, kShipSize.height / 2.0f);
    [self addChild:ship];
}


- (SKNode *)makeShip
{
    SKSpriteNode *ship = [SKSpriteNode spriteNodeWithImageNamed:@"Ship.png"];

    ship.name = kShipName;
    ship.color = [UIColor greenColor];
    ship.colorBlendFactor = 1.0f;
    ship.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ship.frame.size];
    ship.physicsBody.dynamic = YES;
    ship.physicsBody.affectedByGravity = NO;
    ship.physicsBody.mass = 0.02;
    ship.physicsBody.categoryBitMask = kShipCategory;
    ship.physicsBody.contactTestBitMask = 0x0;
    ship.physicsBody.collisionBitMask = kSceneEdgeCategory;

    return ship;
}


- (void)setupHud
{
    SKLabelNode *scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];

    scoreLabel.name = kScoreHudName;
    scoreLabel.fontSize = 15;
    scoreLabel.fontColor = [SKColor greenColor];
    scoreLabel.text = [NSString stringWithFormat:kScoreHudText, self.score];
    scoreLabel.position = CGPointMake(20 + scoreLabel.frame.size.width / 2, self.size.height - (20 + scoreLabel.frame.size.height / 2));
    [self addChild:scoreLabel];

    SKLabelNode *healthLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
    healthLabel.name = kHealthHudName;
    healthLabel.fontSize = 15;
    healthLabel.fontColor = [SKColor redColor];
    healthLabel.text = [NSString stringWithFormat:kHealthHudText, self.shipHealth * 100.0f];
    healthLabel.position = CGPointMake(self.size.width - healthLabel.frame.size.width / 2 - 20, self.size.height - (20 + healthLabel.frame.size.height / 2));
    [self addChild:healthLabel];
}


- (SKNode *)makeBulletOfType:(BulletType)bulletType
{
    SKNode *bullet;

    switch (bulletType) {
        case ShipFiredBulletType:
            bullet = [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:kBulletSize];
            bullet.name = kShipFiredBulletName;
            bullet.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bullet.frame.size];
            bullet.physicsBody.dynamic = YES;
            bullet.physicsBody.affectedByGravity = NO;
            bullet.physicsBody.categoryBitMask = kShipFiredBulletCategory;
            bullet.physicsBody.contactTestBitMask = kInvaderCategory;
            bullet.physicsBody.collisionBitMask = 0x0;
            break;

        case InvaderFiredBulletType:
            bullet = [SKSpriteNode spriteNodeWithColor:[SKColor magentaColor] size:kBulletSize];
            bullet.name = kInvaderFiredBulletName;
            bullet.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:bullet.frame.size];
            bullet.physicsBody.dynamic = YES;
            bullet.physicsBody.affectedByGravity = NO;
            bullet.physicsBody.categoryBitMask = kInvaderFiredBulletCategory;
            bullet.physicsBody.contactTestBitMask = kShipCategory;
            bullet.physicsBody.collisionBitMask = 0x0;
            break;

        default:
            bullet = nil;
            break;
    }


    return bullet;
}


#pragma mark - Scene Update

- (void)update:(NSTimeInterval)currentTime
{
    if ([self isGameOver]) {
        [self endGameWinning:false];
        return;
    }
    else if ([self isGameWin]) {
        [self endGameWinning:true];
        return;
    }
    
    [self moveInvadersForUpdate:currentTime];
    [self processUserMotionForUpdate:currentTime];
    [self processUserTapsForUpdate:currentTime];
    [self fireInvaderBulletsForUpdate:currentTime];
    [self processContactsForUpdate:currentTime];
}


#pragma mark - Scene Update Helpers

- (void)moveInvadersForUpdate:(NSTimeInterval)currentTime
{
    if (currentTime - self.timeOfLastMove < self.timePerMove) return;

    [self determineInvaderMovementDirection];

    [self enumerateChildNodesWithName:kInvaderName usingBlock: ^(SKNode *node, BOOL *stop) {
        switch (self.invaderMovementDirection) {
            case InvaderMovementDirectionRight:
                node.position = CGPointMake(node.position.x + 10, node.position.y);
                break;

            case InvaderMovementDirectionLeft:
                node.position = CGPointMake(node.position.x - 10, node.position.y);
                break;

            case InvaderMovementDirectionDownThenLeft:
            case InvaderMovementDirectionDownThenRight:
                node.position = CGPointMake(node.position.x, node.position.y - 10);
                break;

            case InvaderMovementDirectionNone:
            default:
                break;
        }
    }];
    self.timeOfLastMove = currentTime;
}


- (void)processUserMotionForUpdate:(NSTimeInterval)currentTime
{
    SKSpriteNode *ship = (SKSpriteNode *)[self childNodeWithName:kShipName];
    CMAccelerometerData *data = self.motionManager.accelerometerData;

    if (fabs(data.acceleration.x) > 0.2) {
        [ship.physicsBody applyForce:CGVectorMake(40.0 * data.acceleration.x, 0)];
    }
}


- (void)processUserTapsForUpdate:(NSTimeInterval)currentTime
{
    for (NSNumber *tapCount in [self.tapQueue copy]) {
        if ([tapCount unsignedIntegerValue] == 1) {
            [self fireShipBullets];
        }

        [self.tapQueue removeObject:tapCount];
    }
}


- (void)processContactsForUpdate:(NSTimeInterval)currentTime
{
    for (SKPhysicsContact *contact in [self.contactQueue copy]) {
        [self handleContact:contact];
        [self.contactQueue removeObject:contact];
    }
}


#pragma mark - Invader Movement Helpers

- (void)determineInvaderMovementDirection
{
    __block InvaderMovementDirection proposedMovementDirection = self.invaderMovementDirection;

    [self enumerateChildNodesWithName:kInvaderName usingBlock: ^(SKNode *node, BOOL *stop) {
        switch (self.invaderMovementDirection) {
            case InvaderMovementDirectionRight:
                if (CGRectGetMaxX(node.frame) >= node.scene.size.width - 1.0f) {
                    proposedMovementDirection = InvaderMovementDirectionDownThenLeft;
                    *stop = YES;
                }

                break;

            case InvaderMovementDirectionLeft:
                if (CGRectGetMinX(node.frame) <= 1.0f) {
                    proposedMovementDirection = InvaderMovementDirectionDownThenRight;
                    *stop = YES;
                }

                break;

            case InvaderMovementDirectionDownThenLeft:
                proposedMovementDirection = InvaderMovementDirectionLeft;
                [self adjustInvaderMovementToTimePerMove];
                *stop = YES;
                break;
                
            case InvaderMovementDirectionDownThenRight:
                proposedMovementDirection = InvaderMovementDirectionRight;
                [self adjustInvaderMovementToTimePerMove];
                *stop = YES;
                break;
                
            default:
                break;
        }
    }];

    if (proposedMovementDirection != self.invaderMovementDirection) {
        self.invaderMovementDirection = proposedMovementDirection;
    }
}


- (void)adjustInvaderMovementToTimePerMove
{
    NSTimeInterval newTimePerMove = self.timePerMove * kInvaderReductionOfTime;
    if (newTimePerMove < kInvaderMinTimePerMove) return;
    
    double ratio = self.timePerMove / newTimePerMove;
    self.timePerMove = newTimePerMove;

    [self enumerateChildNodesWithName:kInvaderName usingBlock: ^(SKNode *node, BOOL *stop) {
        node.speed = node.speed * ratio;
    }];
}



#pragma mark - Bullet Helpers

- (void)fireBullet:(SKNode *)bullet toDestination:(CGPoint)destination withDuration:(NSTimeInterval)duration soundFileName:(NSString *)soundFileName
{
    SKAction *bulletAction = [SKAction sequence:@[[SKAction moveTo:destination duration:duration],
                                                  [SKAction waitForDuration:3.0 / 60.0],
                                                  [SKAction removeFromParent]]];

    SKAction *soundAction  = [SKAction playSoundFileNamed:soundFileName waitForCompletion:YES];

    [bullet runAction:[SKAction group:@[bulletAction, soundAction]]];

    [self addChild:bullet];
}


- (void)fireShipBullets
{
    SKNode *ship = [self childNodeWithName:kShipName];
    SKNode *bullet = [self makeBulletOfType:ShipFiredBulletType];
    
    bullet.position = CGPointMake(ship.position.x, ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2);
    CGPoint bulletDestination = CGPointMake(ship.position.x, self.frame.size.height + bullet.frame.size.height / 2);

    [self fireBullet:bullet toDestination:bulletDestination withDuration:1.0 soundFileName:@"ShipBullet.wav"];

}


- (void)fireInvaderBulletsForUpdate:(NSTimeInterval)currentTime
{
    SKNode *existingBullet = [self childNodeWithName:kInvaderFiredBulletName];

    if (!existingBullet) {
        NSMutableArray *allInvaders = [NSMutableArray array];
        [self enumerateChildNodesWithName:kInvaderName usingBlock: ^(SKNode *node, BOOL *stop) {
            if (CGRectContainsPoint(self.frame, node.position)) {
                [allInvaders addObject:node];
            }
        }];

        if ([allInvaders count] > 0) {
            NSUInteger index = [self indexOfAnInvader:allInvaders];
            SKNode *invader = [allInvaders objectAtIndex:index];

            SKNode *bullet = [self makeBulletOfType:InvaderFiredBulletType];
            bullet.position = CGPointMake(invader.position.x, invader.position.y - invader.frame.size.height / 2 + bullet.frame.size.height / 2);

            CGPoint bulletDestination = CGPointMake(invader.position.x, -bullet.frame.size.height / 2);
            
            [self adjustInvaderBulletTimeWithCurrentTime:currentTime];
            [self fireBullet:bullet toDestination:bulletDestination withDuration:self.timeOfInvaderBullet soundFileName:@"InvaderBullet.wav"];
        }
    }
}


- (NSInteger)indexOfAnInvader:(NSArray *)allInvaders
{
    __block NSInteger index = 0;
    __block SKNode *ship = [self childNodeWithName:kShipName];
    
    
    switch (self.invaderStrategy) {
        case InvaderStrategyRandom:
            index = arc4random_uniform([allInvaders count]);
            break;

        case InvaderStrategyCol:
            {
                __block CGFloat minDistanceX = CGFLOAT_MAX;
                __block CGFloat minDistanceY = CGFLOAT_MAX;

                [allInvaders enumerateObjectsUsingBlock:^(SKNode *invader, NSUInteger idx, BOOL *stop) {
                    CGFloat distanceX = fabs(invader.position.x - ship.position.x);
                    CGFloat distanceY = fabs(invader.position.y - ship.position.y);
                    if (distanceX < minDistanceX) {
                        minDistanceX = distanceX;
                        minDistanceY = distanceY;
                        index = idx;
                    }
                    else if (distanceX == minDistanceX && distanceY < minDistanceY) {
                        minDistanceY = distanceY;
                        index = idx;
                    }
                }];
            }
            break;
            
        case InvaderStrategyMotion:
            {
                __block CGFloat minDistanceX = CGFLOAT_MAX;
                __block CGFloat minDistanceY = CGFLOAT_MAX;
                __block CGPoint target = CGPointMake(ship.position.x + ship.physicsBody.velocity.dx, ship.position.y);
                
                [allInvaders enumerateObjectsUsingBlock:^(SKNode *invader, NSUInteger idx, BOOL *stop) {
                    CGFloat distanceX = fabs(invader.position.x - target.x);
                    CGFloat distanceY = fabs(invader.position.y - target.y);
                    if (distanceX < minDistanceX) {
                        minDistanceX = distanceX;
                        minDistanceY = distanceY;
                        index = idx;
                    }
                    else if (distanceX == minDistanceX && distanceY < minDistanceY) {
                        minDistanceY = distanceY;
                        index = idx;
                    }
                }];
                
            }
            break;
            
        case InvaderStrategyDistance:
        default:
            {
                __block CGFloat minDistance = CGFLOAT_MAX;

                [allInvaders enumerateObjectsUsingBlock:^(SKNode *invader, NSUInteger idx, BOOL *stop) {
                    CGFloat distance = rwLength(rwSub(invader.position, ship.position));
                    if (distance < minDistance) {
                        minDistance = distance;
                        index = idx;
                    }
                }];
            }
            break;
    }

    return index;
}


- (void)adjustInvaderBulletTimeWithCurrentTime:(NSTimeInterval)currentTime
{
    NSTimeInterval newTime = self.timeOfInvaderBullet*kInvaderReductionOfBulletTime;

    if (newTime < kInvaderMinTimePerMove) return;
    if (currentTime - self.timeOfLastInvaderBullet < kInvaderBulletTimeAdjustmentInterval) return;
    
    self.timeOfLastInvaderBullet = currentTime;
    self.timeOfInvaderBullet = newTime;
}


#pragma mark - User Tap Helpers

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
    UITouch *touch = [touches anyObject];
    if (touch.tapCount <= self.burstSize) [self.tapQueue addObject:@1];
}


#pragma mark - HUD Helpers

- (void)adjustScoreBy:(NSUInteger)points
{
    self.score += points;
    SKLabelNode *score = (SKLabelNode *)[self childNodeWithName:kScoreHudName];
    score.text = [NSString stringWithFormat:kScoreHudText, self.score];
}


- (void)adjustShipHealthBy:(CGFloat)healthAdjustment
{
    self.shipHealth = MAX(self.shipHealth + healthAdjustment, 0);
    SKLabelNode *health = (SKLabelNode *)[self childNodeWithName:kHealthHudName];
    health.text = [NSString stringWithFormat:kHealthHudText, self.shipHealth * 100];
}


#pragma mark - Physics Contact Helpers

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    [self.contactQueue addObject:contact];
}


- (void)handleContact:(SKPhysicsContact *)contact
{
    if (!contact.bodyA.node.parent || !contact.bodyB.node.parent) return;

    NSArray *nodeNames = @[contact.bodyA.node.name, contact.bodyB.node.name];

    if ([nodeNames containsObject:kShipName] && [nodeNames containsObject:kInvaderFiredBulletName]) {
        [self runAction:[SKAction playSoundFileNamed:@"ShipHit.wav" waitForCompletion:NO]];

        [self adjustShipHealthBy:-0.25f];

        if (self.shipHealth <= 0.0f) {
            [contact.bodyA.node removeFromParent];
            [contact.bodyB.node removeFromParent];
        }
        else {
            SKNode *ship = [self childNodeWithName:kShipName];
            ship.alpha = self.shipHealth;

            if (contact.bodyA.node == ship) [contact.bodyB.node removeFromParent];
            else [contact.bodyA.node removeFromParent];
        }
    }
    else if ([nodeNames containsObject:kInvaderName] && [nodeNames containsObject:kShipFiredBulletName]) {
        SKNode *node;
        if ([contact.bodyA.node.name isEqualToString:kInvaderName]) {node = contact.bodyA.node; }
        else node = contact.bodyB.node;

        if (CGRectContainsPoint(self.frame, node.position)) {
            [self runAction:[SKAction playSoundFileNamed:@"InvaderHit.wav" waitForCompletion:NO]];
            [contact.bodyA.node removeFromParent];
            [contact.bodyB.node removeFromParent];

            [self adjustScoreBy:100];
        }
    }
}


#pragma mark - Game End Helpers

- (BOOL)isGameOver
{
    __block BOOL invaderTooLow = NO;

    [self enumerateChildNodesWithName:kInvaderName usingBlock: ^(SKNode *node, BOOL *stop) {
        if (CGRectGetMinY(node.frame) <= kMinInvaderBottomHeight) {
            invaderTooLow = YES;
            *stop = YES;
        }
    }];

    SKNode *ship = [self childNodeWithName:kShipName];
    return invaderTooLow || !ship;
}


- (BOOL)isGameWin
{
    SKNode *invader = [self childNodeWithName:kInvaderName];
    SKNode *ship = [self childNodeWithName:kShipName];
    return !invader && ship && self.score > 0;
}



- (void)endGameWinning:(BOOL)winning
{
    if (!self.gameEnding) {
        self.gameEnding = YES;

        [self.motionManager stopAccelerometerUpdates];
        
        SKScene *scene = winning ? [[YouWinScene alloc] initWithSize:self.size] : [[GameOverScene alloc] initWithSize:self.size];
        scene.userData = [NSMutableDictionary dictionary];
        scene.userData[@"score"] = @(self.score);
        scene.userData[@"earlierScore"] = @(self.earlierScore);
        scene.userData[@"shipHealth"] = @(self.shipHealth);
        scene.userData[@"numberOfInvaderRows"] = @(self.numberOfInvaderRows);
        
        [self.view presentScene:scene transition:[SKTransition doorsOpenHorizontalWithDuration:1.0]];
    }
}



#pragma mark - Math helpers

static inline CGPoint rwAdd(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}


static inline CGPoint rwSub(CGPoint a, CGPoint b)
{
    return CGPointMake(a.x - b.x, a.y - b.y);
}


static inline CGPoint rwMult(CGPoint a, float b)
{
    return CGPointMake(a.x * b, a.y * b);
}


static inline float rwLength(CGPoint a)
{
    return sqrtf(a.x * a.x + a.y * a.y);
}


// Makes a vector have a length of 1
static inline CGPoint rwNormalize(CGPoint a)
{
    float length = rwLength(a);    
    return CGPointMake(a.x / length, a.y / length);
}



@end
