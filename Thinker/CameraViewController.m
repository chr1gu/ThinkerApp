//
//  CameraViewController.m
//  Thinker
//
//  Created by Christoph Ebert on 4/15/13.
//
//

#import "CameraViewController.h"
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>

#pragma mark-

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size);
static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size)
{
	CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixel;
	CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
	CVPixelBufferRelease( pixelBuffer );
}

// create a CGImage with provided pixel buffer, pixel buffer must be uncompressed kCVPixelFormatType_32ARGB or kCVPixelFormatType_32BGRA
static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut);
static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut)
{
	OSStatus err = noErr;
	OSType sourcePixelFormat;
	size_t width, height, sourceRowBytes;
	void *sourceBaseAddr = NULL;
	CGBitmapInfo bitmapInfo;
	CGColorSpaceRef colorspace = NULL;
	CGDataProviderRef provider = NULL;
	CGImageRef image = NULL;
	
	sourcePixelFormat = CVPixelBufferGetPixelFormatType( pixelBuffer );
	if ( kCVPixelFormatType_32ARGB == sourcePixelFormat )
		bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst;
	else if ( kCVPixelFormatType_32BGRA == sourcePixelFormat )
		bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
	else
		return -95014; // only uncompressed pixel formats
	
	sourceRowBytes = CVPixelBufferGetBytesPerRow( pixelBuffer );
	width = CVPixelBufferGetWidth( pixelBuffer );
	height = CVPixelBufferGetHeight( pixelBuffer );
	
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
	sourceBaseAddr = CVPixelBufferGetBaseAddress( pixelBuffer );
	
	colorspace = CGColorSpaceCreateDeviceRGB();
    
	CVPixelBufferRetain( pixelBuffer );
	provider = CGDataProviderCreateWithData( (void *)pixelBuffer, sourceBaseAddr, sourceRowBytes * height, ReleaseCVPixelBuffer);
	image = CGImageCreate(width, height, 8, 32, sourceRowBytes, colorspace, bitmapInfo, provider, NULL, true, kCGRenderingIntentDefault);
	
bail:
	if ( err && image ) {
		CGImageRelease( image );
		image = NULL;
	}
	if ( provider ) CGDataProviderRelease( provider );
	if ( colorspace ) CGColorSpaceRelease( colorspace );
	*imageOut = image;
	return err;
}

// utility used by newSquareOverlayedImageForFeatures for
static CGContextRef CreateCGBitmapContextForSize(CGSize size);
static CGContextRef CreateCGBitmapContextForSize(CGSize size)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    int             bitmapBytesPerRow;
	
    bitmapBytesPerRow = (size.width * 4);
	
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate (NULL,
									 size.width,
									 size.height,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedLast);
	CGContextSetAllowsAntialiasing(context, NO);
    CGColorSpaceRelease( colorSpace );
    return context;
}

#pragma mark-

@interface UIImage (RotationMethods)
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees mirrored:(BOOL)isMirrored;
@end

@implementation UIImage (RotationMethods)

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees mirrored:(BOOL)isMirrored
{
	// calculate the size of the rotated view's containing box for our drawing space
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.size.width, self.size.height)];
    
	CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
	rotatedViewBox.transform = t;
	CGSize rotatedSize = rotatedViewBox.frame.size;
	[rotatedViewBox release];
	
	// Create the bitmap context
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();
	
	// Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
    //CGContextTranslateCTM(bitmap, 0, 0);
	
	//   // Rotate the image context
	CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
	
	// Now, draw the rotated/scaled image into the context
	//CGContextScaleCTM(bitmap, 1.0, -1.0);
    //CGContextScaleCTM(bitmap, -1.0, -1.0);
    // if mirrored then do that
    // invert and scale double the size because...
    if (isMirrored) {
        CGContextScaleCTM(bitmap, -1.0, -1.0);
    } else {
        CGContextScaleCTM(bitmap, 1.0, -1.0);
    }
	//CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
    
	
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
	
}

@end

#pragma mark-

@interface CameraViewController ()
// internal methods
- (void)setupAVCapture;
- (void)teardownAVCapture;
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation;
@end

@implementation CameraViewController

- (id)initWithSize:(CGSize)size
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        // Custom initialization  (init)
        CGRect frame = CGRectMake(.0f, .0f, size.width, size.height);
        self.view = [[UIView alloc] initWithFrame:frame];
        [self setupAVCapture];
        
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        faceDetector = [[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions] retain];
        [detectorOptions release];
        
        [self switchCameras:nil];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    // TODO: don't call this directly.. throw an assert
    return nil;
}

- (void)setupAVCapture
{
	NSError *error = nil;
	
	AVCaptureSession *session = [AVCaptureSession new];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	    [session setSessionPreset:AVCaptureSessionPreset640x480];
	else
	    [session setSessionPreset:AVCaptureSessionPresetPhoto];
	
    // Select a video device, make an input
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	require( error == nil, bail );
	
    isUsingFrontFacingCamera = NO;
	if ( [session canAddInput:deviceInput] )
		[session addInput:deviceInput];
	
    // Make a still image output
	stillImageOutput = [AVCaptureStillImageOutput new];
	[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:AVCaptureStillImageIsCapturingStillImageContext];
	if ( [session canAddOutput:stillImageOutput] )
		[session addOutput:stillImageOutput];
	
    // Make a video data output
	videoDataOutput = [AVCaptureVideoDataOutput new];
	
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
	NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
									   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	[videoDataOutput setVideoSettings:rgbOutputSettings];
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
	videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
	
    if ( [session canAddOutput:videoDataOutput] )
		[session addOutput:videoDataOutput];
	[[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
	
	effectiveScale = 1.0;
	previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	//[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    //[previewLayer setVideoGravity:AVLayerVideoGravityResize];
	CALayer *rootLayer = [self.view layer];
	[rootLayer setMasksToBounds:YES];
	[previewLayer setFrame:[rootLayer bounds]];
	[rootLayer addSublayer:previewLayer];
	[session startRunning];
    
bail:
	[session release];
	if (error) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"Dismiss"
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		[self teardownAVCapture];
	}
}

// clean up capture setup
- (void)teardownAVCapture
{
	[videoDataOutput release];
	if (videoDataOutputQueue)
		dispatch_release(videoDataOutputQueue);
	[stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
	[stillImageOutput release];
	[previewLayer removeFromSuperlayer];
	[previewLayer release];
}

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ( context == AVCaptureStillImageIsCapturingStillImageContext ) {
		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		if ( isCapturingStillImage ) {
			// do flash bulb like animation
			flashView = [[UIView alloc] initWithFrame:[self.view frame]];
			[flashView setBackgroundColor:[UIColor whiteColor]];
			[flashView setAlpha:0.f];
			[[[self view] window] addSubview:flashView];
			
			[UIView animateWithDuration:.4f
							 animations:^{
								 [flashView setAlpha:1.f];
							 }
			 ];
		}
		else {
			[UIView animateWithDuration:.4f
							 animations:^{
								 [flashView setAlpha:0.f];
							 }
							 completion:^(BOOL finished){
								 [flashView removeFromSuperview];
								 [flashView release];
								 flashView = nil;
							 }
			 ];
		}
	}
}

// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = deviceOrientation;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
	return result;
}

- (CGImageRef)newCameraImageWithOverlay:(UIImage *)overlay
                                       inCGImage:(CGImageRef)backgroundImage
                                 withOrientation:(UIDeviceOrientation)orientation
                                     frontFacing:(BOOL)isFrontFacing
{
	CGImageRef returnImage = NULL;
	CGRect backgroundImageRect = CGRectMake(0., 0., CGImageGetWidth(backgroundImage), CGImageGetHeight(backgroundImage));
	CGContextRef bitmapContext = CreateCGBitmapContextForSize(backgroundImageRect.size);
	CGContextClearRect(bitmapContext, backgroundImageRect);
	CGContextDrawImage(bitmapContext, backgroundImageRect, backgroundImage);
	CGFloat rotationDegrees = 0.;
	
	switch (orientation) {
		case UIDeviceOrientationPortrait:
			rotationDegrees = -90.;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			rotationDegrees = 90.;
			break;
		case UIDeviceOrientationLandscapeLeft:
			if (isFrontFacing) rotationDegrees = 180.;
			else rotationDegrees = 0.;
			break;
		case UIDeviceOrientationLandscapeRight:
			if (isFrontFacing) rotationDegrees = 0.;
			else rotationDegrees = 180.;
			break;
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		default:
			break; // leave the layer in its last known orientation
	}
    
    NSLog(@"size of bg: %f %f %f %f", backgroundImageRect.origin.x, backgroundImageRect.origin.y, backgroundImageRect.size.width, backgroundImageRect.size.height);
	
    UIImage *rotatedSquareImage = [overlay imageRotatedByDegrees:rotationDegrees mirrored:isFrontFacing];
    
    NSLog(@"size of overlay: %f %f", overlay.size.width, overlay.size.height);
    NSLog(@"size of overlay after rotation blah: %f %f", rotatedSquareImage.size.width, rotatedSquareImage.size.height);
    //CGRect overlayRect = CGRectMake(0., 0., rotatedSquareImage.size.width, rotatedSquareImage.size.height);
    
    // while capturing 2:3 ratio
    // when saving 4:3
    // get correct aperture size
    
    // 568 - (640/480*320) /2
    
    CGSize parentFrameSize = [self.view frame].size;
    //CGRect overlayRect = CGRectMake(0., 0., parentFrameSize.height/parentFrameSize.width*cleanApertureBox.size.width, cleanApertureBox.size.width);
    
    // no stretching
    //CGRect overlayRect = CGRectMake(0., 0., 568., 320.);
    //CGRect overlayRect = CGRectMake(0., 0., cleanApertureBox.size.width, cleanApertureBox.size.height);
    
    // correct ui-coordinates:
    /*float width = cleanApertureBox.size.width;
    float height = parentFrameSize.width/parentFrameSize.height*cleanApertureBox.size.width;
    float sizediff = cleanApertureBox.size.height - height;
    float xPos = sizediff/2;
    float yPos = 0;*/
    
    float width = parentFrameSize.height/parentFrameSize.width*cleanApertureBox.size.height;
    float height = cleanApertureBox.size.height;
    float sizediff = cleanApertureBox.size.width - width;
    float xPos = 0;
    float yPos = sizediff/2 + 30;
    
    CGRect overlayRect = CGRectMake(yPos, xPos, width, height);
    
    NSLog(@"overlay rect new: %f %f", overlayRect.size.width, overlayRect.size.height);
    //NSLog(@"Aperture box: %f %f", cleanApertureBox.size.width, cleanApertureBox.size.height);
    //NSLog(@"Size Difference: %f", sizediff);
    
    // transform/scale overlay rect to clean aperture size
    // correct position because picture is cropped when saving on iPhone 5
    // aperture: 480. 640. frame size: parent 320. 568.
    
    CGContextDrawImage(bitmapContext, overlayRect, [rotatedSquareImage CGImage]);
	returnImage = CGBitmapContextCreateImage(bitmapContext);
	CGContextRelease (bitmapContext);
	
	return returnImage;
}


// utility routine used after taking a still image to write the resulting image to the camera roll
- (BOOL)writeCGImageToCameraRoll:(CGImageRef)cgImage withMetadata:(NSDictionary *)metadata
{
	CFMutableDataRef destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
	CGImageDestinationRef destination = CGImageDestinationCreateWithData(destinationData,
																		 CFSTR("public.jpeg"),
																		 1,
																		 NULL);
	BOOL success = (destination != NULL);
	require(success, bail);
    
	//const float JPEGCompQuality = 0.85f; // JPEGHigherQuality
    const float JPEGCompQuality = 0.90f; // JPEGHigherQuality
	CFMutableDictionaryRef optionsDict = NULL;
	CFNumberRef qualityNum = NULL;
	
	qualityNum = CFNumberCreate(0, kCFNumberFloatType, &JPEGCompQuality);
	if ( qualityNum ) {
		optionsDict = CFDictionaryCreateMutable(0, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		if ( optionsDict )
			CFDictionarySetValue(optionsDict, kCGImageDestinationLossyCompressionQuality, qualityNum);
		CFRelease( qualityNum );
	}
    
    
	
	CGImageDestinationAddImage( destination, cgImage, optionsDict );
	success = CGImageDestinationFinalize( destination );
    
	if ( optionsDict )
		CFRelease(optionsDict);
	
	require(success, bail);
	
	CFRetain(destinationData);
	ALAssetsLibrary *library = [ALAssetsLibrary new];
	[library writeImageDataToSavedPhotosAlbum:(id)destinationData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
		if (destinationData)
			CFRelease(destinationData);
	}];
	[library release];
    
    
bail:
	if (destinationData)
		CFRelease(destinationData);
	if (destination)
		CFRelease(destination);
	return success;
}

// utility routine to display error aleart if takePicture fails
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil
												  cancelButtonTitle:@"Dismiss"
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	});
}


// save picture
- (void)savePictureWithOverlay:(UIImage *)overlay
{
    // Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
	[stillImageConnection setVideoOrientation:avcaptureOrientation];
	[stillImageConnection setVideoScaleAndCropFactor:effectiveScale];
	
    [stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                      if (error) {
                                                          [self displayErrorOnMainQueue:error withMessage:@"Take picture failed"];
                                                      }
                                                      else {
                                                          // Got an image.
                                                          CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(imageDataSampleBuffer);
                                                          CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
                                                          CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(NSDictionary *)attachments];
                                                          if (attachments)
                                                              CFRelease(attachments);
                                                          
                                                          NSDictionary *imageOptions = nil;
                                                          NSNumber *orientation = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyOrientation, NULL);
                                                          if (orientation) {
                                                              imageOptions = [NSDictionary dictionaryWithObject:orientation forKey:CIDetectorImageOrientation];
                                                          }
                                                          
                                                          // when processing an existing frame we want any new frames to be automatically dropped
                                                          // queueing this block to execute on the videoDataOutputQueue serial queue ensures this
                                                          // see the header doc for setSampleBufferDelegate:queue: for more information
                                                          dispatch_sync(videoDataOutputQueue, ^(void) {
                                                              
                                                              CGImageRef srcImage = NULL;
                                                              OSStatus err = CreateCGImageFromCVPixelBuffer(CMSampleBufferGetImageBuffer(imageDataSampleBuffer), &srcImage);
                                                              check(!err);
                                                              
                                                              
                                                              CGImageRef cgImageResult = [self
                                                                                 newCameraImageWithOverlay:overlay
                                                                                                                        inCGImage:srcImage
                                                                                                                withOrientation:curDeviceOrientation
                                                                                                                      frontFacing:isUsingFrontFacingCamera];
                                                              
                                                              if (srcImage)
                                                                  CFRelease(srcImage);
                                                              
                                                              CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault,
                                                                                 imageDataSampleBuffer,          kCMAttachmentMode_ShouldPropagate);
                                                              
                                                              
                                                              [self writeCGImageToCameraRoll:cgImageResult withMetadata:(id)attachments];
                                                              
                                                              if (attachments)
                                                                  CFRelease(attachments);
                                                              if (cgImageResult)
                                                                  CFRelease(cgImageResult);
                                                              
                                                          });
                                                          
                                                          [ciImage release];
                                                      }
                                                  }];
}


// turn on/off face detection
- (void)setFaceDetection:(BOOL)isEnabled;
{
	//detectFaces = [(UISwitch *)sender isOn];
    detectFaces = isEnabled;
	[[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:detectFaces];
	if (!detectFaces) {
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			// clear out any squares currently displaying.
			[self drawFaceBoxesForFeatures:[NSArray array] forVideoBox:CGRectZero orientation:UIDeviceOrientationPortrait];
		});
	}
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        /*if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }*/
        size.width = frameSize.width;
        size.height = frameSize.height;
        
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector (if on)
// to detect features and for each draw the red square in a layer and set appropriate orientation
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
    
    
    CGSize parentFrameSize = [self.view frame].size;
	NSString *gravity = [previewLayer videoGravity];
	CGRect previewBox = [CameraViewController videoPreviewBoxForGravity:gravity
                                                              frameSize:parentFrameSize
                                                           apertureSize:clap.size];
    
    //NSLog(@"gravity: %@ frame size: %f %f %f %f", gravity, previewBox.origin.x, previewBox.origin.y, previewBox.size.width, previewBox.size.height);
	
    //NSLog(@"faces detected: %i", [features count]);
    int index = 0;
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
		// flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
		if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
		
        
        if (interface) {
            [interface updateCloud:faceRect orientation:orientation size:CGSizeMake(faceRect.size.width, faceRect.size.height) index:index];
        }
        
        index = index+1;
    }
    
    if (interface) {
        [interface freeClouds];
    }
    
    
    
	/*[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
	
	if ( featuresCount == 0 || !detectFaces ) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [self.view frame].size;
	NSString *gravity = [previewLayer videoGravity];
	BOOL isMirrored = [previewLayer isMirrored];
	CGRect previewBox = [CameraViewController videoPreviewBoxForGravity:gravity
                                                                 frameSize:parentFrameSize
                                                              apertureSize:clap.size];
    
    //NSLog(@"gravity: %@ frame size: %f %f %f %f", gravity, previewBox.origin.x, previewBox.origin.y, previewBox.size.width, previewBox.size.height);
	
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
		// flip preview width and height
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
		if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
		
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];
			[featureLayer setContents:(id)[square CGImage]];
			[featureLayer setName:@"FaceLayer"];
			[previewLayer addSublayer:featureLayer];
			[featureLayer release];
		}
		[featureLayer setFrame:faceRect];
		
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}
		currentFeature++;
	}
	
	[CATransaction commit];*/
}

- (void)setInterface:(id)sender
{
    interface = sender;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!detectFaces) {
        return;
    }
    
	// got an image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
	NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
	[ciImage release];
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	cleanApertureBox = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features forVideoBox:cleanApertureBox orientation:curDeviceOrientation];
	});
}

- (void)dealloc
{
	[self teardownAVCapture];
	[faceDetector release];
	[super dealloc];
}

- (BOOL)getIsMirrored
{
    return isMirrored;
}

// use front/back camera
- (IBAction)switchCameras:(id)sender
{
    if (!isMirrored) {
        isMirrored = YES;
    } else {
        isMirrored = NO;
    }

	AVCaptureDevicePosition desiredPosition;
	if (isUsingFrontFacingCamera)
		desiredPosition = AVCaptureDevicePositionBack;
	else
		desiredPosition = AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			[[previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
			for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
				[[previewLayer session] removeInput:oldInput];
			}
			[[previewLayer session] addInput:input];
			[[previewLayer session] commitConfiguration];
			break;
		}
	}
	isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// scale image depending on users pinch gesture
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
	BOOL allTouchesAreOnThePreviewLayer = YES;
	NSUInteger numTouches = [recognizer numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i ) {
		CGPoint location = [recognizer locationOfTouch:i inView:self.view];
		CGPoint convertedLocation = [previewLayer convertPoint:location fromLayer:previewLayer.superlayer];
		if ( ! [previewLayer containsPoint:convertedLocation] ) {
			allTouchesAreOnThePreviewLayer = NO;
			break;
		}
	}
	
	if ( allTouchesAreOnThePreviewLayer ) {
		effectiveScale = beginGestureScale * recognizer.scale;
		if (effectiveScale < 1.0)
			effectiveScale = 1.0;
		CGFloat maxScaleAndCropFactor = [[stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
		if (effectiveScale > maxScaleAndCropFactor)
			effectiveScale = maxScaleAndCropFactor;
		[CATransaction begin];
		[CATransaction setAnimationDuration:.025];
		[previewLayer setAffineTransform:CGAffineTransformMakeScale(effectiveScale, effectiveScale)];
		[CATransaction commit];
	}
}

@end
