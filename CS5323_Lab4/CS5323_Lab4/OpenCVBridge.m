//
//  OpenCVBridge.m`
//  LookinLive
//
//  Created by Michael DeWeese.
//  Copyright (c) Eric Larson. All rights reserved.
//

#import "OpenCVBridge.h"
#import "QuartzCore/QuartzCore.h"






using namespace cv;

@interface OpenCVBridge()
@property (nonatomic) cv::Mat image;
@property (strong,nonatomic) CIImage* frameInput;
@property (nonatomic) CGRect bounds;
@property (nonatomic) CGAffineTransform transform;
@property (nonatomic) CGAffineTransform inverseTransform;
@property (atomic) cv::CascadeClassifier classifier;
@property (nonatomic) VisionAnalgesic* toggleFlash;
@property (nonatomic) VisionAnalgesic* turnOnFlashwithLevel;




@end

@implementation OpenCVBridge

//@synthesize processFinger = processFinger_;

#pragma mark ===Write Your Code Here===
// you can define your own functions here for processing the image


//Create process Finger bool function
-(bool)processFinger{
   
    
    cv::Mat frame_gray,image_copy;
    const int kCannyLowThreshold = 150;
    const int kFilterKernelSize = 5;
    
            
    // fine, adding scoping to case statements to get rid of jump errors
    // FOR FLIPPED ASSIGNMENT, YOU MAY BE INTERESTED IN THIS EXAMPLE
    char text[50];
    Scalar avgPixelIntensity;
   
    
    
    
    
    cvtColor(_image, image_copy, CV_BGRA2BGR); // get rid of alpha for processing
    avgPixelIntensity = cv::mean( image_copy );
    // they say that sprintf is depricated, but it still works for c++
    sprintf(text,"Avg. R: %.0f, G: %.0f, B: %.0f", avgPixelIntensity.val[0],avgPixelIntensity.val[1],avgPixelIntensity.val[2]);
    cv::putText(_image, text, cv::Point(0, 20), FONT_HERSHEY_PLAIN, 2.0, Scalar::all(255), 1, 2);
    int n = 0;
    
    //Check if threshold is met to toggle torch to on and disable UI buttons
    //It is important to check both high end or low end equally as both can indicate something is covering the camer lens.
    while( ( (int(avgPixelIntensity.val[0]) <= int(20)) && (int(avgPixelIntensity.val[1]) <= int(5) ) && (int(avgPixelIntensity.val[2]) <= int(5))) || ( (int(avgPixelIntensity.val[0]) >= int(200)) ||(int(avgPixelIntensity.val[1]) >= int(200) ) || (int(avgPixelIntensity.val[2]) >= int(200))) && (n < 100))
    {
        //Create arrays to save average blue, red and green values
        CFTimeInterval startTime = CACurrentMediaTime();
        float blueArray[100];
        float redArray[100];
        float greenArray[100];
        for ( n = 0; n <= 100; n++){
            avgPixelIntensity = cv::mean( image_copy );
            
            redArray[n] = avgPixelIntensity.val[0];
            greenArray[n] = avgPixelIntensity.val[1];
            blueArray[n] = avgPixelIntensity.val[2];
            
        
            
        }
        CFTimeInterval elapsedTime = CACurrentMediaTime() - startTime;
        NSLog(@" %f",elapsedTime);
        
        
        //Show finger has been seen and arrays have been saved
        sprintf(text,"Finger Seen. Saved Array. R: %.0f, G: %.0f, B: %.0f", redArray[99], greenArray[99], blueArray[99]);
        cv::putText(_image, text, cv::Point(0, 50), FONT_HERSHEY_PLAIN, 2.0, Scalar::all(255), 1, 2);
        
        //Traverse through array of average RBG values
        for ( int i = 0; i <= 100; i++){
            sprintf(text,"R: %.0f, G: %.0f, B: %.0f", redArray[i], greenArray[i], blueArray[i]);
            cv::putText(_image, text, cv::Point(0, (i*50)+ 100), FONT_HERSHEY_PLAIN, 2.0, Scalar::all(255), 1, 2);
        }
        //If finger seen return true
        return true;
        
       
    }
    //if finger not seen return false
    return false;
    

    


}




#pragma mark ====Do Not Manipulate Code below this line!====
-(void)setTransforms:(CGAffineTransform)trans{
    self.inverseTransform = trans;
    self.transform = CGAffineTransformInvert(trans);
}

-(void)loadHaarCascadeWithFilename:(NSString*)filename{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"xml"];
    self.classifier = cv::CascadeClassifier([filePath UTF8String]);
}

-(instancetype)init{
    self = [super init];
    
    if(self != nil){
        //self.transform = CGAffineTransformMakeRotation(M_PI_2);
        //self.transform = CGAffineTransformScale(self.transform, -1.0, 1.0);
        
        //self.inverseTransform = CGAffineTransformMakeScale(-1.0,1.0);
        //self.inverseTransform = CGAffineTransformRotate(self.inverseTransform, -M_PI_2);
        self.transform = CGAffineTransformIdentity;
        self.inverseTransform = CGAffineTransformIdentity;
        
    }
    return self;
}

#pragma mark Bridging OpenCV/CI Functions
// code manipulated from
// http://stackoverflow.com/questions/30867351/best-way-to-create-a-mat-from-a-ciimage
// http://stackoverflow.com/questions/10254141/how-to-convert-from-cvmat-to-uiimage-in-objective-c


-(void) setImage:(CIImage*)ciFrameImage
      withBounds:(CGRect)faceRectIn
      andContext:(CIContext*)context{
    
    CGRect faceRect = CGRect(faceRectIn);
    faceRect = CGRectApplyAffineTransform(faceRect, self.transform);
    ciFrameImage = [ciFrameImage imageByApplyingTransform:self.transform];
    
    
    //get face bounds and copy over smaller face image as CIImage
    //CGRect faceRect = faceFeature.bounds;
    _frameInput = ciFrameImage; // save this for later
    _bounds = faceRect;
    CIImage *faceImage = [ciFrameImage imageByCroppingToRect:faceRect];
    CGImageRef faceImageCG = [context createCGImage:faceImage fromRect:faceRect];
    
    // setup the OPenCV mat fro copying into
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(faceImageCG);
    CGFloat cols = faceRect.size.width;
    CGFloat rows = faceRect.size.height;
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    _image = cvMat;
    
    // setup the copy buffer (to copy from the GPU)
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                // Pointer to backing data
                                                    cols,                      // Width of bitmap
                                                    rows,                      // Height of bitmap
                                                    8,                         // Bits per component
                                                    cvMat.step[0],             // Bytes per row
                                                    colorSpace,                // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    //kCGImageAlphaLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    // do the copy
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), faceImageCG);
    
    // release intermediary buffer objects
    CGContextRelease(contextRef);
    CGImageRelease(faceImageCG);
    
}

-(CIImage*)getImage{
    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:_image.data
                                  length:_image.elemSize() * _image.total()];
    
    CGColorSpaceRef colorSpace;
    if (_image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(_image.cols,                                     // Width
                                        _image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * _image.elemSize(),                           // Bits per pixel
                                        _image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        //kCGImageAlphaLast |
                                        kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.bounds.origin.x, self.bounds.origin.y);
    retImage = [retImage imageByApplyingTransform:transform];
    retImage = [retImage imageByApplyingTransform:self.inverseTransform];
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return retImage;
}

-(CIImage*)getImageComposite{
    
    // convert back
    // setup NS byte buffer using the data from the cvMat to show
    NSData *data = [NSData dataWithBytes:_image.data
                                  length:_image.elemSize() * _image.total()];
    
    CGColorSpaceRef colorSpace;
    if (_image.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    // setup buffering object
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // setup the copy to go from CPU to GPU
    CGImageRef imageRef = CGImageCreate(_image.cols,                                     // Width
                                        _image.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * _image.elemSize(),                           // Bits per pixel
                                        _image.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        //kCGImageAlphaLast |
                                        kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    // do the copy inside of the object instantiation for retImage
    CIImage* retImage = [[CIImage alloc]initWithCGImage:imageRef];
    // now apply transforms to get what the original image would be inside the Core Image frame
    CGAffineTransform transform = CGAffineTransformMakeTranslation(self.bounds.origin.x, self.bounds.origin.y);
    retImage = [retImage imageByApplyingTransform:transform];
    CIFilter* filt = [CIFilter filterWithName:@"CISourceAtopCompositing"
                          withInputParameters:@{@"inputImage":retImage,@"inputBackgroundImage":self.frameInput}];
    retImage = filt.outputImage;
    
    // clean up
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    retImage = [retImage imageByApplyingTransform:self.inverseTransform];
    
    return retImage;
}


@end
