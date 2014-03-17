//
//  SocialManager.h
//  Lightwriter
//
//  Created by Christoph Ebert on 1/14/13.
//
//

#import "cocos2d.h"

@interface SocialManager : CCLayer

+(void) setFacebookMessage;
+(BOOL) handleOpenURL: (NSURL *)url;
+(void) handleDidBecomeActive;
+(void) handleWillTerminate;
+(void) publishFacebookStatus: (NSString *)text;

@end
