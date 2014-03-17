//
//  ThoughtCloudItem.h
//  Thinker
//
//  Created by Christoph Ebert on 6/3/13.
//
//

#import "CCSprite.h"

@interface ThoughtCloudItem : CCSprite
{
    CCSprite *child;
}

+(id)itemWithFile: (NSString *)file;

@end
