//
//  IntroLayer.m
//  Thinker
//
//  Created by Christoph Ebert on 4/15/13.
//  Copyright __MyCompanyName__ 2013. All rights reserved.
//


// Import the interfaces
#import "IntroLayer.h"
#import "Interface.h"
#import "CameraViewController.h"

#pragma mark - IntroLayer

// HelloWorldLayer implementation
@implementation IntroLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	IntroLayer *layer = [IntroLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// 
-(void) onEnter
{
	[super onEnter];

	// ask director for the window size
	CGSize size = [[CCDirector sharedDirector] winSize];
    CameraViewController *cameraViewController = [[CameraViewController alloc] initWithSize:size];
    
    // add camera view
    [[[[CCDirector sharedDirector] view] superview] insertSubview:[cameraViewController view] atIndex:0];
    [CCDirector sharedDirector].view.backgroundColor = [UIColor clearColor];
    [CCDirector sharedDirector].view.opaque = NO;
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA); glClearColor(0.0, 0.0, 0.0, 0.0); glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // add interface
    Interface *interface = [Interface node];
    [interface setCameraViewController:cameraViewController];
    [self addChild:interface];
}

@end
