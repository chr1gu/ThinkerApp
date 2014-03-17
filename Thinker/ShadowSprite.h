//
//  ShadowSprite.h
//  Thinker
//
//  Created by Christoph Ebert on 4/22/13.
//
//

#import "CCSprite.h"

@interface ShadowSprite : CCSprite

+(id)shadowSpriteWithName:(NSString*)name fileEnding:(NSString *)fileEnding;
-(void)setFile:(NSString*)name fileEnding:(NSString *)fileEnding;
-(void)rotateTo:(float)angle withDuration:(float)duration;
-(void)refreshAnimation;

@end
