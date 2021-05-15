# Binary-image converter in Assembly MIPS language :camera: :gear:

Program written in the MIPS assembly language which is responsible for converting the BMP 24-bit 320x240 image to the binary (black and white) BMP image based on the input parameters given by the user who has to specify the region in which the pixels will be processed. The region is defined by:
* top-left corner coordinates (x2, y2)
* bottom-right coordinates (x1, y1)
* threshold value

Then, the assembly program is checking every pixel which is represented by the hexadecimal color representaion such as : 0x00RRGGBB where R - red, G - green, B - blue.
The assembly code checks, reffering to the threshold value the inequality defined as follow:
```
	thres >= 0.21R + 0.72G + 0.07B
```
If the inequality is satisfied then the pixel is set to white (0xFFFFFFFF), if not, then the pixel is set to black (0x00000000). The program only process the pixels which are placed in the defined region by the user. The rest of the pixels remain unchanged.

## Overview
![alt text](https://github.com/mikpaszkowski/assembly-binary-image-converter/blob/master/examples/example2.png)
![alt text](https://github.com/mikpaszkowski/assembly-binary-image-converter/blob/master/examples/example3.png)
![alt text](https://github.com/mikpaszkowski/assembly-binary-image-converter/blob/master/examples/example1.png)


## Instalation
1. The Mars4_5 should be downloaded downloaded from https://courses.missouristate.edu/KenVollmar/MARS/download.htm and extracted into the project directory.
2. Through command below extract the Mars4_5 package:
    ``` 
    jar -xf Mars4_5.jar 
    ```
4. Then run the Mars enviroment:
    ```
    java Mars
    ```
6. Through the Mars, open the project "binary_image_project".
7. Then run it.
8. The processed image can be changed at line 39 with these three images in the directory
    or with any other BMP 24-bit 320x240 bitmap image.