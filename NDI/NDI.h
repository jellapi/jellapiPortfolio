//
//  NDI.h
//  NDI
//
//  Created by Jellapi on 2022/03/08.
//
#ifndef NDI_h
#define NDI_h

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioToolbox/AudioUnit.h>
#import <CoreMedia/CMSampleBuffer.h>
#import <CoreGraphics/CoreGraphics.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import <VideoToolbox/VideoToolbox.h>
#import "ImageProcessing.h"

FOUNDATION_EXPORT double NDIVersionNumber;
FOUNDATION_EXPORT const unsigned char NDIVersionString[];

@interface NDI : NSObject <H264HwEncoderImplDelegate>

+ (void) initialize;
- (void) setWatermarkImage:(UIImage *)image withPosition:(CGPoint)point;
- (void) start:(NSString *)name;
- (void) start:(NSString *)name clippingAudio:(BOOL)isClippingaudio;
- (void) stop;
- (void) removeNDI;
- (BOOL) isStarted;
- (void) sendVideoAdv:(CMSampleBufferRef)sampleBuffer;
- (void)sendVideo:(CVPixelBufferRef)pixelBuffer withOrientation:(int)orientation;

/// default PCM16
- (void)sendAudio:(CMSampleBufferRef)sampleBuffer;

@end

#endif
