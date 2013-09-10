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
    CCTexture2D *_tex;
    b2Body *_center;
    std::vector<b2Body*> _verts;
    std::vector<b2Joint*> _edges;
    std::vector<b2Joint*> _spokes;
    float _vertRadius;
    float _vertRadiusDiag;
    ccVertex2F *_posCoords;
    ccVertex2F *_texCoords;
}

- (id) initWithName:(NSString *)name pos:(CGPoint)pos world:(b2World *)world {
    if ((self = [super init])) {
        _name = name;
        
        //init texture
        _tex = [[CCTextureCache sharedTextureCache] textureForKey:name];
        float W = _tex.pixelsWide / CC_CONTENT_SCALE_FACTOR();
        float H = _tex.pixelsHigh / CC_CONTENT_SCALE_FACTOR();
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTexture];
        CCLOG(@"TEXTURE %@ size=%dx%d scale=%.1f", name, _tex.pixelsWide, _tex.pixelsHigh, CC_CONTENT_SCALE_FACTOR());
        
        //compute various radii from texture width (scale width on retina)
        _vertRadius = W / 7.0f;
        _vertRadiusDiag = sqrtf(_vertRadius * _vertRadius * 2.0f);
        float centerRadius = _vertRadius * 0.6f;
        
        //subtract vertRadius to keep entire vert circle inside master ball
        float R = (W / 2.0f - _vertRadius) / PTM_RATIO;
        //CCLOG(@"RADIUS %.3f", R);
        //CCLOG(@"VERT RADIUS %.3f", _vertRadius);
        //CCLOG(@"CENTER RADIUS %.3f", centerRadius);
        
        //compute center pos
        CGSize sz = [[CCDirector sharedDirector] winSize];
        if (pos.x < W * 0.5f) {
            pos.x = W * 0.5f;
        } else if (pos.x > (sz.width - W * 0.5f)) {
            pos.x = sz.width - W * 0.5f;
        }
        if (pos.y < H * 0.5f) {
            pos.y = H * 0.5f;
        } else if (pos.y > (sz.height - H * 0.5f)) {
            pos.y = sz.height - H * 0.5f;
        }
        b2Vec2 centerPos = b2Vec2(pos.x/PTM_RATIO, pos.y/PTM_RATIO);
        //CCLOG(@"CENTER (%.3f,%.3f)", centerPos.x, centerPos.y);
        
        //first, the center body
        b2CircleShape shape;
        shape.m_radius = centerRadius / PTM_RATIO;
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position = centerPos;
        bodyDef.angularDamping = 5.0f;
        
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &shape;
        fixtureDef.density = 0.1f;
        fixtureDef.friction = 0.7f;
        fixtureDef.restitution = 0.03f;
        
        _center = world->CreateBody(&bodyDef);
        _center->CreateFixture(&fixtureDef);
        
        //next, all the vertex bodies
        shape.m_radius = _vertRadius / PTM_RATIO;
        
        //center right
        bodyDef.position = b2Vec2(R, 0.0f) + centerPos;
        b2Body *cr = world->CreateBody(&bodyDef);
        cr->CreateFixture(&fixtureDef);
        _verts.push_back(cr);
        
        //top right
        bodyDef.position = b2Vec2(R, R) + centerPos;
        b2Body *tr = world->CreateBody(&bodyDef);
        tr->CreateFixture(&fixtureDef);
        _verts.push_back(tr);

        //top center
        bodyDef.position = b2Vec2(0.0f, R) + centerPos;
        b2Body *tc = world->CreateBody(&bodyDef);
        tc->CreateFixture(&fixtureDef);
        _verts.push_back(tc);
        
        //top left
        bodyDef.position = b2Vec2(-R, R) + centerPos;
        b2Body *tl = world->CreateBody(&bodyDef);
        tl->CreateFixture(&fixtureDef);
        _verts.push_back(tl);
        
        //center left
        bodyDef.position = b2Vec2(-R, 0.0f) + centerPos;
        b2Body *cl = world->CreateBody(&bodyDef);
        cl->CreateFixture(&fixtureDef);
        _verts.push_back(cl);
        
        //bottom left
        bodyDef.position = b2Vec2(-R, -R) + centerPos;
        b2Body *bl = world->CreateBody(&bodyDef);
        bl->CreateFixture(&fixtureDef);
        _verts.push_back(bl);
        
        //bottom center
        bodyDef.position = b2Vec2(0.0f, -R) + centerPos;
        b2Body *bc = world->CreateBody(&bodyDef);
        bc->CreateFixture(&fixtureDef);
        _verts.push_back(bc);
        
        //bottom right
        bodyDef.position = b2Vec2(R, -R) + centerPos;
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
            jointDef.Initialize(_verts[i], _center, _verts[i]->GetPosition(), centerPos);
            jointDef.collideConnected = true;
            jointDef.frequencyHz = 8.0f;
            jointDef.dampingRatio = 0.6f;
            b2Joint *spoke = world->CreateJoint(&jointDef);
            _spokes.push_back(spoke);
        }
    }
    return self;
}

-(void) dealloc {
	free(_posCoords);
	free(_texCoords);
    _name = nil;
    _tex = nil;
    _center = nil;
    [super dealloc];
}

-(void) draw {
    int N = 10;
    
    //init my arrays
    if (_posCoords) {
        free(_posCoords);
    }
    if (_texCoords) {
        free(_texCoords);
    }
    _posCoords = (ccVertex2F *) malloc(sizeof(ccVertex2F) * N);
    _texCoords = (ccVertex2F *) malloc(sizeof(ccVertex2F) * N);
    
    //compute position coords (where my verts are in the pixel world)
    _posCoords[0] = (ccVertex2F) { _center->GetPosition().x * PTM_RATIO, _center->GetPosition().y * PTM_RATIO };
    for (int i = 0; i < 8; i++) {
        //compute dist between center and vert center
        float dx = _center->GetPosition().x - _verts[i]->GetPosition().x;
        float dy = _center->GetPosition().y - _verts[i]->GetPosition().y;
        float R = sqrtf(dx*dx + dy*dy) * PTM_RATIO;
        float r = (i % 2 == 0 ? _vertRadius : _vertRadiusDiag);
        
        //add vert radius to compute new vert (all the way to the edge)
        float x = (_verts[i]->GetPosition().x - _center->GetPosition().x) * (1 + r/R) * PTM_RATIO + _posCoords[0].x;
        float y = (_verts[i]->GetPosition().y - _center->GetPosition().y) * (1 + r/R) * PTM_RATIO + _posCoords[0].y;
        _posCoords[i+1] = (ccVertex2F) { x, y };
        //CCLOG(@"POS COORDS %d %.3f %.3f,%.3f", i+1, R, x, y);
    }
    _posCoords[N-1] = _posCoords[1];
    
    //compute texture coords (in range [0,1])
    _texCoords[0] = (ccVertex2F) { 0.5f, 0.5f };
    _texCoords[1] = (ccVertex2F) { 1.0f, 0.5f };
    _texCoords[2] = (ccVertex2F) { 1.0f, 1.0f };
    _texCoords[3] = (ccVertex2F) { 0.5f, 1.0f };
    _texCoords[4] = (ccVertex2F) { 0.0f, 1.0f };
    _texCoords[5] = (ccVertex2F) { 0.0f, 0.5f };
    _texCoords[6] = (ccVertex2F) { 0.0f, 0.0f };
    _texCoords[7] = (ccVertex2F) { 0.5f, 0.0f };
    _texCoords[8] = (ccVertex2F) { 1.0f, 0.0f };
    _texCoords[9] = _texCoords[1];
    
    CC_NODE_DRAW_SETUP();
    
    ccGLBindTexture2D(_tex.name);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    
    ccGLBlendFunc(CC_BLEND_SRC, CC_BLEND_DST);
    
    ccGLEnableVertexAttribs(kCCVertexAttribFlag_Position | kCCVertexAttribFlag_TexCoords);
    
    glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 0, _posCoords);
    glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0, _texCoords);
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, N);
}

@end

