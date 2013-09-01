//
//  MainLayer.mm
//  SquishyBalls
//
//  Created by Justin on 8/25/13.
//  Copyright Saturnboy 2013. All rights reserved.
//

#import "MainLayer.h"
#import "CCPhysicsSprite.h"

#define BATCH_TAG 123

#pragma mark - MainLayer

@interface MainLayer()
-(void) createWorld;
-(void) createGround;
-(void) createFunnel;
-(void) addBall:(CGPoint)pos;
@end

@implementation MainLayer

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
        
        //init physics
        [self createWorld];
        [self createGround];
        
        // load spritesheet
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"balls.plist"];
        
        // load texture into batch node to optimize rendering
        CCSpriteBatchNode *batch = [CCSpriteBatchNode batchNodeWithFile:@"balls.png" capacity:50];
        [self addChild:batch z:0 tag:BATCH_TAG];
        

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

-(void) draw {
    //NOTE: only for debug draw, disable this in a real app
    [super draw];
    ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
    kmGLPushMatrix();
    _world->DrawDebugData();
    kmGLPopMatrix();
}

-(void) addBall:(CGPoint)pos {
    CCLOG(@"ADD BALL: %.1f,%.1f", pos.x, pos.y);
    
    //get the sprite
    NSString *name = (CCRANDOM_0_1() < 0.2 ? @"ball-pink.png" : @"ball.png");
    CCPhysicsSprite *ball = [CCPhysicsSprite spriteWithSpriteFrameName:name];
    
    //define the body
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(pos.x/PTM_RATIO, pos.y/PTM_RATIO);
    b2Body *body = _world->CreateBody(&bodyDef);
    
    //define the body's shape
    //b2PolygonShape dynamicBox;
    //dynamicBox.SetAsBox(radius,radius);
    b2CircleShape shape;
    shape.m_radius = ball.contentSize.width / PTM_RATIO / 2;
    
    //define the body's fixture
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.density = 1.0f;
    fixtureDef.friction = 0.3f;
    body->CreateFixture(&fixtureDef);
    
    //find the batch node, add ball as child
    CCNode *batch = [self getChildByTag:BATCH_TAG];
    [batch addChild:ball];
    
    [ball setPTMRatio:PTM_RATIO];
    [ball setB2Body:body];
    [ball setPosition:ccp(pos.x,pos.y)];
}

-(void) update:(ccTime) dt {
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
        [self addBall:pos];
    }
}

@end
