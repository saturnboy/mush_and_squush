//
//  SoftBall.mm
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "SoftBall.h"
#import <vector>

#define NUM_EDGES 8

@implementation SoftBall {
    NSString *_name;
    b2Body *_center;
    std::vector<b2Body*> _verts;
    std::vector<b2Joint*> _edges;
    std::vector<b2Joint*> _spokes;
}

- (id) initWithName:(NSString *)name pos:(CGPoint)pos world:(b2World *)world {
    if ((self = [super init])) {
        _name = name;
        
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:name];
        CCLOG(@"IMAGE %@ %.1fx%.1f", name, frame.rect.size.width, frame.rect.size.height);
        
        float vertRadius = frame.rect.size.width / 8.0f;
        float centerRadius = vertRadius * 0.6f;
        float R = (frame.rect.size.width / 2.0f - vertRadius) / PTM_RATIO;
        CCLOG(@"RADIUS %.3f", R);
        CCLOG(@"VERT RADIUS %.3f", vertRadius);
        CCLOG(@"CENTER RADIUS %.3f", centerRadius);

        
        b2Vec2 center = b2Vec2(pos.x/PTM_RATIO, pos.y/PTM_RATIO);
        CCLOG(@"CENTER (%.3f,%.3f)", center.x, center.y);
        
        //first, the center body
        b2CircleShape shape;
        shape.m_radius = centerRadius / PTM_RATIO;
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position = center;
        bodyDef.angularDamping = 1.0f;
        
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &shape;
        fixtureDef.density = 0.1f;
        fixtureDef.friction = 0.7f;
        fixtureDef.restitution = 0.03f;
        
        _center = world->CreateBody(&bodyDef);
        _center->CreateFixture(&fixtureDef);
        
        //next, all the vertex bodies
        shape.m_radius = vertRadius / PTM_RATIO;
        for (int i = 0; i < NUM_EDGES; i++) {
            float theta = i * 2.0f * M_PI / NUM_EDGES;
            b2Vec2 vertPos = b2Vec2(R * cosf(theta), R * sinf(theta)) + center;
            CCLOG(@"EDGE%d theta=%.3f (%.3f,%.3f)", i, theta, vertPos.x, vertPos.y);
            
            //only the vertex pos changes
            bodyDef.position = vertPos;
            
            b2Body *body = world->CreateBody(&bodyDef);
            body->CreateFixture(&fixtureDef);
            
            _verts.push_back(body);
        }
        
        //last, make all the joints (edges & spokes)
        b2DistanceJointDef jointDef;
        for (int i = 0; i < NUM_EDGES; i++) {
            //joints between verts (aka the edges)
            int j = (i == 0 ? NUM_EDGES-1 : i-1);
            jointDef.Initialize(_verts[i], _verts[j], _verts[i]->GetPosition(), _verts[j]->GetPosition());
            jointDef.collideConnected = true;
            jointDef.frequencyHz = 8.0f;
            jointDef.dampingRatio = 0.6f;
            b2Joint *edge = world->CreateJoint(&jointDef);
            _edges.push_back(edge);
            
            //joints between vert and center (aka the spokes)
            jointDef.Initialize(_verts[i], _center, _verts[i]->GetPosition(), center);
            jointDef.collideConnected = true;
            jointDef.frequencyHz = 8.0f;
            jointDef.dampingRatio = 0.6f;
            b2Joint *spoke = world->CreateJoint(&jointDef);
            _spokes.push_back(spoke);
        }
    }
    return self;
}

@end
