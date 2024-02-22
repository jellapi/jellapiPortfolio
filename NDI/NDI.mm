#import "NDI.h"
#import <UIKit/UIKit.h>
#include <csignal>
#include <cstdint>
#include <cstring>
#include <algorithm>
#include <atomic>
#include <thread>
#include <vector>
//#include <python3>
//#include "avcodec.h"
//#include <avformat>

// CoreAudio Public Utility
//#include "CAStreamBasicDescription.h"
//#include "CAComponentDescription.h"
//#include "CAAudioBufferList.h"
//#include "AUOutputBL.h"

#include "NDIDataModel.h"
#include <Processing.NDI.Advanced.h>

void defer2(void (^block)()) {
    static AIDefer* __weak d;
    d = [AIDefer defer:block];
}

@implementation NDI {
    NDIlib_send_instance_t ndiSendInstance;
    BOOL started;
    H264HwEncoderImpl *h264Encoder;
    ImageProcessing *imageProcessing;
    UIImage* __watermarkImage;
  
    size_t extraSize;
    Byte* extraSendData;
    int xres;
    int yres;
}

- (void) setWatermarkImage:(UIImage *)image withPosition:(CGPoint)point {
    __watermarkImage = image;
    imageProcessing.watermarkPostion = point;
    imageProcessing.orientation = UIImageOrientationUp;
}

+ (void)initialize {
    NDIlib_initialize();
}

-(id)init {
  return [self initWithAppID:nil];
}

-(id)initWithAppID:(id)input {
  if (self = [super init]) {
    self->started = false;
    self->__watermarkImage = nil;
    self->imageProcessing = [[ImageProcessing alloc] init];
    self->extraSize = 0;
    self->extraSendData = nil;
    self->xres = 0;
    self->yres = 0;
  }
  return self;
}

- (void) initNdiSender:(NSString*)name clippingAudio:(BOOL)isClippingAudio {
    if (ndiSendInstance) {
        ndiSendInstance = nil;
    }
    started = false;
    
    NDIlib_send_create_t options;
    options.p_ndi_name = [name cStringUsingEncoding: NSUTF8StringEncoding];
    options.p_groups = NULL;
    options.clock_video = false;
    options.clock_audio = isClippingAudio;
    
    ndiSendInstance = NDIlib_send_create(&options);
    if (!ndiSendInstance) {
        NSLog(@"ERROR: Failed to create sender");
    } else {
        NSLog(@"Successfully created sender");
    }
    
}

- (BOOL)isStarted {
    return started;
}

- (void)start:(NSString *)name {
    [self start:name clippingAudio:false];
}

- (void)start:(NSString *)name clippingAudio:(BOOL)isClippingaudio {
    if (!ndiSendInstance) {
        [self initNdiSender:name clippingAudio:isClippingaudio];
    }
    started = true;
    
    h264Encoder = [H264HwEncoderImpl alloc];
    [h264Encoder initWithConfiguration];
    [h264Encoder initEncode:640 height:480];
    h264Encoder.delegate = self;
}


- (void)stop {
    started = false;
}

- (void)removeNDI {
    if (ndiSendInstance) {
        NDIlib_send_destroy(ndiSendInstance);
        ndiSendInstance = nil;
    }
}

- (void)sendVideo:(CVPixelBufferRef)pixelBuffer withOrientation:(int)orientation {
    if (!started)
        return;
	
    CVPixelBufferRef __pixelBuffer = nil;
    imageProcessing.orientation = orientation;
    if (__watermarkImage != nil) {
        __pixelBuffer = [imageProcessing getWatermarkWithPixelBufferWithFilter:NO pixelBuffer:pixelBuffer watermarkImage:__watermarkImage];
    } else {
        __pixelBuffer = pixelBuffer;
    }
    OSType format = CVPixelBufferGetPixelFormatType(__pixelBuffer);
    if(format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ||
       format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        [self sendVideoYUV:__pixelBuffer];
    } else if(format == kCVPixelFormatType_32BGRA) {
        [self sendVideo32BGRA:__pixelBuffer];
    } else {
        assert(0);
    }
    if (__watermarkImage != nil) {
        defer2(^{
            CVPixelBufferRelease(__pixelBuffer);
        });
    }
}

- (void)sendVideo32BGRA:(CVPixelBufferRef)pixelBuffer {
    if (!ndiSendInstance) {
        return;
    }
    if (!started)
        return;
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
	float ratio = 0;
	if(width > height) {
		ratio = (float)width / (float)height;
	} else {
		ratio = (float)height / (float)width;
	}
	NDIlib_video_frame_v2_t video_frame;
	video_frame.frame_rate_N = 24000;
	video_frame.frame_rate_D = 1001;
	video_frame.FourCC = NDIlib_FourCC_type_BGRA;
	video_frame.frame_format_type = NDIlib_frame_format_type_progressive;
	video_frame.p_metadata = NULL;
	video_frame.xres = width;
	video_frame.yres = height;
	video_frame.picture_aspect_ratio = ratio;
	CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	video_frame.p_data = (uint8_t*) CVPixelBufferGetBaseAddress(pixelBuffer);
	CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
	NDIlib_send_send_video_v2(self->ndiSendInstance, &video_frame);
}

- (void)sendVideoYUV:(CVPixelBufferRef)pixelBuffer {
    if (!started)
        return;
    if (!ndiSendInstance) {
        return;
    }
    CVPixelBufferRef convertedBuffer = [imageProcessing toBGRA:pixelBuffer];
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	int width = (int)CVPixelBufferGetWidth(convertedBuffer);
	int height = (int)CVPixelBufferGetHeight(convertedBuffer);
	float ratio = 0;
	if(width > height) {
		ratio = (float)width / (float)height;
	} else {
		ratio = (float)height / (float)width;
	}
	NDIlib_video_frame_v2_t video_frame;
	video_frame.frame_rate_N = 24000;
	video_frame.frame_rate_D = 1001;
	video_frame.FourCC = NDIlib_FourCC_type_BGRA;
	video_frame.frame_format_type = NDIlib_frame_format_type_progressive;
	video_frame.p_metadata = NULL;
	video_frame.xres = width;
	video_frame.yres = height;
	video_frame.picture_aspect_ratio = ratio;
	CVPixelBufferLockBaseAddress(convertedBuffer, kCVPixelBufferLock_ReadOnly);
	video_frame.p_data = (uint8_t*) CVPixelBufferGetBaseAddress(convertedBuffer);
	CVPixelBufferUnlockBaseAddress(convertedBuffer, kCVPixelBufferLock_ReadOnly);
	NDIlib_send_send_video_v2(self->ndiSendInstance, &video_frame);
	free((void*) video_frame.p_data);
}

// PCM32
- (void)sendAudio:(CMSampleBufferRef)sampleBuffer {
    if (!started)
        return;
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    if (blockBuffer == NULL) {
        return;
    }
    size_t length = CMBlockBufferGetDataLength(blockBuffer);
    uint8_t samples[length];
    CMBlockBufferCopyDataBytes(blockBuffer, 0, length, samples);
    
    long double numSamples = CMSampleBufferGetNumSamples(sampleBuffer);
    CMAudioFormatDescriptionRef format = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *desc = CMAudioFormatDescriptionGetStreamBasicDescription(format);
        
    float *convertedSamples = (float*)malloc(numSamples * sizeof(float));
    
    if (desc->mChannelsPerFrame == 1 && desc->mBitsPerChannel == 16) {
        vDSP_vflt16((short *)samples, 1, convertedSamples, 1, numSamples);
        float div = 32768.0;
        vDSP_vsdiv(convertedSamples, 1, &div, convertedSamples, 1, numSamples);
    } else {
        NSLog(@"not channelsPerFrame 1, bitsPerChannel 16");
    }
    
    NDIlib_audio_frame_v3_t audio_frame_data;
    audio_frame_data.sample_rate = desc->mSampleRate;
    audio_frame_data.no_channels = desc->mChannelsPerFrame;
    audio_frame_data.no_samples = numSamples;
    audio_frame_data.channel_stride_in_bytes = numSamples * sizeof(uint8_t);
    audio_frame_data.p_metadata = NULL;
    audio_frame_data.p_data = (uint8_t*) convertedSamples;
    NDIlib_send_send_audio_v3(self->ndiSendInstance, &audio_frame_data);
    
    defer2(^() {
        free(convertedSamples);
    });
    
}

- (void)gotEncodedData:(NSMutableData *)data isKeyFrame:(BOOL)isKeyFrame {
  
    const char bytes[] = "\x00\x00\x00\x01";
    size_t headerLength = (sizeof bytes) - 1;
    size_t totalSize = headerLength + [data length];
    Byte* sendData = (Byte*) malloc(totalSize);
    memcpy(sendData, bytes, headerLength);
    memcpy(sendData + headerLength, data.bytes, [data length]);
  
    [self sendNDIAdv:sendData length:totalSize isKeyFrame:isKeyFrame xres:self->xres yres:self->yres];
}

- (void)gotSpsPps:(NSData *)sps pps:(NSData *)pps {
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    size_t spsSize = [sps length];
    size_t ppsSize = [pps length];
  
    extraSize = sizeof(Byte) * length * 2 + spsSize + ppsSize;
    extraSendData = (Byte*)malloc(extraSize);
  
    memcpy(extraSendData, bytes, length);
    memcpy(extraSendData+length, sps.bytes, spsSize);
    memcpy(extraSendData+length+spsSize, bytes, length);
    memcpy(extraSendData+length*2+spsSize, pps.bytes, ppsSize);
}

- (void) sendVideoAdv:(CMSampleBufferRef)sampleBuffer  {
  
  if (!ndiSendInstance) return;
  [h264Encoder encode:sampleBuffer];
  
  CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
  xres = (int)CVPixelBufferGetWidth(imageBuffer);
  yres = (int)CVPixelBufferGetHeight(imageBuffer);
  return;
}

// for android
- (void)setExtraData:(Byte *)data length:(size_t)length {
  extraSize = length;
  extraSendData = (Byte*)malloc(extraSize);
  memcpy(extraSendData, data, extraSize);
}

// for android
- (void)setResolution:(int)xres yres:(int)yres {
  self->xres = xres;
  self->yres = yres;
}

struct video_send_data
{
    NDIlib_compressed_packet_t packet;
    NDIlib_video_frame_v2_t    frame;
    std::vector<uint8_t*>      scatter_data;
    std::vector<int>           scatter_data_size;
};

- (void)sendNDIAdv:(Byte *)frameData length:(size_t)frameLength isKeyFrame:(BOOL)isKeyFrame xres:(int)xres yres:(int)yres {
  
  static int64_t framecount = 1;
  
  NDIlib_video_frame_v2_t frameInfo;
  frameInfo.FourCC               = (NDIlib_FourCC_video_type_e)NDIlib_FourCC_video_type_ex_H264_highest_bandwidth;
  frameInfo.xres                 = xres;
  frameInfo.yres                 = yres;
  frameInfo.p_data               = nullptr;
  frameInfo.data_size_in_bytes   = 0;
  frameInfo.frame_rate_N         = 30000;
  frameInfo.frame_rate_D         = 1001;
  frameInfo.frame_format_type    = NDIlib_frame_format_type_progressive;
  frameInfo.picture_aspect_ratio = yres / xres;
  frameInfo.timecode         = framecount * 1000;
            
  NDIlib_compressed_packet_t packet;
  packet.version         = sizeof(NDIlib_compressed_packet_t);
  packet.pts             = framecount * 1000;  // "pts"
  packet.dts             = framecount * 1000;  // "dts"
  packet.flags           = isKeyFrame ? NDIlib_compressed_packet_t::flags_keyframe : NDIlib_compressed_packet_t::flags_none;
  packet.data_size       = (uint32_t)frameLength;
  packet.extra_data_size = (uint32_t)extraSize;
  packet.fourCC          = NDIlib_compressed_FourCC_type_H264;

  
  std::vector<uint8_t*>      scatter_data;
  std::vector<int>           scatter_data_size;
  
  scatter_data.clear();
  scatter_data_size.clear();
  
  scatter_data.push_back((uint8_t*)&packet);
  scatter_data_size.push_back((int)sizeof(NDIlib_compressed_packet_t));
  
  scatter_data.push_back((uint8_t*)frameData);
  scatter_data_size.push_back((int)frameLength);

  if (extraSize != 0) {
      scatter_data.push_back((uint8_t*)extraSendData);
      scatter_data_size.push_back((int)extraSize);
  }

  scatter_data.push_back(nullptr);
  scatter_data_size.push_back(0);
  
  NDIlib_frame_scatter_t frameScatter;
  frameScatter.p_data_blocks = scatter_data.data();
  frameScatter.p_data_blocks_size = scatter_data_size.data();

  NDIlib_send_send_video_scatter(ndiSendInstance, &frameInfo, &frameScatter);

  if (extraSize != 0) {
      free(extraSendData);
      extraSendData = nil;
      extraSize = 0;
  }
  framecount++;
}

// Basic audio frame structure for the pre-compressed AAC frames
struct audio_frame
{
    const uint8_t* p_data;
    const uint8_t* p_extra;
    int64_t  dts;
    int64_t  pts;
    uint32_t data_size;
    uint32_t extra_size;
};

// Include the AAC test data
namespace aac {
#include "aac.h"
}
static std::atomic<bool> exit_loop(false);
static void sigint_handler(int) {
    exit_loop = true;
}


void send_aac_audio(NDIlib_send_instance_t pNDI_send)
{
    const int num_frames = aac::num_audio_frames;

    NDIlib_compressed_packet_t packet = { };
    packet.version = sizeof(NDIlib_compressed_packet_t);
    packet.fourCC  = NDIlib_compressed_FourCC_type_AAC;
    packet.flags   = NDIlib_compressed_packet_t::flags_keyframe;

    NDIlib_audio_frame_v3_t dst_frame = { };
    dst_frame.sample_rate = aac::audio_sample_rate;
    dst_frame.no_channels = aac::audio_num_channels;
    dst_frame.no_samples  = aac::audio_num_samples;
    dst_frame.FourCC      = (NDIlib_FourCC_audio_type_e)NDIlib_FourCC_audio_type_ex_AAC;

    std::vector<uint8_t*> scatter_data;
    std::vector<int>      scatter_data_size;

    for (int frame_num = 0; !exit_loop; frame_num = (frame_num + 1) % num_frames)
    {   
      const audio_frame& src_frame = aac::audio_frames[frame_num];

        dst_frame.timecode = src_frame.dts;

        packet.pts             = src_frame.pts;
        packet.dts             = src_frame.dts;
        packet.data_size       = src_frame.data_size;
        packet.extra_data_size = src_frame.extra_size;

        scatter_data.clear();
        scatter_data_size.clear();

        scatter_data.push_back((uint8_t*)&packet);
        scatter_data_size.push_back((int)sizeof(NDIlib_compressed_packet_t));

        scatter_data.push_back((uint8_t*)src_frame.p_data);
        scatter_data_size.push_back((int)src_frame.data_size);

        if (src_frame.extra_size != 0)
        {    scatter_data.push_back((uint8_t*)src_frame.p_extra);
            scatter_data_size.push_back((int)src_frame.extra_size);
        }

        scatter_data.push_back(nullptr);
        scatter_data_size.push_back(0);

        NDIlib_frame_scatter_t frame_scatter = { scatter_data.data(), scatter_data_size.data() };

        NDIlib_send_send_audio_scatter(pNDI_send, &dst_frame, &frame_scatter);
    }
}


@end


