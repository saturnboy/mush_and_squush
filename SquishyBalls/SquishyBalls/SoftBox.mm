//
//  SoftBox.mm
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "SoftBox.h"
#import <vector>

@implementation SoftBox {
    NSString *_name;
    b2Body* _center;
    std::vector<b2Body*> _verts;
    std::vector<b2Joint*> _edges;
    std::vector<b2Joint*> _spokes;
}

- (id) initWithName:(NSString *)name pos:(CGPoint)pos world:(b2World *)world {
    if ((self = [super init])) {
        _name = name;
        
        CCSpriteFrame *frame = [[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"ball.png"];
        CCLOG(@"%@ %.1fx%.1f", name, frame.rect.size.width, frame.rect.size.height);
        
        float vertRadius = frame.rect.size.width / 7.0f;
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
        
        //center right
        bodyDef.position = b2Vec2(R, 0.0f) + center;
        b2Body *cr = world->CreateBody(&bodyDef);
        cr->CreateFixture(&fixtureDef);
        _verts.push_back(cr);
        
        //top right
        bodyDef.position = b2Vec2(R, R) + center;
        b2Body *tr = world->CreateBody(&bodyDef);
        tr->CreateFixture(&fixtureDef);
        _verts.push_back(tr);

        //top center
        bodyDef.position = b2Vec2(0.0f, R) + center;
        b2Body *tc = world->CreateBody(&bodyDef);
        tc->CreateFixture(&fixtureDef);
        _verts.push_back(tc);
        
        //top left
        bodyDef.position = b2Vec2(-R, R) + center;
        b2Body *tl = world->CreateBody(&bodyDef);
        tl->CreateFixture(&fixtureDef);
        _verts.push_back(tl);
        
        //center left
        bodyDef.position = b2Vec2(-R, 0.0f) + center;
        b2Body *cl = world->CreateBody(&bodyDef);
        cl->CreateFixture(&fixtureDef);
        _verts.push_back(cl);
        
        //bottom left
        bodyDef.position = b2Vec2(-R, -R) + center;
        b2Body *bl = world->CreateBody(&bodyDef);
        bl->CreateFixture(&fixtureDef);
        _verts.push_back(bl);
        
        //bottom center
        shape.m_radius = vertRadius / PTM_RATIO;
        bodyDef.position = b2Vec2(0.0f, -R) + center;
        b2Body *bc = world->CreateBody(&bodyDef);
        bc->CreateFixture(&fixtureDef);
        _verts.push_back(bc);
        
        //bottom right
        shape.m_radius = vertRadius / PTM_RATIO;
        bodyDef.position = b2Vec2(R, -R) + center;
        b2Body *br = world->CreateBody(&bodyDef);
        br->CreateFixture(&fixtureDef);
        _verts.push_back(br);
        
        //last, make all the joints (edges & spokes)
        b2DistanceJointDef jointDef;
        for (int i = 0; i < _verts.size(); i++) {
            //joints between verts (aka the edges)
            int j = (i == 0 ? _verts.size()-1 : i-1);
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
