//
//  OpenCVBridge.h
//  LookinLive
//
//  Created by Michael Deweese.
//  Copyright (c) Eric Larson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>
#import "AVFoundation/AVFoundation.h"

#import "PrefixHeader.pch"

@class VisionAnalgesic;
@protocol VisionAnalgesicProtocol;



@interface OpenCVBridge : NSObject

@property (nonatomic) NSInteger processType;

//@property (assign) BOOL processFinger;



+(VisionAnalgesic *)toggleFlash;

+(VisionAnalgesic *)turnOnFlashwithLevel:(float)level;


// set the image for processing later
-(void) setImage:(CIImage*)ciFrameImage
      withBounds:(CGRect)rect
      andContext:(CIContext*)context;

//get the image raw opencv
-(CIImage*)getImage;

//get the image inside the original bounds
-(CIImage*)getImageComposite;

// call this to perfrom processing (user controlled for better transparency)
-(void)processImage;

// for the video manager transformations
-(void)setTransforms:(CGAffineTransform)trans;

-(void)loadHaarCascadeWithFilename:(NSString*)filename;

-(void)myProcessFinger;

-(bool)processFinger;

-(void)myProcessFingerStage1;

-(void)myProcessFingerStage2;





@end




