//
//  InfoOverlay.m
//  Thinker
//
//  Created by Christoph Ebert on 4/22/13.
//
//

#import "InfoOverlay.h"

@implementation InfoOverlay

-(id) init
{
	if( (self=[super init]) ) {
        
        CGSize size = [[CCDirector sharedDirector] winSize];
        CCLayerColor *bg = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 255) width:300 height:300];
        bg.position = ccp(size.width/2 - bg.contentSize.width/2, size.height - bg.contentSize.height - 70);
        [self addChild:bg z:1];
        
        CCLayerColor *shadow = [CCLayerColor layerWithColor:ccc4(0, 0, 0, 102) width:bg.contentSize.width height:bg.contentSize.height];
        shadow.position = ccpAdd(bg.position, ccp(0, -1));
        [self addChild:shadow z:0];
        
        CCSprite *arrow = [CCSprite spriteWithFile:@"info_arrow.png"];
        arrow.position = ccp(size.width/2, size.height + arrow.contentSize.height/2 - 70);
        [self addChild:arrow];
        
        CCLabelTTF *title = [CCLabelTTF labelWithString:@"THE THINKER" fontName:@"Signika-Regular" fontSize:32/2];
        title.color = ccc3(51, 54, 58);
        
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"Unconver hidden thoughts: Point the\nCamera on your Friends to get an idea\nwhat's going on in their heads." fontName:@"Signika-Light" fontSize:28/2];
        label.color = ccc3(127, 127, 127);
        
        CCLabelTTF *creditstext = [CCLabelTTF labelWithString:@"Concept & Design: Dani Rolli\nCode & Development: Christoph Ebert\nIcons: Linecons, The NounProject & handcrafted\n\nv. 1.0" fontName:@"Signika-Light" fontSize:20/2];
        creditstext.color = ccc3(127, 127, 127);
        
        CCLabelTTF *creditstitle = [CCLabelTTF labelWithString:@"CREDITS" fontName:@"Signika-Regular" fontSize:22/2];
        creditstitle.color = ccc3(51, 54, 58);
        
        title.position = ccp(size.width/2, size.height - 94 - title.contentSize.height/2);
        label.position = ccp(size.width/2, size.height - 120 - label.contentSize.height/2);
        creditstitle.position = ccp(size.width/2, size.height - 275 - creditstitle.contentSize.height/2);
        creditstext.position = ccp(size.width/2, size.height - 292 - creditstext.contentSize.height/2);
        [self addChild:label z:5];
        [self addChild:title z:5];
        [self addChild:creditstext z:5];
        [self addChild:creditstitle z:5];
        
        CCMenuItemImage *aboutItem = [CCMenuItemImage itemWithNormalImage:@"info_appetite.png" selectedImage:@"info_appetite.png" target:self selector:@selector(appetiteHandler:)];
        CCMenu *menu = [CCMenu menuWithItems:aboutItem, nil];
        menu.position = ccp(0, 0);
        [aboutItem setPosition:ccp( size.width/2, size.height - aboutItem.contentSize.height / 2 - 194)];
        [self addChild:menu z:5];
        
        self.isTouchEnabled = YES;
	}
	return self;
}

-(void) appetiteHandler: (id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://app.etite.ch"]];
}

-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.parent performSelector:@selector(aboutHandler:) withObject:self];
}

@end
