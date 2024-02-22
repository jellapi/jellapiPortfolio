//
//  ImageProcessing.h
//  NDI
//
//  Created by Jellapi on 2022/03/17.
//
//

#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>

@interface ImageProcessing : NSObject
@property (nonatomic) CGPoint watermarkPostion;
@property (nonatomic) int orientation;
- (CVPixelBufferRef) toBGRA:(CVPixelBufferRef)pixelBuffer;

- (bool) convertYpCbCr:(CVPixelBufferRef)pixelBuffer argbBuffer:(vImage_Buffer*)argbBuffer;
- (CVPixelBufferRef) getWatermarkWithPixelBufferWithFilter:(BOOL)isFiltering pixelBuffer:(CVPixelBufferRef)pixelBuffer watermarkImage:(UIImage*) watermarkImage;

@end


@interface AIDefer : NSObject

@property (copy, nonatomic) void (^block)();
+ (instancetype)defer:(void (^)())block;

@end


@protocol H264HwEncoderImplDelegate <NSObject>

- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps;
- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame;

@end


@interface H264HwEncoderImpl : NSObject

- (void) initWithConfiguration;
- (void) initEncode:(int)width  height:(int)height;
- (void) changeResolution:(int)width  height:(int)height;
- (void) encode:(CMSampleBufferRef )sampleBuffer;
- (void) End;


@property (weak, nonatomic) NSString *error;
@property (weak, nonatomic) id<H264HwEncoderImplDelegate> delegate;

@end


