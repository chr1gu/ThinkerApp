//
//  ThoughtCloud.h
//  Thinker
//
//  Created by Christoph Ebert on 4/22/13.
//
//

#import "CCSprite.h"
#import "ThoughtCloudItem.h"

@interface ThoughtCloud : CCSprite
{
    CGPoint cloudBOffset;
    ThoughtCloudItem *cloudB;
    ThoughtCloudItem *cloudM;
    ThoughtCloudItem *cloudS;
    ThoughtCloudItem *thought;
    BOOL cloudIsBusy;
    BOOL free;
    float distancePoint;
}

+(id)thoughtCloud;

-(void)setCloudBOffset: (CGPoint)offset;
-(void)setIsFree: (BOOL)setting;
-(BOOL)isFree;
-(float)lastDistancePoint;
-(void)updateThought;
-(void)refreshThought;
-(void)updateCloud:(CGRect)faceRect orientation:(UIDeviceOrientation)orientation size:(CGSize)size;
-(void)updateIsMirrored: (BOOL)mirrored;

@end
