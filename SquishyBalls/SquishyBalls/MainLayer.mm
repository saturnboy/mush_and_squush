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
    BOOL _debugging;
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
        _debugging = NO;
        
        //build the box2d world
        [self createWorld];
        [self createGround];
        //[self createFunnel];
        
        //load textures (these *MUST* be POT textures for orig, -hd, -ipad, -ipadhd)
        [[CCTextureCache sharedTextureCache] addImage:@"ball.png"];
        [[CCTextureCache sharedTextureCache] addImage:@"ball-50.png"];
        [[CCTextureCache sharedTextureCache] addImage:@"crate.png"];
        [[CCTextureCache sharedTextureCache] addImage:@"crate-50.png"];
        
        [[CCTextureCache sharedTextureCache] dumpCachedTextureInfo];

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
    [super draw];
    if (_debugging) {
        ccGLEnableVertexAttribs(kCCVertexAttribFlag_Position);
        kmGLPushMatrix();
        _world->DrawDebugData();
        kmGLPopMatrix();
    }
}

-(void) addBall:(CGPoint)pos {
    CCLOG(@"ADD BALL %.1f,%.1f", pos.x, pos.y);
    SoftBall *ball = [[SoftBall alloc] initWithName:(_debugging ? @"ball-50.png" : @"ball.png") pos:pos world:_world];
    [self addChild:ball];
}

-(void) addCrate:(CGPoint)pos {
    CCLOG(@"ADD CRATE %.1f,%.1f", pos.x, pos.y);
    SoftBox *box = [[SoftBox alloc] initWithName:(_debugging ? @"crate-50.png" : @"crate.png") pos:pos world:_world];
    [self addChild:box];
}

-(void) update:(ccTime)dt {
    _world->Step(dt, 8, 2);
}

- (void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint pos = [touch locationInView:[touch view]];
        pos = [[CCDirector sharedDirector] convertToGL:pos];
        
        //pick ball or crate at random
        if (CCRANDOM_0_1() < 0.8f) {
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
    //stop everything
    [self unscheduleUpdate];
    self.touchEnabled = NO;
    self.accelerometerEnabled = NO;
    
    //destory the entire world (are we leaking here?)
    delete _world;
    _world = NULL;
    
    //remove all children
    [self removeAllChildrenWithCleanup:YES];
    
    //toggle debugging
    _debugging = (_debugging ? NO : YES);
    CCLOG(@"DEBUGGING is now %@", _debugging ? @"ON" : @"OFF");
    
    //rebuild the world
    [self createWorld];
    [self createGround];
    //[self createFunnel];
    
    //restart everything after a 500ms delay
    [self performSelector:@selector(restart) withObject:nil afterDelay:0.5f];
}

- (void) restart {
    _shaking = NO;
    self.touchEnabled = YES;
    self.accelerometerEnabled = YES;
    [self scheduleUpdate];
}

@end
