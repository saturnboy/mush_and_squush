//
//  Ball_withDrawNode.m
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "Ball_withDrawNode.h"

/**
 * Ball is-a CCDrawNode, thus can't be part of a CCSpriteBatchNode, but draw calls are themselves batched.
 * Since we extend CCDrawNode, we must also impl the CCPhysicsNode methods here directly.
 */
@implementation Ball_withDrawNode {
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
        
        ccColor4F color = ccc4f(113.0f/255.0f, 202.0f/255.0f, 53.0f/255.0f, 1.0f);
        [self drawDot:ccp(0,0) radius:_radius color:color];
         
    }
    return self;
}

/*** borrowed directly from CCPhysicsSprite.mm ***/
-(CGPoint)position {
	b2Vec2 pos  = _b2Body->GetPosition();
    
	float x = pos.x * _PTMRatio;
	float y = pos.y * _PTMRatio;
	return ccp(x,y);
}

-(void)setPosition:(CGPoint)position {
	float angle = _b2Body->GetAngle();
	_b2Body->SetTransform( b2Vec2(position.x / _PTMRatio, position.y / _PTMRatio), angle );
}

-(float)rotation {
	return (_ignoreBodyRotation ? super.rotation :
			CC_RADIANS_TO_DEGREES( _b2Body->GetAngle() ) );
}

-(void)setRotation:(float)rotation {
	if(_ignoreBodyRotation){
		super.rotation = rotation;
	} else {
		b2Vec2 p = _b2Body->GetPosition();
		float radians = CC_DEGREES_TO_RADIANS(rotation);
		_b2Body->SetTransform( p, radians);
	}
}

// returns the transform matrix according the Chipmunk Body values
-(CGAffineTransform) nodeToParentTransform {
	b2Vec2 pos  = _b2Body->GetPosition();
    
	float x = pos.x * _PTMRatio;
	float y = pos.y * _PTMRatio;
    
	if ( _ignoreAnchorPointForPosition ) {
		x += _anchorPointInPoints.x;
		y += _anchorPointInPoints.y;
	}
    
	// Make matrix
	float radians = _b2Body->GetAngle();
	float c = cosf(radians);
	float s = sinf(radians);
    
	// Although scale is not used by physics engines, it is calculated just in case
	// the sprite is animated (scaled up/down) using actions.
	// For more info see: http://www.cocos2d-iphone.org/forum/topic/68990
	if( ! CGPointEqualToPoint(_anchorPointInPoints, CGPointZero) ){
		x += c*-_anchorPointInPoints.x * _scaleX + -s*-_anchorPointInPoints.y * _scaleY;
		y += s*-_anchorPointInPoints.x * _scaleX + c*-_anchorPointInPoints.y * _scaleY;
	}
    
	// Rot, Translate Matrix
	_transform = CGAffineTransformMake( c * _scaleX,	s * _scaleX,
									   -s * _scaleY,	c * _scaleY,
									   x,	y );
    
	return _transform;
}

-(BOOL) dirty {
	return YES;
}

@end
