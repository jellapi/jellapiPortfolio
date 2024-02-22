//
//  NDIDataModel.h
//  NDI
//
//  Created by Jellapi on 2022/03/17.
//

#ifndef NDIDataModel_h
#define NDIDataModel_h



typedef struct _VImage {
    size_t width;
    size_t height;
    size_t bytesPerRow;
    vImage_Buffer buffer;
}VImage;



#endif /* NDIDataModel_h */
