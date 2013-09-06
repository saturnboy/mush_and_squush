//
//  Ball_withSprite.h
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "CCPhysicsSprite.h"

@interface Ball_withSprite : CCPhysicsSprite

-(id) initWithSprite:(NSString *)name pos:(CGPoint)pos world:(b2World *)world;

@end
