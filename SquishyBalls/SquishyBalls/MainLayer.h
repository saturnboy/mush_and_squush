//
//  MainLayer.h
//  SquishyBalls
//
//  Created by Justin on 8/25/13.
//  Copyright Saturnboy 2013. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

#define PTM_RATIO 32 //pixels to meters

@interface MainLayer : CCLayer {
    b2World* _world;
    GLESDebugDraw *_debug;
}

+(CCScene *) scene;

@end
