//
//  Ball_withSprite.m
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "Ball_withSprite.h"

/**
 * Ball is-a CCPhysics sprite.
 */
@implementation Ball_withSprite

- (id) initWithSprite:(NSString *)name pos:(CGPoint)pos world:(b2World *)world {
    if ((self = [super initWithSpriteFrameName:name])) {
        //define the body
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position.Set(pos.x/PTM_RATIO, pos.y/PTM_RATIO);
        b2Body *body = world->CreateBody(&bodyDef);
        
        //define the body's shape
        b2CircleShape shape;
        shape.m_radius = self.contentSize.width / PTM_RATIO / 2;
        
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

@end
