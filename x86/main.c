// graf_io.c : Defines the entry point for the console application.
//

#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#define BYTES_FOR_SINGLE_PIXEL 3
#define MAX_THRESHOLD_VALUE 255
#define DESIRED_COMPRESSION_VALUE 0
#define BYTE_PER_PIXEL 24
#define NUMBER_OF_HEADERS 1
#define BMP_SIZE_WITHOUT_HEADER 230454
#define HEIGHT_BMP 240
#define WIDTH_BMP 320

const int BMP_SIGNATURE = 0x4D42;
const char READ_AND_BINARY_MODE[] = "rb"; // open file to read and binary mode
const char WRITE_AND_BINARY_MODE[] = "wb"; // open file to write and binary mode
const char SOURCE_IMAGE_NAME[] = "source1.bmp";
const char DESTINATION_IMAGE_NAME[] = "binary_image.bmp";
const int WHITE_HEX = 0x00FFFFFF;
const int BLACK_HEX = 0x00000000;
const char WRONG_BMP_HEADER_SIZE_MESSAGE[] = "Check compilation options so as bmpHeaderInfo struct size is 54 bytes.\n";
const char WARNING_EXPLANATION_OF_INPUTS[] = "Be careful with coordinates you enter. \nThe following points (x, y) you enter will be RIGHT BOTTOM corner and the TOP LEFT corner between \nwhose will be created rectangle from the right to left. \nIt means that you cannot enter coordinates of RIGHT BOTTOM corner what in result will place \nthe point on the left side or under if TOP LEFT corner.\n";
const char ERROR_FILE_OPENING[] = "\nOpening the file failure. Check the name of the file.";
const char ERROR_FILE_READING[] = "\nReading from file failure.";
const char ERROR_FILE_WRITING[] = "\nWriting to the file failure.";
const char ERROR_FILE_WIDTH[] = "\nWidht of the file should be 320 pixels.";
const char ERROR_FILE_HEIGHT[] = "\nHeight of the file should be 240 pixels.";
const char BOTTOM_RIGH_INPUT_MSG_X[] = "\nEnter the x coordinate of BOTTOM RIGHT corner.\n";
const char BOTTOM_RIGH_INPUT_MSG_Y[] = "\nEnter the y coordinate of BOTTOM RIGHT corner.\n";
const char TOP_LEFT_MSG_X[] = "\nEnter the x coordinate of TOP LEFT corner.\n";
const char TOP_LEFT_MSG_Y[] = "\nEnter the y coordinate of TOP LEFT corner.\n";
const char THRESHOLD_INPUT_MSG[] = "\nEnter the threshold value from 0-255\n";
const char ERROR_COORDINATES[] = "\nCoordinates x or y are incorrect.\n";
const char ERROR_THRESHOLD[] = "\nThreshold value is incorrect.\n";
const char ERROR_FILE_FORMAT[] = "\nInput file should be a BMP format.";
const char ERROR_WRONG_X_COORDINATES[] = "\nX of right corner cannot be smaller than X of left corner.";
const char ERROR_WRONG_Y_COORDINATES[] = "\nY cannot be smaller than x1.";
const char CHECKING_FILE_MSG[] = "\nProcessing the file ...";
const char PROCESSING_MSG[] = "\nProcessing ...";
const char ERROR_BMP_FILESIZE[] = "\nBMP file's size should be 230454 bytes";
const char ERROR_WRONG_BMP_TYPE[] = "\nWrong file type. It should be 24-bit BMP file.";
const char ERROR_WRONG_COMPRESSION[] = "\nBMP compression should be equal to 0.";

#pragma pack(push, 1)

typedef struct
{
    unsigned short bytesImageType;	// 0x4D42
    unsigned long  bytesFileSize;	// file size in bytes
    unsigned short bfReserved1;
    unsigned short bfReserved2;
    unsigned long  bytesPixelDataOffset;	// offset of pixel data
    unsigned long  bytesHeaderSize;		// header size (bitmap info size)
    long  bytesImageWidth;			// image width
    long  bytesImageHeight;			// image height
    short bytesBitmapPlanes;			// bitmap planes (== 3)
    short bytesPixelBitCount;		// bit count of a pixel (== 24)
    unsigned long  bytesImageCompression;	// should be 0 (no compression)
    unsigned long  bytesImageSize;		// image size (not file size!)
    long bytesHorizontalRes;			// horizontal resolution
    long bytesVerticalRes;			// vertical resolution
    unsigned long  bytesColorUsed;		// not important for RGB images
    unsigned long  bytesColorsImportant;	// not important for RGB images
} BMPHeaderInfo;

#pragma pack(pop)

typedef struct
{
    unsigned int width, height;
    unsigned int bytesPerRow;
    unsigned char* pImg;
    BMPHeaderInfo *pHeaderInfo;
} imageInfo;

imageInfo* allocImgInfo()
{
    imageInfo* retv = malloc(sizeof(imageInfo));
    if (retv != NULL)
    {
        retv->width = 0;
        retv->height = 0;
        retv->bytesPerRow = 0;
        retv->pImg = NULL;
        retv->pHeaderInfo = NULL;
    }
    return retv;
}

void* freeImgInfo(imageInfo* toFree)
{
    if (toFree != NULL)
    {
        if (toFree->pImg != NULL)
            free(toFree->pImg);
        if (toFree->pHeaderInfo != NULL)
            free(toFree->pHeaderInfo);
        free(toFree);
    }
    return NULL;
}

void* freeResources(FILE* pFile, imageInfo* toFree)
{
    if (pFile != NULL)
        fclose(pFile);
    return freeImgInfo(toFree);
}

int isBMPFileCorrect(imageInfo* pInfo){

    if(pInfo->pHeaderInfo->bytesImageHeight != HEIGHT_BMP){
        printf(ERROR_FILE_HEIGHT);
        return 0;
    }
    if(pInfo->pHeaderInfo->bytesImageWidth != WIDTH_BMP){
        printf(ERROR_FILE_WIDTH);
        return 0;
    }

    if(pInfo->pHeaderInfo->bytesFileSize != BMP_SIZE_WITHOUT_HEADER){
        printf(ERROR_BMP_FILESIZE);
        return 0;
    }

    if(pInfo->pHeaderInfo->bytesImageType != BMP_SIGNATURE){
        printf(ERROR_WRONG_BMP_TYPE);
        return 0;
    }

    if(pInfo->pHeaderInfo->bytesPixelBitCount != BYTE_PER_PIXEL){
        printf(ERROR_WRONG_BMP_TYPE);
        return 0;
    }

    if(pInfo->pHeaderInfo->bytesImageCompression != DESIRED_COMPRESSION_VALUE){
        printf(ERROR_WRONG_COMPRESSION);
        return 0;
    }

    if(pInfo->pHeaderInfo->bytesBitmapPlanes != NUMBER_OF_HEADERS){
        printf(ERROR_WRONG_BMP_TYPE);
        return 0;
    }
    return 1;
}

imageInfo* readBMP(const char* fname)
{
    imageInfo* pInfo = 0;
    FILE* fbmp = 0;

    if ((pInfo = allocImgInfo()) == NULL)
        return NULL;

    if ((fbmp = fopen(fname, READ_AND_BINARY_MODE)) == NULL){
        printf(ERROR_FILE_OPENING);
        return freeResources(fbmp, pInfo);  // cannot open file
    }

    if ((pInfo->pHeaderInfo = malloc(sizeof(BMPHeaderInfo))) == NULL ||
        fread((void *)pInfo->pHeaderInfo, sizeof(BMPHeaderInfo), 1, fbmp) != 1){
        printf(ERROR_FILE_READING);
        return freeResources(fbmp, pInfo);
    }

    if (!isBMPFileCorrect(pInfo)){
        return (imageInfo*) freeResources(fbmp, pInfo);
    }

    if ((pInfo->pImg = malloc(pInfo->pHeaderInfo->bytesImageSize)) == NULL ||
        fread((void *)pInfo->pImg, 1, pInfo->pHeaderInfo->bytesImageSize, fbmp) != pInfo->pHeaderInfo->bytesImageSize){
        printf(ERROR_FILE_READING);
        return (imageInfo*) freeResources(fbmp, pInfo);
    }

    fclose(fbmp);
    pInfo->width = pInfo->pHeaderInfo->bytesImageWidth;
    pInfo->height = pInfo->pHeaderInfo->bytesImageHeight;
    pInfo->bytesPerRow = pInfo->pHeaderInfo->bytesImageSize / pInfo->pHeaderInfo->bytesImageHeight;
    return pInfo;
}

int saveBMP(const imageInfo* pInfo, const char* fname)
{
    FILE * fbmp;
    if ((fbmp = fopen(fname, WRITE_AND_BINARY_MODE)) == NULL){
        printf(ERROR_FILE_OPENING);
        return 0;
    }

    if (fwrite(pInfo->pHeaderInfo, sizeof(BMPHeaderInfo), 1, fbmp) != 1 ||
        fwrite(pInfo->pImg, 1, pInfo->pHeaderInfo->bytesImageSize, fbmp) != pInfo->pHeaderInfo->bytesImageSize)
    {
        printf(ERROR_FILE_WRITING);
        fclose(fbmp);  // cannot write header or image
        return 0;
    }

    fclose(fbmp);
    return 0;
}

extern unsigned int generateRecByThresh(imageInfo* pImg, unsigned int top_left_x, unsigned int top_left_y, unsigned int bottom_right_x, unsigned int bottom_right_y, unsigned int thresh);

//function responsible for binary processing of the given rectangle - only C
unsigned int thresholdRec(imageInfo* pImg, unsigned int x, unsigned int y, unsigned int thresh)
{
    char R, G, B;
    unsigned char *pPix = pImg->pImg + pImg->bytesPerRow * y + x * BYTES_FOR_SINGLE_PIXEL;

    R = *pPix;
    G = *(pPix+1);
    B = *(pPix+2);

    unsigned int color = (R * 21 + G * 72 + B * 7 > thresh * 100) ? BLACK_HEX : WHITE_HEX;

    *pPix = (color >> 16) & 0xFF; // R color of the pixel
    *(pPix + 1) = (color >> 8) & 0xFF; // G color of the pixel
    *(pPix + 2) =  color & 0xFF; // B color of the pixel
    return 1;
}

typedef struct {
    unsigned int x;
    unsigned  int y;
} topLeftCorner;

typedef struct {
    unsigned int x;
    unsigned  int y;
} bottomRightCorner;

void checkCoordinates(imageInfo *pInfo, unsigned int x, unsigned int y){
    if(x > pInfo->width || x < 0){
        printf(ERROR_COORDINATES);
        exit(0);
    }
    if(y > pInfo->height || y < 0){
        printf(ERROR_COORDINATES);
        exit(0);
    }
}

void checkCoordinatesOfRec(imageInfo *pInfo, unsigned int left_x, unsigned int left_y, unsigned int right_x, unsigned int right_y){
    if(right_x < left_x){
        printf(ERROR_WRONG_X_COORDINATES);
    }

    if(left_y < right_y){
        printf(ERROR_WRONG_Y_COORDINATES);
    }
}

int main(int argc, char* argv[])
{
    imageInfo* pInfo;
    unsigned int col_idx;
    unsigned int row_idx;
    unsigned int threshold = 0;

    topLeftCorner leftCorner;
    bottomRightCorner rightCorner;

    if ((pInfo = readBMP(SOURCE_IMAGE_NAME)) == NULL)
    {
        printf(ERROR_FILE_READING);
        return 2;
    }
    //warning message
    printf("\n**************************************************************************************************\n\n");
    printf(WARNING_EXPLANATION_OF_INPUTS);
    printf("\n**************************************************************************************************\n");

    printf(TOP_LEFT_MSG_X);
    scanf("%d", &leftCorner.x);
    printf(TOP_LEFT_MSG_Y);
    scanf("%d", &leftCorner.y);

    checkCoordinates(pInfo, leftCorner.x, leftCorner.y);

    printf(BOTTOM_RIGH_INPUT_MSG_X);
    scanf("%d", &rightCorner.x);
    printf(BOTTOM_RIGH_INPUT_MSG_Y);
    scanf("%d", &rightCorner.y);

    checkCoordinates(pInfo, rightCorner.x, rightCorner.y);
    checkCoordinatesOfRec(pInfo, leftCorner.x, leftCorner.y, rightCorner.x, rightCorner.y);

    printf(THRESHOLD_INPUT_MSG);
    scanf("%d", &threshold);

    if(threshold < 0 || threshold > MAX_THRESHOLD_VALUE){
        printf(ERROR_THRESHOLD);
        return 0;
    }

     generateRecByThresh(pInfo, leftCorner.x, leftCorner.y, rightCorner.x, rightCorner.y, threshold);

    saveBMP(pInfo, DESTINATION_IMAGE_NAME);
    freeResources(NULL, pInfo);
    return 0;
}
