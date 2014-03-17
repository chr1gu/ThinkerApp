//
//  CameraViewController.h
//  Thinker
//
//  Created by Christoph Ebert on 4/15/13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@class CIDetector;

@interface CameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    id interface;
	IBOutlet UISegmentedControl *camerasControl;
	AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
	BOOL detectFaces;
    BOOL isMirrored;
	dispatch_queue_t videoDataOutputQueue;
	AVCaptureStillImageOutput *stillImageOutput;
	UIView *flashView;
	BOOL isUsingFrontFacingCamera;
	CIDetector *faceDetector;
	CGFloat beginGestureScale;
	CGFloat effectiveScale;
    CGRect cleanApertureBox;
}

- (BOOL)getIsMirrored;
- (void)setInterface:(id)sender;
- (id)initWithSize:(CGSize)size;
- (IBAction)takePicture:(id)sender;
- (void)savePictureWithOverlay:(UIImage *)overlay;
- (IBAction)switchCameras:(id)sender;
- (IBAction)handlePinchGesture:(UIGestureRecognizer *)sender;
- (void)setFaceDetection:(BOOL)isEnabled;

@end
