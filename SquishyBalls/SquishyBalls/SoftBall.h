//
//  SoftBall.h
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"

@interface SoftBall : CCSprite

-(id) initWithName:(NSString *)name pos:(CGPoint)pos world:(b2World *)world;

@end
