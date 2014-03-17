//
//  FacebookPostPhone.m
//  Thinker
//
//  Created by Christoph Ebert on 5/9/13.
//
//

#import "FacebookPostPhone.h"
#import <QuartzCore/QuartzCore.h>
#import "SocialManager.h"

NSString *const kPlaceholderPostMessage = @"Tell your friends...";

@interface FacebookPostPhone ()

@end

@implementation FacebookPostPhone

@synthesize postMessageTextView;
@synthesize prefilledText;
@synthesize subview;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil placeholderText:(NSString *)text
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.prefilledText = text;
    }
    return self;
}

- (void)resetPostMessage
{
    self.postMessageTextView.text = kPlaceholderPostMessage;
    self.postMessageTextView.textColor = [UIColor lightGrayColor];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // Clear the message text when the user starts editing
    if ([textView.text isEqualToString:kPlaceholderPostMessage]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    // Reset to placeholder text if the user is done
    // editing and no message has been entered.
    if ([textView.text isEqualToString:@""]) {
        [self resetPostMessage];
    }
}


- (IBAction)cancelButtonAction:(id)sender
{
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
}

- (IBAction)postButtonAction:(id)sender
{
    if ([self.postMessageTextView isFirstResponder]) {
        [self.postMessageTextView resignFirstResponder];
    }
    [SocialManager publishFacebookStatus:self.postMessageTextView.text];
    [[self presentingViewController] dismissModalViewControllerAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.subview.layer.cornerRadius = 5;
    self.subview.layer.masksToBounds = YES;
    self.postMessageTextView.text = self.prefilledText;
    if ([self.postMessageTextView.text isEqualToString:@""]) {
        [self resetPostMessage];
    }
    [postMessageTextView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
