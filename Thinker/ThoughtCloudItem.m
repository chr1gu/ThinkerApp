//
//  ThoughtCloudItem.m
//  Thinker
//
//  Created by Christoph Ebert on 6/3/13.
//
//

#import "ThoughtCloudItem.h"
#import "cocos2d.h"

@implementation ThoughtCloudItem

+(id)itemWithFile: (NSString *)file
{
    ThoughtCloudItem *item = [ThoughtCloudItem node];
    
    CCSprite *child = [CCSprite spriteWithFile:file];
    [item setContentSize:child.contentSize];
    [child setPosition:CGPointMake(child.contentSize.width/2, child.contentSize.height/2)];
    [child setOpacity:0];
    [item addChild:child];
    [item setChild:child];
    [item moveToRandomPosition];
    return item;
}

- (void) setChild: (CCSprite *)aChild
{
    child = aChild;
}

-(void) setOpacity:(GLubyte) anOpacity
{
    [child setOpacity:anOpacity];
}

-(void) moveToRandomPosition
{
    float ranInterval = 2+arc4random()%5;
    
    int xDist = 10;
    int ranX = arc4random()%(xDist*2)-xDist;
    
    int yDist = 10;
    int ranY = arc4random()%(yDist*2)-yDist;
    
    [child runAction:[CCMoveTo actionWithDuration:ranInterval position:ccp(ranX+child.contentSize.width/2, ranY+child.contentSize.height/2)]];
    //[item setPosition:CGPointMake(ranX+item.contentSize.width/2, ranY+item.contentSize.height/2)];
    [self performSelector:@selector(moveToRandomPosition) withObject:nil afterDelay:ranInterval];
}

-(void) setTexture:(CCTexture2D*)texture
{    
	[child setTexture:texture];
}

@end
