//
//  Ball_withDrawNode.h
//  SquishyBalls
//
//  Created by Justin on 9/3/13.
//  Copyright (c) 2013 Saturnboy. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"

@interface Ball_withDrawNode : CCDrawNode

@property(nonatomic, assign) b2Body *b2Body;
@property(nonatomic, assign) float PTMRatio;
@property(nonatomic, assign) BOOL ignoreBodyRotation;

-(id) initWithPos:(CGPoint)pos radius:(float)radius world:(b2World *)world;

@end
