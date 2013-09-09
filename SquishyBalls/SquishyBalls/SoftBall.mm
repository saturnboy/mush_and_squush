//
//  SoftBall.mm
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "SoftBall.h"
#import <vector>

@implementation SoftBall {
    NSString *_name;
    CCTexture2D *_tex;
    b2Body *_center;
    std::vector<b2Body*> _verts;
    std::vector<b2Joint*> _edges;
    std::vector<b2Joint*> _spokes;
    float _vertRadius;
    ccVertex2F *_posCoords;
    ccVertex2F *_texCoords;
}

- (id) initWithName:(NSString *)name pos:(CGPoint)pos world:(b2World *)world {
    if ((self = [super init])) {
        _name = name;
        
        //init texture
        _tex = [[CCTextureCache sharedTextureCache] textureForKey:name];
        self.shaderProgram = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTexture];
        CCLOG(@"TEXTURE %@ size=%dx%d scale=%.1f", name, _tex.pixelsWide, _tex.pixelsHigh, CC_CONTENT_SCALE_FACTOR());
        
        //compute various radii from texture width
        _vertRadius = _tex.pixelsWide / CC_CONTENT_SCALE_FACTOR() / 8.0f;
        float centerRadius = _vertRadius * 0.9f;
        
        //subtract vertRadius to keep entire vert circle inside master ball
        float R = (_tex.pixelsWide / CC_CONTENT_SCALE_FACTOR() / 2.0f - _vertRadius) / PTM_RATIO;
        CCLOG(@"RADIUS %.3f", R);
        CCLOG(@"VERT RADIUS %.3f", _vertRadius);
        CCLOG(@"CENTER RADIUS %.3f", centerRadius);

        //compute center pos
        b2Vec2 centerPos = b2Vec2(pos.x/PTM_RATIO, pos.y/PTM_RATIO);
        CCLOG(@"CENTER (%.3f,%.3f)", centerPos.x, centerPos.y);
        
        //first, the center body
        b2CircleShape shape;
        shape.m_radius = centerRadius / PTM_RATIO;
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position = centerPos;
        bodyDef.angularDamping = 1.0f;
        
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &shape;
        fixtureDef.density = 0.1f;
        fixtureDef.friction = 0.7f;
        fixtureDef.restitution = 0.03f;
        
        _center = world->CreateBody(&bodyDef);
        _center->CreateFixture(&fixtureDef);
        
        //next, all the vertex bodies
        shape.m_radius = _vertRadius / PTM_RATIO;
        for (int i = 0; i < 8; i++) {
            float theta = i * M_PI_4;
            b2Vec2 vertPos = b2Vec2(R * cosf(theta), R * sinf(theta)) + centerPos;
            CCLOG(@"VERT%d theta=%.3f (%.3f,%.3f)", i, theta, vertPos.x, vertPos.y);
            
            //only the vertex pos changes
            bodyDef.position = vertPos;
            
            b2Body *body = world->CreateBody(&bodyDef);
            body->CreateFixture(&fixtureDef);
            
            _verts.push_back(body);
        }
        
        //last, make all the joints (edges & spokes)
        b2DistanceJointDef jointDef;
        for (int i = 0; i < 8; i++) {
            //joints between verts (aka the edges)
            int j = (i == 0 ? 8-1 : i-1);
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

        //add vert radius to compute new vert (all the way to the edge)
        float x = (_verts[i]->GetPosition().x - _center->GetPosition().x) * (1 + _vertRadius/R) * PTM_RATIO + _posCoords[0].x;
        float y = (_verts[i]->GetPosition().y - _center->GetPosition().y) * (1 + _vertRadius/R) * PTM_RATIO + _posCoords[0].y;
        _posCoords[i+1] = (ccVertex2F) { x, y };
        //CCLOG(@"POS COORDS %d %.3f %.3f,%.3f", i, R, x, y);
    }
    _posCoords[N-1] = _posCoords[1];
    
    //compute texture coords (in range [0,1])
    _texCoords[0] = (ccVertex2F) { 0.5f, 0.5f };
    for (int i = 0; i < 8; i++) {
        float theta = i * M_PI_4;
        _texCoords[i+1] = (ccVertex2F) { cosf(theta) * 0.5f + 0.5f, sinf(theta) * 0.5f + 0.5f };
        //CCLOG(@"TEX COORDS %d %.3f,%.3f", i, _texCoords[i+1].x, _texCoords[i+1].y);
    }
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
