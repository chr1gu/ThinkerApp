//
//  ThoughtCloud.m
//  Thinker
//
//  Created by Christoph Ebert on 4/22/13.
//
//

#import "ThoughtCloud.h"
#import "cocos2d.h"

@implementation ThoughtCloud

+(id)thoughtCloud
{
    ThoughtCloud *container = [ThoughtCloud node];
    return container;
}

- (id)init
{
    if( (self = [super init]) )
    {
        
        cloudB = [ThoughtCloudItem itemWithFile:[ThoughtCloud getBCloudTexture]];
        [self setContentSize:cloudB.contentSize];
        [self setCloudBOffset:ccp(cloudB.contentSize.width/2, cloudB.contentSize.height/2)];
        [self addChild:cloudB];
        
        cloudM = [ThoughtCloudItem itemWithFile:[ThoughtCloud getMCloudTexture]];
        cloudM.position = ccp(cloudM.contentSize.width/2+30, -cloudM.contentSize.height/2);
        [self addChild:cloudM];
        
        cloudS = [ThoughtCloudItem itemWithFile:[ThoughtCloud getSCloudTexture]];
        cloudS.position = ccp(cloudS.contentSize.width/2, -cloudM.contentSize.height-cloudS.contentSize.height/2);
        [self addChild:cloudS];
        
        thought = [ThoughtCloudItem itemWithFile:[ThoughtCloud getRandomThought]];
        thought.position = ccp(self.contentSize.width/2, self.contentSize.height/2);
        [self addChild:thought];
        
        [self setVisible:NO];
        
        distancePoint = 0;
        free = YES;
        
        //CCSprite *debug = [CCSprite spriteWithFile:@"debug-ring.png"];
        //[debug setPosition:ccp(debug.contentSize.width/2, debug.contentSize.width/2)];
        //debug.tag = 100;
        //[self addChild:debug];
    }
    return self;
}


-(void)setCloudBOffset: (CGPoint)offset
{
    cloudBOffset = offset;
}

+(NSString *)getRandomThought
{
    return [NSString stringWithFormat:@"ico_%i.png",(arc4random()%30)+1];
}

+(NSString *)getBCloudTexture
{
    return [NSString stringWithFormat:@"cloud_big_%i.png", arc4random()%4+1];
}

+(NSString *)getMCloudTexture
{
    return [NSString stringWithFormat:@"cloud_medium_%i.png", arc4random()%2+1];
}

+(NSString *)getSCloudTexture
{
    return [NSString stringWithFormat:@"cloud_small_%i.png", arc4random()%2+1];
}

-(void)updateCloudTextures
{
    [self setTexture:[[CCSprite spriteWithFile:[ThoughtCloud getBCloudTexture]] texture]];
    [cloudM setTexture:[[CCSprite spriteWithFile:[ThoughtCloud getMCloudTexture]] texture]];
    [cloudS setTexture:[[CCSprite spriteWithFile:[ThoughtCloud getSCloudTexture]] texture]];
}

-(void)refreshThought
{
    [self hideCloud];
    //[self performSelector:@selector(updateThought) withObject:NO afterDelay:0.40];
}

-(void)updateThought
{
    // update textures
    [self updateCloudTextures];
    // update though
    [thought setTexture:[[CCSprite spriteWithFile:[ThoughtCloud getRandomThought]] texture]];
    [self showCloud];
}


-(void)updateIsMirrored: (BOOL)mirrored
{
    [thought setFlipX:mirrored];
}

-(float)lastDistancePoint
{
    return distancePoint;
}


bool positionHasChanged(CGPoint pos1, CGPoint pos2)
{
    float threshold = 10.0f;
    return ccpDistance(pos1, pos2) > threshold;
}


-(void)updateCloud:(CGRect)faceRect orientation:(UIDeviceOrientation)orientation size:(CGSize)size;
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    distancePoint = faceRect.origin.x+faceRect.origin.y;
    
    float xscale = faceRect.size.width/[self contentSize].width;
    float yscale = faceRect.size.height/[self contentSize].height;
    BOOL isNewCloud = !self.visible;
    
    //NSLog(@"size: %f %f", size.width/cloudB.contentSize.width, size.height/cloudB.contentSize.height);
    //[self setScaleX:xscale+0.3];
    //[self setScaleY:yscale+0.3];
    //[self runAction:[CCScaleTo actionWithDuration:0.3 scaleX:xscale+0.3 scaleY:yscale+0.3]];
    
    if (isNewCloud) {
        [self updateThought];
    }
    
    // hide timer TODO: too much memory consumption?
    [self unscheduleAllSelectors];
    [self scheduleOnce:@selector(hideCloud) delay:0.2];
    
    // TODO: apply size to all
    CCSprite *debug = (CCSprite *)[self getChildByTag:100];
    [debug setContentSize:size];
    [debug setPosition:ccp(debug.contentSize.width/2, debug.contentSize.height/2)];
    
    
    // position itself in the middle of a face
    CGPoint newPos = ccp(faceRect.origin.x+(self.contentSize.width/2*xscale), winSize.height - faceRect.origin.y - self.contentSize.height/2*yscale);
    
    if (!positionHasChanged(self.position, newPos)) {
        // position didn't change skip rest
        return;
    }
    
    // on the face itself
    // max 150 pts away from the face
    float xpos = MIN(winSize.width-self.position.x-50,150);
    float ypos = MIN(winSize.height-self.position.y-110,300);
    
    // if more on the right, put cloud on the left side
    if (newPos.x > winSize.width/2) {
        xpos = MAX(50-self.position.x, -150);
    }
    
    CGPoint cloudBPos = ccpAdd(cloudBOffset, ccp(xpos, ypos));
    CGPoint cloudMPos = ccpAdd(cloudBOffset, ccp(xpos/1.5, ypos/1.5));
    CGPoint cloudSPos = ccpAdd(cloudBOffset, ccp(xpos/2, ypos/2));
    CGPoint thoughtPos = ccpAdd(cloudBOffset, ccp(xpos, ypos));
    
    if (isNewCloud) {
        //NSLog(@"position changed: new");
        self.position = newPos;
        [cloudB setPosition:cloudBPos];
        [cloudM setPosition:cloudMPos];
        [cloudS setPosition:cloudSPos];
        [thought setPosition:thoughtPos];
    } else {
        float movespeed = 0.4;
        //NSLog(@"position changed: existing");
        [self runAction:[CCMoveTo actionWithDuration:movespeed position:newPos]];
        [cloudB runAction:[CCMoveTo actionWithDuration:movespeed position:cloudBPos]];
        [cloudM runAction:[CCMoveTo actionWithDuration:movespeed position:cloudMPos]];
        [cloudS runAction:[CCMoveTo actionWithDuration:movespeed position:cloudSPos]];
        [thought runAction:[CCMoveTo actionWithDuration:movespeed position:thoughtPos]];
    }
}

-(void)idleCloud
{
    cloudIsBusy = NO;
    [self unscheduleAllSelectors];
    [self scheduleOnce:@selector(hideCloud) delay:0.1];
}

-(BOOL)isFree
{
    return free;
}

-(void)setIsFree: (BOOL)setting
{
    free = setting;
}

-(void)showCloud
{
    if (cloudIsBusy) {
        //NSLog(@"cloud is busy and cant show");
        return;
    }
    cloudB.scale = 1.0;
    cloudS.scale = 1.0;
    cloudM.scale = 1.0;
    cloudS.opacity = 0;
    cloudM.opacity = 0;
    cloudB.opacity = 0;
    thought.opacity = 0;
    [cloudS runAction:[CCFadeIn actionWithDuration:0.2]];
    [cloudM runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.1], [CCFadeIn actionWithDuration:0.2], nil]];
    [cloudB runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.15], [CCFadeIn actionWithDuration:0.2], nil]];
    [thought runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.20], [CCFadeIn actionWithDuration:0.2], nil]];
    [self setVisible:YES];
    [self performSelector:@selector(idleCloud) withObject:NO afterDelay:0.4];
    cloudIsBusy = YES;
}

-(void)hideCloud
{
    if (cloudIsBusy) {
        //NSLog(@"cloud is busy and cant hide");
        return;
    }
    [cloudS runAction:[CCFadeOut actionWithDuration:0.2]];
    [cloudS runAction:[CCScaleTo actionWithDuration:0.2 scale:0.5]];
    [cloudM runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.1], [CCFadeOut actionWithDuration:0.2], nil]];
    [cloudM runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.1], [CCScaleTo actionWithDuration:0.2 scale:0.5], nil]];
    [cloudB runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.2], [CCFadeOut actionWithDuration:0.2], nil]];
    [cloudB runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.2], [CCScaleTo actionWithDuration:0.2 scale:1.3], nil]];
    [thought runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.2], [CCFadeOut actionWithDuration:0.2], nil]];
    [self performSelector:@selector(setVisible:) withObject:NO afterDelay:0.40];
    [self performSelector:@selector(idleCloud) withObject:NO afterDelay:0.40];
    cloudIsBusy = YES;
}

@end
