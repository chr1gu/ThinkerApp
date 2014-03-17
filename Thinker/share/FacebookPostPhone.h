//
//  FacebookPostPhone.h
//  Thinker
//
//  Created by Christoph Ebert on 5/9/13.
//
//

#import <UIKit/UIKit.h>

@interface FacebookPostPhone : UIViewController

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)postButtonAction:(id)sender;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil placeholderText:(NSString *)text;

@property (nonatomic, retain) IBOutlet UIView *subview;
@property (nonatomic, retain) IBOutlet UITextView *postMessageTextView;
@property (nonatomic, retain) NSString *prefilledText;

@end
