//
//  ShadowSprite.m
//  Thinker
//
//  Created by Christoph Ebert on 4/22/13.
//
//

#import "ShadowSprite.h"
#import "cocos2d.h"

@implementation ShadowSprite

+(id)shadowSpriteWithName:(NSString*)name fileEnding:(NSString *)fileEnding
{
    ShadowSprite *container = [ShadowSprite node];
    CCSprite *texture = [self spriteWithFile:[NSString stringWithFormat:@"%@.%@", name, fileEnding]];
	CCSprite *shadow = [self spriteWithFile:[NSString stringWithFormat:@"%@_shadow.%@", name, fileEnding]];
    [container setContentSize:texture.contentSize];
    [texture setTag:1];
    [shadow setTag:0];
    [texture setPosition:ccp(container.contentSize.width/2, container.contentSize.height/2)];
    [shadow setPosition:ccp(container.contentSize.width/2, container.contentSize.height/2-1)];
    [container addChild:shadow z:0];
    [container addChild:texture z:1];
    
    return container;
}

-(void)setFile:(NSString*)name fileEnding:(NSString *)fileEnding
{
    CCSprite *shadow = (CCSprite *)[self getChildByTag:0];
    CCSprite *texture = (CCSprite *)[self getChildByTag:1];
    
    [shadow setTexture:[[CCSprite spriteWithFile:[NSString stringWithFormat:@"%@_shadow.%@", name, fileEnding]] texture]];
    [texture setTexture:[[CCSprite spriteWithFile:[NSString stringWithFormat:@"%@.%@", name, fileEnding]] texture]];
}

-(void)rotateTo:(float)angle withDuration:(float)duration
{
    CCNode *shadow = [self getChildByTag:0];
    CCNode *texture = [self getChildByTag:1];
    [shadow stopAllActions];
    [texture stopAllActions];
    [shadow runAction:[CCRotateTo actionWithDuration:duration angle:angle]];
    [texture runAction:[CCRotateTo actionWithDuration:duration angle:angle]];
}

-(void)setOpacity:(GLubyte)opacity
{
    [(CCSprite *)[self getChildByTag:0] setOpacity:opacity];
    [(CCSprite *)[self getChildByTag:1] setOpacity:opacity];
    [super setOpacity:opacity];
}

-(void)refreshAnimation
{
    CCNode *shadow = [self getChildByTag:0];
    CCNode *texture = [self getChildByTag:1];

    CCSequence *rotationAction = [CCSequence actions:[CCEaseExponentialInOut actionWithAction:[CCRotateBy actionWithDuration:2.0f angle:-360]], [CCCallBlockN actionWithBlock:^(CCNode *node){
        [node setRotation:0];
    }], nil];
    
    [shadow stopAllActions];
    [texture stopAllActions];
    [shadow setRotation:0];
    [texture setRotation:0];
    [shadow runAction:rotationAction];
    [texture runAction:[rotationAction copy]];
}

@end
