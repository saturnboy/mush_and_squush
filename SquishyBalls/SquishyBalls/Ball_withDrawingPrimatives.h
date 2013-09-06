//
//  Ball_withDrawingPrimatives.h
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "CCPhysicsSprite.h"

@interface Ball_withDrawingPrimatives : CCPhysicsSprite

-(id) initWithPos:(CGPoint)pos radius:(float)radius world:(b2World *)world;

@end
