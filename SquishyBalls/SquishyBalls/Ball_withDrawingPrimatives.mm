//
//  Ball_withDrawingPrimatives.mm
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "Ball_withDrawingPrimatives.h"

/**
 * Ball is-a CCPhysicsSprite, but drawing is done via CCDrawingPrimatives in draw method override.
 * Can't be batched in a CCSpriteBatchNode.
 */
@implementation Ball_withDrawingPrimatives {
    float _radius;
}

- (id) initWithPos:(CGPoint)pos radius:(float)radius world:(b2World *)world {
    if ((self = [super init])) {
        _radius = radius;
        
        //define the body
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position.Set(pos.x/PTM_RATIO, pos.y/PTM_RATIO);
        b2Body *body = world->CreateBody(&bodyDef);
        
        //define the body's shape
        b2CircleShape shape;
        shape.m_radius = _radius / PTM_RATIO;
        
        //define the body's fixture
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &shape;
        fixtureDef.density = 1.0f;
        fixtureDef.friction = 0.3f;
        fixtureDef.restitution = 0.5f;
        body->CreateFixture(&fixtureDef);
        
        [self setPTMRatio:PTM_RATIO];
        [self setB2Body:body];
        [self setPosition:ccp(pos.x,pos.y)];
    }
    return self;
}

-(void) draw {
    [super draw];
    ccDrawSolidCircle(ccp(0.0f,0.0f), _radius, 5);
}

@end
