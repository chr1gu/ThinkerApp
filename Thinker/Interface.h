//
//  Interface.h
//  Thinker
//
//  Created by Christoph Ebert on 4/22/13.
//
//

#import "CCLayer.h"
#import "cocos2d.h"
#import "CameraViewController.h"
#import "ShadowSprite.h"
#import "CCCustomMenuItemSprite.h"

@interface Interface : CCLayer
{
    CameraViewController *cameraviewcontroller;

    // menu
    BOOL menuIsOpened;
    BOOL shareMenuIsOpened;
    CCCustomMenuItemSprite *itemAbout;
    CCCustomMenuItemSprite *itemRefresh;
    CCCustomMenuItemSprite *itemCamswitch;
    CCCustomMenuItemSprite *itemTakepicture;
    CCCustomMenuItemSprite *itemShare;
    CCCustomMenuItemSprite *itemFacebook;
    CCCustomMenuItemSprite *itemTwitter;
    CCMenuItemSprite *itemOpenmenu;
    ShadowSprite *labelTwitter;
    ShadowSprite *labelFacebook;
    NSArray *clouds;
}

-(void) freeClouds;
-(void) setCameraViewController: (CameraViewController*)camview;
-(void) updateCloud: (CGRect)faceRect orientation:(UIDeviceOrientation)orientation size:(CGSize)size index:(int)index;

@end
