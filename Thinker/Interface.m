//
//  Interface.m
//  Thinker
//
//  Created by Christoph Ebert on 4/22/13.
//
//

#import "Interface.h"
#import "InfoOverlay.h"
#import <Social/Social.h>
#import "AppDelegate.h"
#import "ThoughtCloud.h"
#import "SocialManager.h"

// twitter integration
// http://stackoverflow.com/questions/12509327/ios6-social-framework-how-does-slcomposeviewcontroller-fallback-to-twtweetco
#define kOAuthConsumerKey				@"suDYGC9fE0mENVeRvMMyQ"
#define kOAuthConsumerSecret			@"Wbbg6niXvCpIo0mTstd9WlU0AQozHm7qJJXwMv0Cys"


static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};



@interface UIImage (RotationMethods)
- (UIImage *)debugImage;
@end

@implementation UIImage (HelperMethods)

// http://coffeeshopped.com/2010/09/iphone-how-to-dynamically-color-a-uiimage
- (UIImage *)debugImage
{
    UIGraphicsBeginImageContext(self.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [[UIColor colorWithRed:(arc4random()%255) green:255 blue:0 alpha:50] setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to color burn, and the original image
    //CGContextSetBlendMode(context, kCGBlendModeColorBurn);
    CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
    //CGContextDrawImage(context, rect, self.CGImage);
    
    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    //CGContextClipToMask(context, rect, self.CGImage);
    CGContextAddRect(context, rect);
    //CGContextDrawPath(context,kCGPathFill);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;//[coloredImg imageWithBorderFromImage:coloredImg];
}

@end


@implementation Interface

-(id) init
{
	if( (self=[super init]) ) {
        
        clouds = [[NSArray alloc] initWithObjects:
                  //[ThoughtCloud thoughtCloud],
                  [ThoughtCloud thoughtCloud],
                  [ThoughtCloud thoughtCloud],
                  nil];
        
        for (ThoughtCloud *cloud in clouds) {
            [self addChild:cloud];
        }
        
        [self addMenu];
        [self performSelector:@selector(aboutHandler:) withObject:nil afterDelay:0.2];
        self.isTouchEnabled = YES;
        
        //[self toggleFaceDetection:nil];
        //[self switchCameras:nil];
	}
	return self;
}

- (void)ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    UITouch* touch = [touches anyObject];
    CGPoint touchPos = [[CCDirector sharedDirector] convertToGL:[touch locationInView:[touch view]]];
    if (!menuIsOpened && ![self getChildByTag:10]) {
        CGSize size = [[CCDirector sharedDirector] winSize];
        CGRect clickBounds = CGRectMake(0, 0, size.width, size.height-60);
        if (CGRectIntersectsRect(CGRectMake(touchPos.x, touchPos.y, 1, 1), clickBounds)) {
            [self takepictureHandler:nil];
        }
    }
}

-(void) setCameraViewController: (CameraViewController*)camview
{
    cameraviewcontroller = camview;
    [cameraviewcontroller setInterface:self];
}

-(void) addMenu
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    ShadowSprite *about = [ShadowSprite shadowSpriteWithName:@"btn_thethinker" fileEnding:@"png"];
    itemAbout = [CCCustomMenuItemSprite itemWithNormalSprite:about selectedSprite:nil target:self selector:@selector(aboutHandler:)];
    [itemAbout setInstantFeedback:YES];
    
    ShadowSprite *refresh = [ShadowSprite shadowSpriteWithName:@"btn_refresh" fileEnding:@"png"];
    itemRefresh = [CCCustomMenuItemSprite itemWithNormalSprite:refresh selectedSprite:nil target:self selector:@selector(refreshHandler:)];
    [itemRefresh setInstantFeedback:YES];
    
    ShadowSprite *camswitch = [ShadowSprite shadowSpriteWithName:@"btn_turn" fileEnding:@"png"];
    itemCamswitch = [CCCustomMenuItemSprite itemWithNormalSprite:camswitch selectedSprite:nil target:self selector:@selector(camswitchHandler:)];
    [itemCamswitch setInstantFeedback:YES];
    
    ShadowSprite *takepicture = [ShadowSprite shadowSpriteWithName:@"btn_photo_back" fileEnding:@"png"];
    itemTakepicture = [CCCustomMenuItemSprite itemWithNormalSprite:takepicture selectedSprite:nil target:self selector:@selector(takepictureHandler:)];
    [itemTakepicture setInstantFeedback:YES];
    
    ShadowSprite *share = [ShadowSprite shadowSpriteWithName:@"btn_share" fileEnding:@"png"];
    itemShare = [CCCustomMenuItemSprite itemWithNormalSprite:share selectedSprite:nil target:self selector:@selector(shareHandler:)];
    [itemShare setTriggerOnTouchStart:YES];
    
    ShadowSprite *facebook = [ShadowSprite shadowSpriteWithName:@"btn_share_fb" fileEnding:@"png"];
    itemFacebook = [CCCustomMenuItemSprite itemWithNormalSprite:facebook selectedSprite:nil target:self selector:@selector(facebookHandler:)];
    [itemFacebook setTriggerOnTouchMove:YES];
    [itemFacebook setTouchRollover:@selector(toggleFacebookRollover:)];
    
    ShadowSprite *twitter = [ShadowSprite shadowSpriteWithName:@"btn_share_tw" fileEnding:@"png"];
    itemTwitter = [CCCustomMenuItemSprite itemWithNormalSprite:twitter selectedSprite:nil target:self selector:@selector(twitterHandler:)];
    [itemTwitter setTriggerOnTouchMove:YES];
    [itemTwitter setTouchRollover:@selector(toggleTwitterRollover:)];
    
    ShadowSprite *openmenu = [ShadowSprite shadowSpriteWithName:@"btn_mainmenu" fileEnding:@"png"];
    itemOpenmenu = [CCMenuItemSprite itemWithNormalSprite:openmenu selectedSprite:nil target:self selector:@selector(openmenuHandler:)];
    
    CCMenu *menu = [CCMenu menuWithItems:itemAbout, itemRefresh, itemCamswitch, itemTakepicture, itemShare, itemFacebook, itemTwitter, itemOpenmenu, nil];
    [itemAbout setPosition:ccp( size.width/2, size.height - itemAbout.contentSize.height / 2 - 10)];
    [itemOpenmenu setPosition:ccp( size.width/2 + itemOpenmenu.contentSize.width / 2 + 100, itemOpenmenu.contentSize.height/2 + 8 )];
    
    [itemRefresh setPosition:ccp( size.width/2 - itemRefresh.contentSize.width / 2 - 100, -itemRefresh.contentSize.height)];
    [itemCamswitch setPosition:ccp( size.width/2 - itemCamswitch.contentSize.width / 2 - 45, -itemCamswitch.contentSize.height)];
    [itemTakepicture setPosition:ccp( size.width/2, -itemTakepicture.contentSize.height)];
    [itemShare setPosition:ccp( size.width/2 + itemShare.contentSize.width / 2 + 45, -itemShare.contentSize.height)];
    [itemFacebook setPosition:ccp( size.width/2 + itemFacebook.contentSize.width / 2 + 45, -itemFacebook.contentSize.height)];
    [itemTwitter setPosition:ccp( size.width/2 + itemTwitter.contentSize.width / 2 + 45, -itemTwitter.contentSize.height)];
    
    labelTwitter = [ShadowSprite shadowSpriteWithName:@"share_tweet" fileEnding:@"png"];
    labelTwitter.opacity = 0;
    labelTwitter.position = ccp( size.width/2 + itemShare.contentSize.width/ 2 + 45, 138 + labelTwitter.contentSize.height/2);
    [self addChild:labelTwitter];
    
    labelFacebook = [ShadowSprite shadowSpriteWithName:@"share_post" fileEnding:@"png"];
    labelFacebook.opacity = 0;
    labelFacebook.position = ccp( size.width/2 + itemShare.contentSize.width/ 2 + 45, 80 + labelFacebook.contentSize.height/2);
    [self addChild:labelFacebook];
    
    [menu setPosition:ccp(0, 0)];
    [self addChild:menu];
}

-(void) toggleFacebookRollover: (BOOL)rollOver
{
    [self toggleShareText:rollOver withTarget:labelFacebook];
}

-(void) toggleTwitterRollover: (BOOL)rollOver
{
    [self toggleShareText:rollOver withTarget:labelTwitter];
}

-(void) toggleShareText: (BOOL)rollOver withTarget:(CCSprite *)target
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    float moveTime = 0.3f;
    float moveBack = 0.4f;
    float moveBounce = 10;
    
    [target stopAllActions];
    
    if (rollOver) {
        [target runAction:[CCFadeIn actionWithDuration:0.2]];
        [target runAction:[CCSequence actions:
                                  [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 - moveBounce, target.position.y )]],
                                  [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveBack position:ccp( size.width/2, target.position.y )]],
                                  nil]];
        
    } else {
        moveTime = 0.2f;
        [target runAction:[CCFadeOut actionWithDuration:0.2]];
        [target runAction:[CCSequence actions:
                                  [CCEaseSineIn actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemShare.contentSize.width/ 2 + 45, target.position.y)]],
                                  nil]];
    }
}

-(void) aboutHandler: (id)sender
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    float moveTime = 0.3f;
    float moveBack = 0.4f;
    float moveBounce = 10;
    
    InfoOverlay *about;
    if (![self getChildByTag:10]) {
        [cameraviewcontroller setFaceDetection:NO];
        about = [InfoOverlay node];
        about.position = ccp(0, size.height);
        about.tag = 10;
        [about runAction:[CCSequence actions:
                           [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( about.position.x, -moveBounce )]],
                           [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveBack position:ccp( about.position.x, 0 )]],
                           nil]];
        [self addChild:about];
    } else {
        [cameraviewcontroller setFaceDetection:YES];
        moveTime = 0.2f;
        float rotation = (arc4random()%20)-10.0f;
        about = (InfoOverlay *)[self getChildByTag:10];
        [about stopAllActions];
        [about runAction:[CCRotateBy actionWithDuration:moveTime angle:rotation]];
        [about runAction:[CCSequence actions:
                          [CCEaseSineIn actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( about.position.x, -size.height)]],
                          [CCCallBlockN actionWithBlock:^(CCNode *node){
            [self removeChild:node cleanup:YES];
        }],
                          nil]];
    }
}
-(void) refreshHandler: (id)sender
{
    ShadowSprite *refreshIcon = (ShadowSprite*)[[itemRefresh children] objectAtIndex:0];
    
    /*[itemTakepicture runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.1], [CCScaleTo actionWithDuration:0.1 scaleX:0 scaleY:1],[CCCallBlock actionWithBlock:^(void){
        [cameraIcon setFile:fileName fileEnding:@"png"];
    }],[CCScaleTo actionWithDuration:0.1 scaleX:1 scaleY:1], [CCDelayTime actionWithDuration:0.1], [CCCallBlock actionWithBlock:^(void){
        [cameraviewcontroller switchCameras:nil];
        [cloud updateIsMirrored:[cameraviewcontroller getIsMirrored]];
    }], nil]];*/
    
    [refreshIcon refreshAnimation];
    
    for (ThoughtCloud *cloud in clouds) {
        [cloud refreshThought];
    }
}

-(void) camswitchHandler: (id)sender
{
    [self flipCamIcon];
}

-(void) takepictureHandler: (id)sender
{
    UIImage *img = [self createUIImageScreenshot];
    
    /*[self removeChildByTag:99 cleanup:YES];
    [[CCTextureCache sharedTextureCache] removeTextureForKey:@"screenshot"];
    CCSprite *sprite = [CCSprite spriteWithCGImage:[img debugImage].CGImage key:@"screenshot"];
    [sprite setScale:0.25];
    CGSize size = [[CCDirector sharedDirector] winSize];
    sprite.position = ccp(size.width/2, size.height/2);
    sprite.tag = 99;
    [self addChild:sprite];*/
    
    [cameraviewcontroller savePictureWithOverlay:img/*[img debugImage]*/];
}
-(void) shareHandler: (id)sender
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    float moveTime = 0.3f;
    float moveBack = 0.4f;
    float moveBounce = 10;
    
    [itemFacebook stopAllActions];
    [itemTwitter stopAllActions];

    if (!shareMenuIsOpened) {
        shareMenuIsOpened = YES;
        
        [itemFacebook runAction:[CCFadeIn actionWithDuration:moveTime]];
        [itemFacebook runAction:[CCSequence actions:
                                [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemFacebook.contentSize.width / 2 + 45, itemFacebook.contentSize.height/2 + 62 + moveBounce )]],
                                [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveBack position:ccp( size.width/2 + itemFacebook.contentSize.width / 2 + 45, itemFacebook.contentSize.height/2 + 62 )]],
                                nil]];
        [itemTwitter runAction:[CCFadeIn actionWithDuration:moveTime]];
        [itemTwitter runAction:[CCSequence actions:
                                  [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemTwitter.contentSize.width / 2 + 45, itemTwitter.contentSize.height/2 + 122 + moveBounce )]],
                                  [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveBack position:ccp( size.width/2 + itemTwitter.contentSize.width / 2 + 45, itemTwitter.contentSize.height/2 + 122 )]],
                                  nil]];
        
    } else {
        moveTime = 0.2f;
        shareMenuIsOpened = NO;
        
        [itemFacebook runAction:[CCFadeOut actionWithDuration:moveTime]];
        [itemFacebook runAction:[CCSequence actions:
                                  [CCEaseSineIn actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemFacebook.contentSize.width / 2 + 45, -itemFacebook.contentSize.height)]],
                                  nil]];
        
        [itemTwitter runAction:[CCFadeOut actionWithDuration:moveTime]];
        [itemTwitter runAction:[CCSequence actions:
                                  [CCEaseSineIn actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemTwitter.contentSize.width / 2 + 45, -itemTwitter.contentSize.height)]],
                                  nil]];
    }
}

-(void) twitterHandler: (id)sender
{
    AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
    UINavigationController *viewController = [app navController];
    
    // prepare the message to be shared
    NSString *text = @"Naughty or nice? Visualize your friends thoughts with TheThinker. Its free, fun and a little creepy. http://goo.gl/GCfjZ via @appetitech";
    NSString *escapedMessage = [text stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *appURL = [NSString stringWithFormat:@"twitter://post?message=%@", escapedMessage];
    
    if(NSClassFromString(@"SLComposeViewController") != nil && [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        // user has setup the iOS6 twitter account
        SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [composeViewController setInitialText:text];
        [viewController presentViewController:composeViewController animated:YES completion:nil];
    }
    else
    {
        // else, we have to fallback to app or browser
        if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appURL]])
        {
            // twitter app available!
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appURL]];
        }
        else
        {
            // worse come to worse, open twitter page in browser
            NSString *web = [NSString stringWithFormat:@"https://twitter.com/intent/tweet?text=%@", escapedMessage];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:web]];
        }
    }
}

-(void) facebookHandler: (id)sender
{
    [SocialManager setFacebookMessage];
}

-(void) openmenuHandler: (id)sender
{
    ShadowSprite *openmenu = (ShadowSprite*)[[itemOpenmenu children] objectAtIndex:0];
    CGSize size = [[CCDirector sharedDirector] winSize];
    float moveTime = 0.3f;
    float moveBack = 0.4f;
    float moveBounce = 10;
    float delayTime = 0.1f;
    
    [itemRefresh stopAllActions];
    [itemCamswitch stopAllActions];
    [itemTakepicture stopAllActions];
    [itemShare stopAllActions];
    [itemOpenmenu stopAllActions];
    
    if (!menuIsOpened) {
        menuIsOpened = YES;
        [openmenu rotateTo:45 withDuration:0.3];
        [itemRefresh runAction:[CCSequence actions:
                                [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 - itemRefresh.contentSize.width / 2 - 100, itemRefresh.contentSize.height/2 + 8 + moveBounce )]],
                                [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveBack position:ccp( size.width/2 - itemRefresh.contentSize.width / 2 - 100, itemRefresh.contentSize.height/2 + 8 )]],
                                nil]];
        [itemCamswitch runAction:[CCSequence actions:
                                  [CCDelayTime actionWithDuration:delayTime],
                                  [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 - itemCamswitch.contentSize.width / 2 - 45, itemCamswitch.contentSize.height/2 + 8 + moveBounce )]],
                                  [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveBack position:ccp( size.width/2 - itemCamswitch.contentSize.width / 2 - 45, itemCamswitch.contentSize.height/2 + 8 )]],
                                  nil]];
        [itemTakepicture runAction:[CCSequence actions:
                                    [CCDelayTime actionWithDuration:delayTime*2],
                                    [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2, itemTakepicture.contentSize.height/2 + 8 + moveBounce )]],
                                    [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveBack position:ccp( size.width/2, itemTakepicture.contentSize.height/2 + 8 )]],
                                    nil]];
        [itemShare runAction:[CCSequence actions:
                              [CCDelayTime actionWithDuration:delayTime*3],
                              [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemShare.contentSize.width / 2 + 45, itemShare.contentSize.height/2 + 8 + moveBounce )]],
                              [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:moveBack position:ccp( size.width/2 + itemShare.contentSize.width / 2 + 45, itemShare.contentSize.height/2 + 8 )]],
                              nil]];
        
    } else {
        
        moveTime = 0.2f;
        delayTime = 0.05f;
        
        menuIsOpened = NO;
        [openmenu rotateTo:0 withDuration:0.3];
        [itemRefresh runAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 - itemRefresh.contentSize.width / 2 - 100, -itemRefresh.contentSize.height)]];
        [itemCamswitch runAction:[CCSequence actions:
                                  [CCDelayTime actionWithDuration:delayTime],
                                  [CCEaseSineIn actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 - itemCamswitch.contentSize.width / 2 - 45, -itemCamswitch.contentSize.height)]],
                                  nil]];
        [itemTakepicture runAction:[CCSequence actions:
                                    [CCDelayTime actionWithDuration:delayTime*2],
                                    [CCEaseSineIn actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2, -itemTakepicture.contentSize.height)]],
                                    nil]];
        [itemShare runAction:[CCSequence actions:
                              [CCDelayTime actionWithDuration:delayTime*3],
                              [CCEaseSineIn actionWithAction:[CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemShare.contentSize.width / 2 + 45, -itemShare.contentSize.height)]],
                              nil]];
        
        shareMenuIsOpened = NO;
        
        [itemFacebook runAction:[CCSequence actions:
                                 [CCDelayTime actionWithDuration:delayTime*3],
                                 [CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemFacebook.contentSize.width / 2 + 45, -itemFacebook.contentSize.height)],
                                 nil]];
        [itemTwitter runAction:[CCSequence actions:
                                [CCDelayTime actionWithDuration:delayTime*3],
                                [CCMoveTo actionWithDuration:moveTime position:ccp( size.width/2 + itemTwitter.contentSize.width / 2 + 45, -itemTwitter.contentSize.height)],
                                nil]];
    }
}


-(void) flipCamIcon
{
    ShadowSprite *cameraIcon = (ShadowSprite*)[[itemTakepicture children] objectAtIndex:0];
    NSString *fileName = ![cameraviewcontroller getIsMirrored] ? @"btn_photo_back" : @"btn_photo_front";
    
    [itemTakepicture stopAllActions];
    [cameraIcon stopAllActions];
    

    [itemTakepicture runAction:[CCSequence actions:
                                [CCDelayTime actionWithDuration:0.03],
                                [CCEaseExponentialIn actionWithAction:[CCScaleTo actionWithDuration:0.25 scaleX:0 scaleY:1]],
                                [CCCallBlock actionWithBlock:^(void){
        [cameraIcon setFile:fileName fileEnding:@"png"];
    }],
                                [CCScaleTo actionWithDuration:0.1 scaleX:1 scaleY:1],
                                [CCScaleTo actionWithDuration:0.06 scaleX:0.95 scaleY:1],
                                [CCScaleTo actionWithDuration:0.18 scaleX:0.90 scaleY:1],
                                [CCScaleTo actionWithDuration:0.18 scaleX:1 scaleY:1],
                                [CCDelayTime actionWithDuration:0.1],
                                [CCCallBlock actionWithBlock:^(void){
        [cameraviewcontroller switchCameras:nil];
        
        BOOL isMirrored = [cameraviewcontroller getIsMirrored];
        for (ThoughtCloud *cloud in clouds) {
            [cloud updateIsMirrored:isMirrored];
        }
    
    }], nil]];
    
    [cameraIcon runAction:[CCSequence actions:
                           [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:0.3f position:ccp( 0, 10 )]],
                           [CCEaseBackOut actionWithAction:[CCMoveTo actionWithDuration:0.4f position:ccp( 0, 0 )]],
                                nil]];
}

-(void) freeClouds
{
    for (ThoughtCloud *cloud in clouds) {
        [cloud setIsFree:YES];
    }
}

-(void) updateCloud: (CGRect)faceRect orientation:(UIDeviceOrientation)orientation size:(CGSize)size index:(int)index
{
    //CGSize size = [[CCDirector sharedDirector] winSize];
    
    //NSLog(@"update scale: %f %f", size.width, size.height);
    
    //float xscale = faceRect.size.width/[cloud contentSize].width;
    //float yscale = faceRect.size.height/[cloud contentSize].height;
    
    //[cloud setScaleY:yscale];
    //[cloud setScaleX:xscale];
    
    // get the closest free cloud..
    if (index >= [clouds count]) {
        return;
    }
    ThoughtCloud *closestCloud = nil;
    float closestDistance = 9999;
    for (ThoughtCloud *cloud in clouds) {
        float distance = fabs((faceRect.origin.x+faceRect.origin.y)-cloud.lastDistancePoint);
        //NSLog(@"distance: %f", distance);
        if (cloud.isFree && distance < closestDistance) {
            closestCloud = cloud;
            closestDistance = distance;
            [cloud setIsFree:NO];
        }
        /*if (cloud.isFree) {
            //float distance = (faceRect.origin.x+faceRect.origin.y)-(cloud.position.x+cloud.position.y);
            //NSLog(@"use free cloud: %@ distanz: %f", cloud, distance);
            //[cloud updateCloud:faceRect orientation:orientation size:size];
            return;
        }*/
        //[cloud updateThought];
    }
    
    if (closestCloud) {
        [closestCloud updateCloud:faceRect orientation:orientation size:size];
    }
    

    
    
    /*if (index < [clouds count]) {
        ThoughtCloud *cloud = [clouds objectAtIndex:index];
        [cloud updateCloud:faceRect orientation:orientation size:size];
    }*/
    
    
    //
    
    /*switch (orientation) {
        case UIDeviceOrientationPortrait:
            [cloud setFlipY:NO];
            [cloud setRotation:0];
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            [cloud setFlipY:YES];
            [cloud setRotation:0];
            break;
        case UIDeviceOrientationLandscapeLeft:
            [cloud setFlipY:NO];
            [cloud setRotation:90.f];
            break;
        case UIDeviceOrientationLandscapeRight:
            [cloud setRotation:90.f];
            [cloud setFlipY:YES];
            break;
        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        default:
            break; // leave the layer in its last known orientation
    }*/
}

-(UIImage*)createUIImageScreenshot
{
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    CCRenderTexture* renderer = [CCRenderTexture renderTextureWithWidth:size.width height:size.height];
	[renderer begin];
    // visit all your sprites
    for (ThoughtCloud *cloud in clouds) {
        [cloud visit];
    }
	[renderer end];
	
    CGImageRef cgimage = [renderer newCGImage];
    UIImage *newImage = [UIImage imageWithCGImage:cgimage];
	CGImageRelease(cgimage);
    return newImage;
}

@end

