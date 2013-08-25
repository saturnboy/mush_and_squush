//
//  MainLayer.m
//  WateryBalls
//
//  Created by Justin on 8/23/13.
//  Copyright Saturnboy 2013. All rights reserved.
//

#import "MainLayer.h"
#import "Ball.h"

#define AMAX 400.0f
#define VMAX 100.0f

#define W_A 50.0f
#define W_B 60.0f
#define W_C 110.0f

#define M1 (-AMAX / W_A)
#define M2 (0.2f * AMAX / (W_C-W_B))

#pragma mark - MainLayer
@implementation MainLayer {
    NSMutableArray *_balls;
}

+(CCScene *) scene {
	CCScene *scene = [CCScene node];
	MainLayer *layer = [MainLayer node];
	[scene addChild:layer];
	return scene;
}

-(id) init {
	if ((self = [super init])) {
        self.touchEnabled = YES;
        _balls = [@[] mutableCopy];
        [self scheduleUpdate];
	}
	return self;
}

- (void) dealloc {
	[super dealloc];
}

- (void) update:(ccTime)dt {
    //zero accel for all balls
    for (Ball *b in _balls) {
        b.acc = ccp(0, 0);
    }
    
    //compute accel for each ball (via double loop)
    for (NSUInteger i=0, sz=_balls.count; i<sz; i++) {
        Ball *b = _balls[i];
        
        for (NSUInteger j=i+1; j<sz; j++) {
            Ball *b2 = _balls[j];
            CGPoint delta = ccpSub(b.position, b2.position);
            float dist = ccpLength(delta);
            
            CGPoint acc = ccp(0,0);
            if (dist < W_B) {
                acc = ccpMult(delta, M1 + AMAX/dist);
            } else if (dist < W_C) {
                acc = ccpMult(delta, M2 * (1 - W_C/dist));
            }
            
            b.acc = ccpAdd(b.acc, acc);
            b2.acc = ccpAdd(b2.acc, ccpMult(acc,-1));
        }
        
        //clamp acceleration
        b.acc = ccp((b.acc.x > AMAX ? AMAX : (b.acc.x < -AMAX) ? -AMAX : b.acc.x),
                    (b.acc.y > AMAX ? AMAX : (b.acc.y < -AMAX) ? -AMAX : b.acc.y));
    }

    //equations of motion (aka move the balls)
    for (Ball *b in _balls) {
        //velocity verlet
        b.position = ccpAdd(ccpAdd(b.position, ccpMult(b.vel, dt)), ccpMult(b.acc, dt*dt));
        b.vel = ccpAdd(b.vel, ccpMult(b.acc, dt));
        
        //clamp velocity
        b.vel = ccp((b.vel.x > VMAX ? VMAX : (b.vel.x < -VMAX) ? -VMAX : b.vel.x),
                    (b.vel.y > VMAX ? VMAX : (b.vel.y < -VMAX) ? -VMAX : b.vel.y));
        
        //friction
        b.vel = ccpMult(b.vel, 0.98);
    }
}

-(void) ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //get touch coords
    CGPoint pos = [self convertTouchToNodeSpace:touches.anyObject];
    
    //add tiny random jitter
    pos = ccp(pos.x + CCRANDOM_MINUS1_1(), pos.y + CCRANDOM_MINUS1_1());
    
    //make a new ball for every touch
    Ball *ball = [Ball spriteWithFile:@"ball.png"];
    ball.position = pos;
    ball.vel = ccp(0, 0);
    ball.acc = ccp(0, 0);
    _balls[_balls.count] = ball;
    [self addChild:ball z:1];
}

@end
