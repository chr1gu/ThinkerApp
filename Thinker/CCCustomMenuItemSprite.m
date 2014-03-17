//
//  CCCustomMenuItemSprite.m
//  Thinker
//
//  Created by Christoph Ebert on 4/27/13.
//
//

#import "CCCustomMenuItemSprite.h"

@implementation CCCustomMenuItemSprite

-(id) initWithNormalSprite:(CCNode<CCRGBAProtocol>*)normalSprite selectedSprite:(CCNode<CCRGBAProtocol>*)selectedSprite disabledSprite:(CCNode<CCRGBAProtocol>*)disabledSprite target:(id)target selector:(SEL)selector
{
    selector_ = selector;
    target_ = target;
    return [super initWithNormalSprite:normalSprite selectedSprite:selectedSprite disabledSprite:disabledSprite target:target selector:selector];
}

-(void)onEnter
{
	[[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:kCCMenuHandlerPriority swallowsTouches:NO];
	[super onEnter];
}

-(void)onExit
{
	[[[CCDirector sharedDirector] touchDispatcher] removeDelegate:self];
	[super onExit];
}

-(void)setTouchRollover:(SEL)touchRollover
{
    touchRollover_ = touchRollover;
}

-(void)setTriggerOnTouchStart:(BOOL)triggerOnTouch
{
    triggerOnTouch_ = triggerOnTouch;
    isEnabled_ = !triggerOnTouch_;
}

-(void)setTriggerOnTouchMove:(BOOL)triggerOnTouchMove
{
    triggerOnTouchMove_ = triggerOnTouchMove;
    isEnabled_ = !triggerOnTouchMove;
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint location = [self convertTouchToNodeSpace: touch];
    float padding = 5;
    CGRect box = CGRectMake(-padding, -padding, self.boundingBox.size.width+padding, self.boundingBox.size.height+padding);
    
    if (CGRectContainsPoint(box, location) && !triggerOnTouchMove_) {
        [self setScale:0.7];
        if (triggerOnTouch_ || instantFeedback_) {
            [target_ performSelector:selector_ withObject:self];
        }
        return YES;
    }
    
    if (triggerOnTouchMove_) {
        [self setRollOver:NO];
        return YES;
    }
    return NO;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (triggerOnTouchMove_) {
        // early bail
        if ([self numberOfRunningActions]) {
            [self setRollOver:NO];
            return;
        }

        CGPoint location = [self convertTouchToNodeSpace: touch];
        float padding = 5;
        CGRect box = CGRectMake(-padding, -padding, self.boundingBox.size.width+padding, self.boundingBox.size.height+padding);
        
        if (CGRectContainsPoint(box, location)) {
            if (!rollOver_) {
                [self setRollOver:YES];
            }
        } else {
            if (rollOver_) {
                [self setRollOver:NO];
            }
        }
    }
}

-(void)setRollOver:(BOOL)rollOver
{
    if (rollOver_ != rollOver && touchRollover_) {
        [target_ performSelector:touchRollover_ withObject:rollOver];
    }
    rollOver_ = rollOver;
}

-(void)setInstantFeedback:(BOOL)instantFeedback
{
    instantFeedback_ = instantFeedback;
    isEnabled_ = !instantFeedback;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (!triggerOnTouchMove_) {
        [self setScale:0.7];
        [self runAction:[CCSequence actions:
                         [CCScaleTo actionWithDuration:0.15 scale:1.3],
                         [CCScaleTo actionWithDuration:0.05 scale:1], nil]];
    }
    
    if (triggerOnTouch_) {
        [target_ performSelector:selector_ withObject:self afterDelay:0.1f];
    }
    
    if (triggerOnTouchMove_ && rollOver_) {
        [self setRollOver:NO];
        [target_ performSelector:selector_ withObject:self afterDelay:0.1f];
    }
}

@end
