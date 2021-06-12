;=====================================================================
; ECOAR x86 - set column of the RGB image to given color
;			  one pixel in the black and white image
;=====================================================================

;	typedef struct
;	{
;		unsigned int width, height;
;		unsigned int bytesPerRow;
;		unsigned char* pImg;
;		BMPHeaderInfo *pHeaderInfo;
;	} imageInfo;

; imageInfo structure layout

img_width		EQU 0
img_height		EQU 4
img_linebytes	EQU 8
img_pImg		EQU	12
img_RGBbmpHdr	EQU 16 ; not really used
red_constant    EQU 21
blue_constant   EQU 7
green_constant  EQU 72


;============================================
; STACK	layout (thanks to Zbigniew Szymanski)
;============================================
;
; greater addresses
;
;  |                                |
;  | ...                            |
;  ----------------------------------
;  | fa - uint color                | EBP+16
;  ----------------------------------
;  | fa - uint col_idx              | EBP+12
;  ----------------------------------
;  | function argument - imageInfo *im| EBP+8
;  ----------------------------------
;  | return address                 | EBP+4
;  ----------------------------------
;  | saved ebp value                | EBP, ESP
;  ----------------------------------
;  | ... local variables            | EBP-x
;  |                                |
;
; \/                               \/
; \/ stack is growing in this      \/
; \/                direction      \/
;
; lower addresses
;
;
;============================================

;img_width		EQU 0
;img_height		EQU 4
;img_linebytes	EQU 8
;img_pImg		EQU	12
;img_RGBbmpHdr	EQU 16 ; not really used
;red_constant    EQU 21
;blue_constant   EQU 7
;green_constant  EQU 72

;[ebp + 8]  - imageInfo
;[ebp + 12]  - top_left_x
;[ebp + 16]  - top_left_y
;[ebp + 20]  - bottom_right_x
;[ebp + 24]  - bottom_right_y
;[ebp + 28]  - threshold

section	.text
global  generateRecByThresh

generateRecByThresh:
    ;prolog
	push ebp
	mov	ebp, esp

	mov	eax, [ebp + 8]	        ; eax <- address of imageInfo struct
    mov edi, [eax + img_pImg]   ;edi <- address of pImg bitmap
	mov ecx, [ebp + 12]	        ; ecx <- x coordinate of TOP LEFT CORNER - beginning
	mov esi, ecx                ;
	mov ebx, [ebp + 24]         ;storing the bottom_right_y in ebx register

next_col:
	lea ecx, [2 * esi + esi]	    ; ecx *= 3
	mov edx, [eax + img_linebytes]  ;storing in edx the address of bytesPerRow
	imul edx, ebx                   ;mulitplying the bytesPerRow by the bottom_right_y
	add ecx, edx                    ;ecx => x * 3 + y * bytesPerRow
	add edi, ecx                    ;edi => offset + x * 3 + y * bytesPerRow
   ;xor ebx, ebx                    ;clearing the ebxregister - y not needed any more

summing:
    ;computing B * 21
    xor eax, eax
    xor ecx, ecx              ;clearing the ecx regisster
    mov ch, BYTE[edi + 2]   ;storing one byte BB from 0x00RRGGBB
    shr ecx, 8              ;shifting 0xBB00 8 bits to the right to obtain 0xBB
    mov eax, ecx            ;storing the B color in register ebx
    imul eax, blue_constant ;ebx contain one B color which might be multiplaied by 21

    ;computing G * 72
    xor ecx, ecx              ;clearing the ecx regisster
    mov ch, BYTE[edi + 1]   ;storing one byte GG from 0x00RRGGBB
    shr ecx, 8              ;shifting the 0xGGXX 8 bits to the right to obtain 0xGG
    imul ecx, green_constant ;multiplying the G color by 72
    add eax, ecx            ;adding the G * 72 to the register ebx -> B * 21 + G * 72

    ;computing R * 21
    xor ecx, ecx              ;clearing the ecx regisster
    mov ch, BYTE[edi]       ;storing one byte RR from 0x00RRGGBB
    shr ecx, 8              ;shifting the 0xRRXX 8 bits to the right to obtain 0xRR
    imul ecx, red_constant  ;multiplying the R color by 21
    add eax, ecx            ;;summing all the coefficients B * 21 + G * 72 + R * 21 => ebx

    xor ecx, ecx              ;clearing the ecx register
    mov ecx, [ebp + 28]     ;loading the threshold value
    imul ecx, 100           ;multiplying the threshol value by 100 to omit the usage
                            ;of float numbers in coefficients

check_inequality:
    cmp ecx, eax            ;using cmp instruction for compraison of ecx - minuend and ebx - subtrahend
    jge paint_to_white      ;in the case that ecx - minuend is bigger or equal than ebx - subtrahend
                            ;then is performed jump to paint_to_white function
    mov BYTE[edi], 0x00     ;setting the last byte of color to 0x00
    mov BYTE[edi + 1], 0x00 ;setting the middle byte of color to 0x00 => 0x0000
    mov BYTE[edi + 2], 0x00 ;storing 0x00 in the first byte of color of register => 0x000000
    jmp next_pixel          ;unconditional jump to next_pixel instruction

paint_to_white:

    mov BYTE[edi], 0xFF     ;analogically the same as in lines 164 - 169 but for white color 0x00FFFFFF
    mov BYTE[edi + 1], 0xFF
    mov BYTE[edi + 2], 0xFF
    jmp next_pixel


next_pixel:
    xor ecx, ecx                ;clearing register ecx
    xor eax, eax                ;clearing register ecx
    mov	eax, [ebp + 8]	        ; eax <- address of imageInfo struct
    mov edi, [eax + img_pImg]   ;edi <- address of pImg bitmap

    add esi, 1                  ;incrementing the x value x+= 1
    mov ecx, esi                ;storing the x in the register ecx
    cmp esi, [ebp + 20]         ;usage of cmp instruction for comparison x with the right_bottom_x
    jne next_col                ;if the values from cmp are not equal then loop is continuing
    jmp next_row

next_row:
    xor esi, esi                ;clearing the register esi
    mov esi, [ebp + 12]         ;storing in the esi the x - beginning of the iteration/rectangular
    add ebx, 1
    cmp ebx, [ebp + 16]
    jg finish
    jmp next_col


finish:

    mov eax, [edi]              ;storing the color from edi register to eax
    and eax, 0x00FFFFFF         ;usage of the mask 0x00FFFFFF to return the proper format of hex color

	pop	ebp                     ;return of the pointer to the frame
	ret                         ;return to the trace