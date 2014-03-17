//
//  CCCustomMenuItemSprite.h
//  Thinker
//
//  Created by Christoph Ebert on 4/27/13.
//
//

#import "CCMenuItem.h"
#import "cocos2d.h"

@interface CCCustomMenuItemSprite : CCMenuItemSprite <CCTargetedTouchDelegate> {
    SEL selector_;
    SEL touchRollover_;
    id target_;
    BOOL triggerOnTouch_;
    BOOL triggerOnTouchMove_;
    BOOL rollOver_;
    BOOL instantFeedback_;
}

-(void)setTriggerOnTouchStart:(BOOL)triggerOnTouch;
-(void)setTriggerOnTouchMove:(BOOL)triggerOnTouchMove;
-(void)setTouchRollover:(SEL)touchRollover;
-(void)setInstantFeedback:(BOOL)instantFeedback;

@end
