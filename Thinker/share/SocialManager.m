//
//  SocialManager.m
//  Lightwriter
//
//  Created by Christoph Ebert on 1/14/13.
//
//

#import "SocialManager.h"
#import <Social/Social.h>
#import <FacebookSDK/FacebookSDK.h>
#import "FacebookPostPhone.h"
//#import "AppDelegate.h"

#define fbAppId @"119208194917762"
//#define fbAppId @"355198514515820"
#define fbAppSecret @"60ed0a94eaca4535b4131386f6d9d428"

// http://stackoverflow.com/questions/12509327/ios6-social-framework-how-does-slcomposeviewcontroller-fallback-to-twtweetco
// http://developers.facebook.com/docs/getting-started/facebook-sdk-for-ios/3.1/
// http://stackoverflow.com/questions/6709469/facebook-ios-sdk-question
// http://stackoverflow.com/questions/13621599/facebook-ios-sdk-3-1-1-with-xcode-4-5-2-error

@implementation SocialManager

+(BOOL)isSocialFrameworkAvailable
{
    // whether the iOS6 Social framework is available?
    return NSClassFromString(@"SLComposeViewController") != nil;
}

+(BOOL) handleOpenURL: (NSURL *)url
{
    return [FBSession.activeSession handleOpenURL:url];
}

+(void) handleDidBecomeActive
{
    if (![FBSession defaultAppID]) {
        [FBSession setDefaultAppID:fbAppId];
    }
    [FBSession.activeSession handleDidBecomeActive];
}

+(void) handleWillTerminate
{
    [FBSession.activeSession close];
}

+(void) setFacebookMessage
{
    if (![FBSession defaultAppID]) {
        [FBSession setDefaultAppID:fbAppId];
    }
    
    // this can be changed with a predefined text
    NSString *initialTextiOS6 = @"Naughty or nice? Visualize the thoughts of your friends with TheThinker App. It's free, fun and a little creepy.";
    NSString *initialText = @"Naughty or nice? Visualize the thoughts of your friends with TheThinker App. It's free, fun and a little creepy: http://goo.gl/GCfjZ";

    // if it is available to us, we will post using the native dialog IOS6
    BOOL displayedNativeDialog = [FBNativeDialogs presentShareDialogModallyFrom:[CCDirector sharedDirector]
                                                                    initialText:initialTextiOS6
                                                                          image:nil
                                                                            url:[NSURL URLWithString:@"http://goo.gl/GCfjZ"]
                                                                        handler:nil];
    
    if (!displayedNativeDialog) {
        // for debugging kill session
        //[FBSession.activeSession closeAndClearTokenInformation];
        
        if (FBSession.activeSession.isOpen || FBSession.activeSession.state==FBSessionStateCreatedTokenLoaded) {
            // Yes, so just open the session (this won't display any UX).
            FacebookPostPhone *viewController =
            [[FacebookPostPhone alloc] initWithNibName:@"FacebookPostPhone" bundle:nil placeholderText:initialText];
            //[[viewController view] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [[CCDirector sharedDirector] presentModalViewController:viewController animated:YES];
            //[[[CCDirector sharedDirector] view] addSubview:[viewController view]];
            [viewController release];
            
        } else {
            // No, display the login page.
            [self showLoginView];
        }
    }
}

+ (void)publishFacebookStatus: (NSString *)text
{
    [self openSession];
    [self performPublishAction:^{
        // otherwise fall back on a request for permissions and a direct post
        [FBRequestConnection startForPostStatusUpdate:text completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
            //[self showAlert:message result:result error:error];
        }];
    }];
}

+ (void)showLoginView
{
    [self openSessionWithAllowLoginUI:YES];
}

+ (void)openSession
{
    [FBSession openActiveSessionWithReadPermissions:nil
                                       allowLoginUI:NO
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}

+ (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            //NSLog(@"FB session opened");
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            //NSLog(@"FB session closed");
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

+ (BOOL)openSessionWithAllowLoginUI:(BOOL)allowLoginUI
{
    //[facebook authorizeWithFBAppAuth:NO safariAuth:NO];
    
    NSArray *permissions = [[NSArray alloc] initWithObjects: @"publish_actions", nil];
    return [FBSession openActiveSessionWithPublishPermissions:permissions defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:allowLoginUI completionHandler:^(FBSession *session, FBSessionState state, NSError *error)
    {
        [self sessionStateChanged:session state:state error:error];
    }];
}

+ (void) performPublishAction:(void (^)(void)) action {
    // we defer request for permission to post to the moment of post, then we check for the permission
    if ([FBSession.activeSession.permissions indexOfObject:@"publish_actions"] == NSNotFound) {
        // if we don't already have the permission, then we request it now
        [FBSession.activeSession reauthorizeWithPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                                   defaultAudience:FBSessionDefaultAudienceFriends
                                                 completionHandler:^(FBSession *session, NSError *error) {
                                                     if (!error) {
                                                         action();
                                                     }
                                                     //For this example, ignore errors (such as if user cancels).
                                                 }];
    } else {
        action();
    }
}

@end
