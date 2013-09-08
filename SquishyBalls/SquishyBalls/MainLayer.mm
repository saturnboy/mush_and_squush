//
//  MainLayer.mm
//  SquishyBalls
//
//  Created by Justin on 8/25/13.
//  Copyright Saturnboy 2013. All rights reserved.
//

#import "MainLayer.h"
#import "SoftBall.h"
#import "SoftBox.h"

#define BATCH_TAG 123
#define SHAKE_ACCEL 1.9f

#pragma mark - MainLayer

@interface MainLayer()
-(void) createWorld;
-(void) createGround;
-(void) createFunnel;
-(void) addBall:(CGPoint)pos;
-(void) addCrate:(CGPoint)pos;
@end

@implementation MainLayer {
    BOOL _shaking;
}

+(CCScene *) scene {
    CCScene *scene = [CCScene node];
    MainLayer *layer = [MainLayer node];
    [scene addChild:layer];
    return scene;
}

-(id) init {
    if ((self = [super init])) {
        self.touchEnabled = YES;
        self.accelerometerEnabled = YES;
        _shaking = NO;
        
        //build the box2d world
        [self createWorld];
        [self createGround];
        [self createFunnel];
        
        //load spritesheet
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"softy.plist"];

        [self scheduleUpdate];
    }
    return self;
}

-(void) dealloc {
    delete _world;
    _world = NULL;
    
    delete _debug;
    _debug = NULL;
    
    [super dealloc];
}

-(void) createWorld {
    b2Vec2 gravity(0.0f, -10.0f);
    _world = new b2World(gravity);
    _world->SetAllowSleeping(true);
    _world->SetContinuousPhysics(true);
    
    _debug = new GLESDebugDraw(PTM_RATIO);
    _debug->SetFlags(b2Draw::e_shapeBit + b2Draw::e_jointBit);
    _world->SetDebugDraw(_debug);
}

-(void) createGround {
    CGSize winsize = [CCDirector sharedDirector].winSize;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    bodyDef.position.Set(0, 0);
    b2Body* body = _world->CreateBody(&bodyDef);

    //define the shape
    b2EdgeShape shape;
    
    // bottom
    shape.Set(b2Vec2(0,0), b2Vec2(winsize.width/PTM_RATIO,0));
    body->CreateFixture(&shape,0);
    
    // top
    shape.Set(b2Vec2(0,winsize.height/PTM_RATIO), b2Vec2(winsize.width/PTM_RATIO,winsize.height/PTM_RATIO));
    body->CreateFixture(&shape,0);
    
    // left
    shape.Set(b2Vec2(0,winsize.height/PTM_RATIO), b2Vec2(0,0));
    body->CreateFixture(&shape,0);
    
    // right
    shape.Set(b2Vec2(winsize.width/PTM_RATIO,winsize.height/PTM_RATIO), b2Vec2(winsize.width/PTM_RATIO,0));
    body->CreateFixture(&shape,0);
}

-(void) createFunnel {
    CGSize winsize = [CCDirector sharedDirector].winSize;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    bodyDef.position.Set(0, 0);
    b2Body* body = _world->CreateBody(&bodyDef);
	
    b2EdgeShape shape;
	
    //right
    shape.Set(b2Vec2(winsize.width*0.667/PTM_RATIO, 0), b2Vec2(winsize.width/PTM_RATIO, winsize.height/2/PTM_RATIO));
    body->CreateFixture(&shape,0);
	
    //left
    shape.Set(b2Vec2(winsize.width*0.333/PTM_RATIO, 0), b2Vec2(0, winsize.height/2/PTM_RATIO));
    body->CreateFixture(&shape,0);
}

-(void) draw {
    //NOTE: only for debug draw, disable this in a real app
    [super draw];
    ccGLEnableVertexAttribs(kCCVertexAttribFlag_Position);
    kmGLPushMatrix();
    _world->DrawDebugData();
    kmGLPopMatrix();
}

-(void) addBall:(CGPoint)pos {
    CCLOG(@"ADD BALL %.1f,%.1f", pos.x, pos.y);
    SoftBall *ball = [[SoftBall alloc] initWithName:@"ball.png" pos:pos world:_world];
    [self addChild:ball];
}

-(void) addCrate:(CGPoint)pos {
    CCLOG(@"ADD CRATE %.1f,%.1f", pos.x, pos.y);
    SoftBox *box = [[SoftBox alloc] initWithName:@"crate.png" pos:pos world:_world];
    [self addChild:box];
}

-(void) update:(ccTime)dt {
    //It is recommended that a fixed time step is used with Box2D for stability
    //of the simulation, however, we are using a variable time step here.
    //You need to make an informed choice, the following URL is useful
    //http://gafferongames.com/game-physics/fix-your-timestep/
    
    int32 velocityIterations = 8;
    int32 positionIterations = 2;
    
    // Instruct the world to perform a single step of simulation. It is
    // generally best to keep the time step and iterations fixed.
    _world->Step(dt, velocityIterations, positionIterations);
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //new ball for every touch
    for ( UITouch *touch in touches ) {
        CGPoint pos = [touch locationInView:[touch view]];
        pos = [[CCDirector sharedDirector] convertToGL:pos];
        
        if (CCRANDOM_0_1() < 0.8) {
            [self addBall:pos];
        } else {
            [self addCrate:pos];
        }
    }
}

-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
    if (!_shaking) {
        if (acceleration.x > SHAKE_ACCEL || acceleration.x < -SHAKE_ACCEL ||
            acceleration.y > SHAKE_ACCEL || acceleration.y < -SHAKE_ACCEL ||
            acceleration.z > SHAKE_ACCEL || acceleration.z < -SHAKE_ACCEL) {
            _shaking = YES;
            [self reset];
        }
    }
}

-(void) reset {
    [self unscheduleUpdate];
    
    //just destory the entire world (probably leaking...)
    delete _world;
    _world = NULL;
    
    //remove any children
    for (CCNode *child in self.children) {
        if ([child isKindOfClass:[SoftBall class]]) {
            [self removeChild:child];
        } else if ([child isKindOfClass:[SoftBox class]]) {
            [self removeChild:child];
        }
    }
    
    //rebuild the world
    [self createWorld];
    [self createGround];
    [self createFunnel];
    
    _shaking = NO;
    
    [self scheduleUpdate];
}

@end
