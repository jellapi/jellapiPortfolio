//
//  ImageProcessing.m
//  NDI
//
//  Created by Jellapi on 2022/03/17.
//
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import "ImageProcessing.h"
#include "NDIDataModel.h"

#import <VideoToolbox/VideoToolbox.h>

@implementation AIDefer
+ (instancetype)defer:(void (^)())block {
  AIDefer* defer =  [[AIDefer alloc] init];
  defer.block = block;
  return defer;
}
- (void)dealloc {
  if (_block)
    _block();
}
@end

void defer(void (^block)()) {
  static AIDefer* __weak d;
  d = [AIDefer defer:block];
}

@implementation ImageProcessing
@synthesize watermarkPostion,orientation;


// input to ARGB
- (CVPixelBufferRef) toBGRA:(CVPixelBufferRef)pixelBuffer {
  OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);
  CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  VImage yImage = [self initWithPixelBuffer:pixelBuffer plane:0];
  VImage cbcrImage = [self initWithPixelBuffer:pixelBuffer plane:1];
  CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  CVPixelBufferRef outPixelBuffer = [self makePixelBuffer:yImage.width height:yImage.height format:kCVPixelFormatType_32BGRA];
  CVPixelBufferLockBaseAddress(outPixelBuffer, kCVPixelBufferLock_ReadOnly);
  VImage argbImage = [self initWithPixelBuffer:outPixelBuffer];
  CVPixelBufferUnlockBaseAddress(outPixelBuffer, kCVPixelBufferLock_ReadOnly);
  
  [self drawVImageBuffer:argbImage.buffer yBuffer:yImage.buffer cbcrBuffer:cbcrImage.buffer];
  uint8_t channelMap[4] = {3, 2, 1, 0};
  [self permuteWithPixelBuffer:argbImage.buffer channelMap:channelMap];
  return outPixelBuffer;
}

- (VImage) initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer  {
  VImage vImage;
  void* rawBuffer = CVPixelBufferGetBaseAddress(pixelBuffer);
  if(rawBuffer == nil) {
    assert(0);
  }
  vImage.width = CVPixelBufferGetWidth(pixelBuffer);
  vImage.height = CVPixelBufferGetHeight(pixelBuffer);
  vImage.bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
  vImage.buffer.data = rawBuffer;
  vImage.buffer.height = vImagePixelCount(vImage.height);
  vImage.buffer.width = vImagePixelCount(vImage.width);
  vImage.buffer.rowBytes = vImage.bytesPerRow;
  return vImage;
}

- (VImage) initWithPixelBuffer:(CVPixelBufferRef)pixelBuffer plane:(int)plane {
  VImage vImage;
  void* rawBuffer = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, plane);
  if(rawBuffer == nil) {
    assert(0);
  }
  vImage.width = CVPixelBufferGetWidthOfPlane(pixelBuffer, plane);
  vImage.height = CVPixelBufferGetHeightOfPlane(pixelBuffer, plane);
  vImage.bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, plane);
  vImage.buffer.data = rawBuffer;
  vImage.buffer.height = vImagePixelCount(vImage.height);
  vImage.buffer.width = vImagePixelCount(vImage.width);
  vImage.buffer.rowBytes = vImage.bytesPerRow;
  return vImage;
}


- (void) drawVImageBuffer:(vImage_Buffer)vImageBuffer yBuffer:(vImage_Buffer)yBuffer cbcrBuffer:(vImage_Buffer)cbcrBuffer {
  vImage_YpCbCrPixelRange pixelRange;
  pixelRange.Yp_bias = 0;
  pixelRange.CbCr_bias = 128;
  pixelRange.YpRangeMax = 255;
  pixelRange.CbCrRangeMax = 255;
  pixelRange.YpMax = 255;
  pixelRange.YpMin = 1;
  pixelRange.CbCrMax = 255;
  pixelRange.CbCrMin = 0;
  
  vImage_YpCbCrToARGB conversionMatrix;
  if(vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_709_2, &pixelRange, &conversionMatrix, kvImage420Yp8_CbCr8, kvImageARGB8888, vImage_Flags(kvImageNoFlags)) != kvImageNoError ) {
    assert(0);
  }
  
  if(vImageConvert_420Yp8_CbCr8ToARGB8888(&yBuffer, &cbcrBuffer, &vImageBuffer, &conversionMatrix, nil, 255, vImage_Flags(kvImageNoFlags)) != kvImageNoError) {
    assert(0);
  }
}

- (void) permuteWithPixelBuffer:(vImage_Buffer)vBuffer channelMap:(uint8_t*)channelMap {
  vImagePermuteChannels_ARGB8888(&vBuffer, &vBuffer, channelMap, 0);
}

- (CVPixelBufferRef) makePixelBuffer:(size_t)width height:(size_t)height format:(OSType)format {
  CVPixelBufferRef pixelBuffer;
  CVPixelBufferCreate(kCFAllocatorDefault, width, height, format, nil, &pixelBuffer);
  return pixelBuffer;
}

- (uint8_t*) convertARGBtoXY:(vImage_Buffer)sampleBuffer {
  int bpp = 4;
  uint8_t* src = (uint8_t*)sampleBuffer.data;
  uint8_t* dest = (uint8_t*)malloc(sampleBuffer.width * sampleBuffer.height * bpp);
  for(int y = 0; y < sampleBuffer.height; y++) {
    for(int x = 0; x < sampleBuffer.width; x++) {
      int dstPoint = y * (int)sampleBuffer.width * bpp + x * bpp;
      int xyPoint = y * bpp + (int)sampleBuffer.width * x * bpp;
      uint8_t* pDst = (uint8_t*)(src + dstPoint);
      uint8_t* pDstXY = (uint8_t*)(dest + xyPoint);
      uint8_t value0 = *(pDst+0);
      uint8_t value1 = *(pDst+1);
      
      // ARGB to RGBA
      //            *(pDst+0) = *(pDst+1);
      //            *(pDst+1) = *(pDst+2);
      //            *(pDst+2) = *(pDst+3);
      //            *(pDst+3) = value0;
      
      *(pDstXY+0) = *(pDst+1);
      *(pDstXY+1) = *(pDst+2);
      *(pDstXY+2) = *(pDst+3);
      *(pDstXY+3) = value0;
      
      //  0  1  2  3  4  5  6  7  8  9
      // 10 11 12 13 14 15 16 17 18 19
      // x + (y * 10)
      
      //  0 10 20 30 40 50 60 70 80 90
      //  1 11 21 31 41 51 61 71 81 91
      // (x * 10) + y
      
      // ARGB to BGRA
      //            *(pDst+0) = *(pDst+3);
      //            *(pDst+1) = *(pDst+2);
      //            *(pDst+2) = value1;
      //            *(pDst+3) = value0;
      
      // BGRA to RGBA
      //            uint8_t value = *(pDst+0);
      //            *(pDst+0) = *(pDst+2);
      //            *(pDst+2) = value;
    }
  }
  free(sampleBuffer.data);
  return dest;
}

// to ARGB
- (uint8_t*) CMSampleBufferBGRAPointer:(CMSampleBufferRef)sampleBuffer {
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CVPixelBufferLockBaseAddress(imageBuffer,0);
  
  uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
  size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
  size_t dataSize = CVPixelBufferGetDataSize(imageBuffer);
  
  size_t width = bytesPerRow/4;
  size_t height = dataSize/bytesPerRow;
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef bitmapContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
  CGImageRef cgImage = CGBitmapContextCreateImage(bitmapContext);
  
  CVPixelBufferUnlockBaseAddress(imageBuffer,0);
  CGContextRelease(bitmapContext);
  CGColorSpaceRelease(colorSpace);
  
  NSMutableData *rgbData = [(__bridge_transfer NSData *)CGDataProviderCopyData(CGImageGetDataProvider(cgImage)) mutableCopy];
  CGImageRelease(cgImage);
  return (uint8_t*)[rgbData mutableBytes];
}

- (vImage_YpCbCrToARGB) getConversionInfoYpCbCrToARGB {
  vImage_YpCbCrPixelRange pixelRange;
  pixelRange.Yp_bias = 16;
  pixelRange.CbCr_bias = 128;
  pixelRange.YpRangeMax = 235;
  pixelRange.CbCrRangeMax = 240;
  pixelRange.YpMax = 235;
  pixelRange.YpMin = 16;
  pixelRange.CbCrMax = 240;
  pixelRange.CbCrMin = 16;
  vImage_YpCbCrToARGB infoYpCbCrToARGB;
  if(vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, &pixelRange, &infoYpCbCrToARGB, kvImage422CbYpCrYp8, kvImageARGB8888, vImage_Flags(kvImageNoFlags)) != kvImageNoError ) {
    assert(0);
  }
  return infoYpCbCrToARGB;
}

// Convert a YpCbCr format pixel buffer into ARGB data.
- (bool) convertYpCbCr:(CVPixelBufferRef)pixelBuffer argbBuffer:(vImage_Buffer*)argbBuffer {
  vImage_YpCbCrToARGB conversionInfoYpCbCrToARGB = [self getConversionInfoYpCbCrToARGB];
  CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  
  defer(^() {
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  });
  if (CVPixelBufferGetPlaneCount(pixelBuffer) != 2) {
    return false;
  }
  
  void* lumaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
  size_t lumaWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
  size_t lumaHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
  size_t lumaRowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
  vImage_Buffer sourceLumaBuffer;
  sourceLumaBuffer.data = lumaBaseAddress;
  sourceLumaBuffer.height = vImagePixelCount(lumaHeight);
  sourceLumaBuffer.width = vImagePixelCount(lumaWidth);
  sourceLumaBuffer.rowBytes = lumaRowBytes;
  
  void* chromaBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
  size_t chromaWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
  size_t chromaHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
  size_t chromaRowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
  vImage_Buffer sourceChromaBuffer;
  sourceChromaBuffer.data = chromaBaseAddress;
  sourceChromaBuffer.height = vImagePixelCount(chromaHeight);
  sourceChromaBuffer.width = vImagePixelCount(chromaWidth);
  sourceChromaBuffer.rowBytes = chromaRowBytes;
  
  if(argbBuffer->data == nil || argbBuffer->width != sourceLumaBuffer.width || argbBuffer->height != sourceLumaBuffer.height || argbBuffer->rowBytes != sourceLumaBuffer.width * 4) {
    if(vImageBuffer_Init(argbBuffer, sourceLumaBuffer.height, sourceLumaBuffer.width, 32, vImage_Flags(kvImageNoFlags)) != kvImageNoError) {
      return false;
    }
  }
  
  if(vImageConvert_420Yp8_CbCr8ToARGB8888(&sourceLumaBuffer, &sourceChromaBuffer, argbBuffer, &conversionInfoYpCbCrToARGB, nil, 255, vImage_Flags(kvImageNoFlags)) != kvImageNoError) {
    return false;
  }
  
  return true;
}


- (uint8_t*) convertARGBto:(vImage_Buffer)sampleBuffer {
  int bpp = 4;
  uint8_t* src = (uint8_t*)sampleBuffer.data;
  for(int y = 0; y < sampleBuffer.height; y++) {
    for(int x = 0; x < sampleBuffer.width; x++) {
      uint8_t* pDst = (uint8_t*)(src + y * (int)sampleBuffer.width * bpp + x * bpp);
      uint8_t value0 = *(pDst+0);
      uint8_t value1 = *(pDst+1);
      
      // ARGB to RGBA
      //            *(pDst+0) = *(pDst+1);
      //            *(pDst+1) = *(pDst+2);
      //            *(pDst+2) = *(pDst+3);
      //            *(pDst+3) = value;
      
      // ARGB to BGRA
      *(pDst+0) = *(pDst+3);
      *(pDst+1) = *(pDst+2);
      *(pDst+2) = value1;
      *(pDst+3) = value0;
      
      // BGRA to RGBA
      //            uint8_t value = *(pDst+0);
      //            *(pDst+0) = *(pDst+2);
      //            *(pDst+2) = value;
    }
  }
  return src;
}

uint8_t clamp(int16_t input)
{
  input &= ~(input >> 16);
  uint8_t saturationMask = input >> 8;
  saturationMask |= saturationMask << 4;
  saturationMask |= saturationMask << 2;
  saturationMask |= saturationMask << 1;
  input |= saturationMask;
  
  return input&0xff;
}

- (void*)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  CVPixelBufferLockBaseAddress(imageBuffer,0);
  
  size_t width = CVPixelBufferGetWidth(imageBuffer);
  size_t height = CVPixelBufferGetHeight(imageBuffer);
  uint8_t *yBuffer = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
  size_t yPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
  uint8_t *cbCrBuffer = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
  size_t cbCrPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
  
  int bytesPerPixel = 4;
  uint8_t *rgbBuffer = (uint8_t*)malloc(width * height * bytesPerPixel);
  
  for(int y = 0; y < height; y++) {
    uint8_t *rgbBufferLine = &rgbBuffer[y * width * bytesPerPixel];
    uint8_t *yBufferLine = &yBuffer[y * yPitch];
    uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
    
    for(int x = 0; x < width; x++) {
      int16_t y = yBufferLine[x];
      int16_t cb = cbCrBufferLine[x & ~1] - 128;
      int16_t cr = cbCrBufferLine[x | 1] - 128;
      
      uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
      
      int16_t r = (int16_t)roundf( y + cr *  1.4 );
      int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
      int16_t b = (int16_t)roundf( y + cb *  1.765);
      
      rgbOutput[0] = 0xff;
      rgbOutput[1] = clamp(b);
      rgbOutput[2] = clamp(g);
      rgbOutput[3] = clamp(r);
    }
  }
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(rgbBuffer, width, height, 8, width * bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
  CGImageRef quartzImage = CGBitmapContextCreateImage(context);
  
  CGContextRelease(context);
  CGColorSpaceRelease(colorSpace);
  CGImageRelease(quartzImage);
  free(rgbBuffer);
  
  CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
  
  return rgbBuffer;
}

- (UIImage*) mergeImage:(UIImage*)firstImage secondImage:(UIImage*)secondImage {
  
  UIImage* waterMarkImage = [UIImage imageWithCGImage:secondImage.CGImage];
  CGRect renderAreaRect = CGRectMake(0, 0, firstImage.size.width, firstImage.size.height);
  CGSize renderAreaSize = CGSizeMake(renderAreaRect.size.width, renderAreaRect.size.height);
  CGRect uiRect = [[UIScreen mainScreen] bounds];
  CGFloat sizeDiff = (renderAreaSize.width * renderAreaSize.height) / (uiRect.size.width * uiRect.size.height);
  
  CGFloat wmWidth = waterMarkImage.size.width * sizeDiff;
  CGFloat wmHeight = waterMarkImage.size.height * sizeDiff;
  
  if(wmWidth > 100 || wmHeight > 100) {
    if(wmWidth > wmHeight) {
      CGFloat ratio = (100 / wmWidth);
      wmWidth = wmWidth * ratio;
      wmHeight = wmHeight * ratio;
    } else {
      CGFloat ratio = (100 / wmHeight);
      wmWidth = wmWidth * ratio;
      wmHeight = wmHeight * ratio;
    }
  }
  
  CGFloat wmX = (renderAreaSize.width * self.watermarkPostion.x) - (wmWidth / 2);
  CGFloat wmY = (renderAreaSize.height * self.watermarkPostion.y) + (wmHeight / 2);
  CGRect wmRect = CGRectMake(wmX, wmY, wmWidth, wmHeight);
  
  UIGraphicsBeginImageContext(renderAreaSize);
  [firstImage drawInRect:renderAreaRect];
  [waterMarkImage drawInRect:wmRect blendMode:kCGBlendModeNormal alpha:1.0];
  UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return newImage;
}

- (CVPixelBufferRef) pixelBufferWithCGImage:(CGImage*) image {
  CGSize frameSize = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
  CVPixelBufferRef pixelBufferOutput = nil;
  CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, frameSize.width, frameSize.height, kCVPixelFormatType_32BGRA, nil, &pixelBufferOutput);
  if(status != kCVReturnSuccess) {
    return nil;
  }
  CVPixelBufferLockFlags flags = (CVPixelBufferLockFlags)0;
  
  CVPixelBufferLockBaseAddress(pixelBufferOutput, flags);
  void* data = CVPixelBufferGetBaseAddress(pixelBufferOutput);
  CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
  CGContextRef context = CGBitmapContextCreate(data, frameSize.width, frameSize.height, 8, CVPixelBufferGetBytesPerRow(pixelBufferOutput), rgbColorSpace, bitmapInfo);
  CGContextDrawImage(context, CGRectMake(0, 0, frameSize.width, frameSize.height), image);
  
  CVPixelBufferUnlockBaseAddress(pixelBufferOutput, flags);
  
  CGContextRelease(context);
  CGColorSpaceRelease(rgbColorSpace);
  
  return pixelBufferOutput;
}

- (UIImage*) getCIImageWithFilter:(BOOL)isFiltering pixelBuffer:(CVPixelBufferRef)pixelBuffer filterName:(NSString*)filterName {
  CIImage *cameraImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
  
  if(isFiltering) {
    CIFilter* ciFilter = [CIFilter filterWithName:@"CISepiaTone"];
    [ciFilter setValue:cameraImage forKey:kCIInputImageKey];
    [ciFilter setValue:@(0.8) forKey:kCIInputIntensityKey];
    
    return [UIImage imageWithCIImage:ciFilter.outputImage];
  } else {
    return [UIImage imageWithCIImage:cameraImage scale:1.0 orientation:(UIImageOrientation)self->orientation];
  }
  
}

- (CVPixelBufferRef) getWatermarkWithPixelBufferWithFilter:(BOOL)isFiltering pixelBuffer:(CVPixelBufferRef)pixelBuffer watermarkImage:(UIImage*) watermarkImage {
  @autoreleasepool {
    
    UIImage *filteredImage = [self getCIImageWithFilter:isFiltering  pixelBuffer:pixelBuffer filterName:@""];
    UIImage* mergedImage = [self mergeImage:filteredImage secondImage:watermarkImage];
    if(mergedImage != nil) {
      CGImage *cgImage = mergedImage.CGImage;
      CVPixelBufferRef outputPixelBuffer = [self pixelBufferWithCGImage:cgImage];
      return outputPixelBuffer;
    }
  }
  return pixelBuffer;
  return nil;
}

@end

#define YUV_FRAME_SIZE 2000
#define FRAME_WIDTH
#define NUMBEROFRAMES 300
#define DURATION 12

@implementation H264HwEncoderImpl
{
  VTCompressionSessionRef EncodingSession;
  dispatch_queue_t aQueue;
  CMFormatDescriptionRef  format;
  CMSampleTimingInfo * timingInfo;
  BOOL initialized;
  int  frameCount;
  NSData *sps;
  NSData *pps;
}
@synthesize error;

- (void) initWithConfiguration
{
  EncodingSession = nil;
  initialized = true;
  aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  frameCount = 0;
  sps = NULL;
  pps = NULL;
  
}

void didCompressH264(void *outputCallbackRefCon, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                     CMSampleBufferRef sampleBuffer )
{
  if (status != 0) return;
  if (!CMSampleBufferDataIsReady(sampleBuffer)) {
    return;
  }
  H264HwEncoderImpl* encoder = (__bridge H264HwEncoderImpl*)outputCallbackRefCon;
  CFArrayRef aArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
  CFDictionaryRef aDict = (CFDictionaryRef)CFArrayGetValueAtIndex(aArray, 0);
  bool keyframe = !CFDictionaryContainsKey(aDict, kCMSampleAttachmentKey_NotSync);
  
  
  if (keyframe) {
    CMFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
    
    size_t sparameterSetSize, sparameterSetCount;
    const uint8_t *sparameterSet;
    OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 0, &sparameterSet, &sparameterSetSize, &sparameterSetCount, 0 );
    if (statusCode == noErr) {
      // sps, pps
      size_t pparameterSetSize, pparameterSetCount;
      const uint8_t *pparameterSet;
      OSStatus statusCode = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format, 1, &pparameterSet, &pparameterSetSize, &pparameterSetCount, 0 );
      if (statusCode == noErr) {
        // Found pps
        encoder->sps = [NSData dataWithBytes:sparameterSet length:sparameterSetSize];
        encoder->pps = [NSData dataWithBytes:pparameterSet length:pparameterSetSize];
        if (encoder->_delegate) {
          [encoder->_delegate gotSpsPps:encoder->sps pps:encoder->pps];
        }
      }
    }
  }
  
  CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
  size_t length, totalLength;
  char *dataPointer;
  OSStatus statusCodeRet = CMBlockBufferGetDataPointer(dataBuffer, 0, &length, &totalLength, &dataPointer);
  if (statusCodeRet == noErr) {
    
    size_t bufferOffset = 0;
    static const int AVCCHeaderLength = 4;
    while (bufferOffset < totalLength - AVCCHeaderLength) {
      
      uint32_t NALUnitLength = 0;
      memcpy(&NALUnitLength, dataPointer + bufferOffset, AVCCHeaderLength);
      
      // Big-endian to Little-endian
      NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
      
      NSMutableData* data = [[NSMutableData alloc] initWithBytes:(dataPointer + bufferOffset + AVCCHeaderLength) length:NALUnitLength];
      [encoder->_delegate gotEncodedData:data isKeyFrame:keyframe];
      
      bufferOffset += AVCCHeaderLength + NALUnitLength;
    }
  }
}

- (void) initEncode:(int)width  height:(int)height
{
  dispatch_sync(aQueue, ^{
    
    CFMutableDictionaryRef sessionAttributes =
    CFDictionaryCreateMutable(
                              NULL,
                              0,
                              &kCFTypeDictionaryKeyCallBacks,
                              &kCFTypeDictionaryValueCallBacks);
    // Create the compression session
    OSStatus status = VTCompressionSessionCreate(NULL, width, height, kCMVideoCodecType_H264, sessionAttributes, NULL, NULL, didCompressH264, (__bridge void *)(self),  &EncodingSession);
    
    if (status != 0) {
      error = @"H264: Unable to create a H264 session";
      return;
    }
    
    VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_High_5_2);
    VTSessionSetProperty(EncodingSession, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse);
    
    // Tell the encoder to start encoding
    VTCompressionSessionPrepareToEncodeFrames(EncodingSession);
  });
}

- (void) encode:(CMSampleBufferRef )sampleBuffer
{
  dispatch_sync(aQueue, ^{
    frameCount++;
    // Get the CV Image buffer
    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    // Create properties
    CMTime presentationTimeStamp = CMTimeMake(frameCount, 1);
    //CMTime duration = CMTimeMake(1, DURATION);
    VTEncodeInfoFlags flags;
    // Pass it to the encoder
    OSStatus statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                          imageBuffer,
                                                          presentationTimeStamp,
                                                          kCMTimeInvalid,
                                                          NULL, NULL, &flags);
    // Check for error
    if (statusCode != noErr) {
      error = @"H264: VTCompressionSessionEncodeFrame failed ";
      // End the session
      VTCompressionSessionInvalidate(EncodingSession);
      CFRelease(EncodingSession);
      EncodingSession = NULL;
      error = NULL;
      return;
    }
  });
}

- (void) changeResolution:(int)width  height:(int)height
{
}


- (void) End
{
  // Mark the completion
  VTCompressionSessionCompleteFrames(EncodingSession, kCMTimeInvalid);
  
  // End the session
  VTCompressionSessionInvalidate(EncodingSession);
  CFRelease(EncodingSession);
  EncodingSession = NULL;
  error = NULL;
  
}

@end
