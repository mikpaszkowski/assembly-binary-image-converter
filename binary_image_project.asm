# -------------------------------------------------------
#author: Paszkowski Miko³aj
#date: 11.05.2021
#project: MIPS Binary Image project
#--------------------------------------------------------


#this project will only supports 24-bit RGB 320x240 pixels BMP files
.eqv BMP_MAX_FILE_SIZE 230454
.eqv BMP_BYTES_PER_ROW 960
.eqv pHeader 0
.eqv fileSize 4
.eqv pImg 8
.eqv width 12
.eqv height 16
.eqv linesbytes 20

.eqv	bi_typeOfFile 0
.eqv	bi_imgoffset  10
.eqv	bi_imgwidth   18
.eqv	bi_imgheight  22
.eqv 	thres 118
.data


	.data
#this project will only supports 24-bit RGB 320x240 pixels BMP files
.align 4
descriptor:	.word	0, 0, 0, 0, 0, 0, 0, 0, 0
r_const: .word 21
g_const: .word 72
b_const: .word 7
max_width: .word 320
max_height: .word 240
max_thres: .word 255
res:	.space 2
imageBuff:	.space BMP_MAX_FILE_SIZE

file_name: .asciiz "image1.bmp"
output_filename: .asciiz "binary_image.bmp"
error_file_opening: .asciiz "\nOpening the file failure. Check the name of the file."
error_file_reading: .asciiz "\nReading from file failure."
error_file_writing: .asciiz "\nWriting to the file failure."
error_file_width: .asciiz "\nWidht of the file should be 320 pixels."
error_file_height: .asciiz "\nHeight of the file should be 240 pixels."
first_input_msg: .asciiz "\nEnter the x1, y1 coordinates\n"
second_input_msg: .asciiz "\nEnter the x2, y2 coordinates\n"
threshold_input_msg: .asciiz "\nEnter the threshold value from 0-255\n"
error_first_input: .asciiz "\nCoordinates x1 or y1 are incorrect.\n"
error_second_input: .asciiz "\nCoordinates x2 or y2 are incorrect.\n"
error_threshold: .asciiz "\nThreshold value is incorrect.\n"
error_file_format: .asciiz "\nInput file should be a BMP format."
error_x2_less_than_x1: .asciiz "\nx2 cannot be smaller than x1."
checking_file_msg: .asciiz "\nProcessing the file ..."
processing_msg: .asciiz "\nProcessing ..."

	.text
main:
	la $a0, file_name
	la $a1, descriptor
	la $t8, imageBuff
	sw $t8, pHeader($a1)
	li $t8, BMP_MAX_FILE_SIZE
	sw $t8, fileSize($a1)
	
#display the message about the processing the file
	li $v0, 4
	la $a0, checking_file_msg
	syscall
	
	jal	read_and_check_bmp 			#opening and reading the file BMP
readings_of_x1_y1:
	jal	reading_top_left_corner_coordinate 	#reading the coordinates of point (x1,y1)
readings_of_x2_y2:
	jal	reading_bottom_right_corner_coordinates #reading the coorindanets of point (x2,y2)
reading_of_threshold:
	jal	reading_threshold_value			#reading the threshold integer from keyboard
	jal 	checking_the_correctness_of_points
	# $s0 -> x1, $s4 -> y1	
	# $s2 -> x2, $s3 -> y2
	# $s5 -> thres
	
#display the message about the processing
	li $v0, 4
	la $a0, processing_msg
	syscall
	
next_row_check:
	ble 	$s4, $s3, next2		#checking whether the processed relative numbers of rows (height) is done
	move	$s0, $k0		#moving the initial value of x1 to begin the next line from the same point
	
main_loop:
	bgt $s0, $s2, next_row_1  #checking of the processed length of the line has reached the x2 - the end of the line
	move 	$a0, $s0	  #passing the x - coordinate of current pixel to the get_pixel function
	move	$a1, $s3	  #passing the y - coordinate of current pixel to the get_pixel function
	jal	get_pixel
	jal	check_inequality
	addi	$s0, $s0, 1	#increasing the value of x1 -> jumping to the next pixel
	j 	main_loop

next_row_1:
	addi	$s3, $s3, 1	#increasing the value of y2 -> jumping to the next line
	j 	next_row_check

next2:
	la $a0, output_filename
	la $a1, descriptor
	jal	save_bmp	#if the processed number of lines has reached the end then the data is saved to the BMP file

exit:	li 	$v0,10		#terminaiting the program
	syscall

#------------------------------- Reading the file---------------------------------
read_and_check_bmp :
	#arguments:
	# $a0 - file name 
	# $a1 - file descriptor
	#	pHeader - contains pointer to file buffer
	#	fileSize - maximum file size allowed
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
#open file
	move $t8, $a1
	li $v0, 13		#using the syscall 13 instruction for opening the file
        la $a0, file_name	#loading file_name address to $a0 
        li $a1, 0		#flags: 0-read file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
 #checking the errors -> i.e. $v0 < 0
        bltz $v0, throw_opening_file_error	#checking if the $s1 is smaller than 0, i.e. 0xFFFFFFFF
						#if it is true then the error message should be printed
#read file
	move $a0, $s1			#moving the file descriptor to $a0
	lw $a1, pHeader($t8)		#loading the address of image buffer
	lw $a2, fileSize($t8)	#loading the image BMP size
	li $v0, 14			#using the syscall 14 instruction for reading the file
	syscall
	
	#checking the errors -> i.e. $v0 < 0
        bltz $v0, throw_reading_file_error	#checking if the $s1 is smaller than 0, i.e. 0xFFFFFFFF
						#if it is true then the error message should be printed

#-------------------CHECKING THE FILE ----------------------
	lw $a1, pHeader($t8)			#loading the word of the header into $a1
	lhu $t9, bi_typeOfFile($a1)		#loading the type of file address in $t9
	#checking if the file is BMP format
	bne $t9, 0x00004D42, throw_file_format_error	
	lhu $t9, bi_imgwidth($a1)
	lw $t0, max_width	#loading the max_width value of the BMP file
	bne $t9, $t0, throw_file_width_error
	lhu $t9, bi_imgheight($a1)
	lw $t0, max_height	#loading the max_height value of the BMP file
	bne $t9, $t0, throw_file_height_error
#---------------------------------------------------------------	
#close file
	li $v0, 16		#using the syscall 16 instruction for closing the file
        syscall
	
	lw $s1, ($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

#------------------------------- Saving the file---------------------------------
save_bmp:
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, ($sp)
#open file
	move $t8, $a1
        la $a0, output_filename		#file name 
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignored
        li $v0, 13		#using the syscall 13 instruction for opening to file
        syscall
	move $s1, $v0      	# save the file descriptor
	
#checking the errors -> i.e. $v0 < 0
        bltz $v0, throw_opening_file_error	#checking if the $s1 is smaller than 0, i.e. 0xFFFFFFFF
						#if it is true then the error message should be printed
#writing to file
	move $a0, $s1			#moving the file descriptor to $a0
	lw $a1, pHeader($t8)		#loading the address of image buffer
	lw $a2, fileSize($t8)		#loading the image BMP size
	li $v0, 15			#using the syscall 15 instruction for writing to file
	syscall
	
	#checking the errors -> i.e. $v0 < 0
        bltz $v0, throw_writing_file_error	#checking if the $s1 is smaller than 0, i.e. 0xFFFFFFFF
						#if it is true then the error message should be printed
#close file
	li $v0, 16			#using the syscall 16 instruction for closing the file
        syscall
	
	lw $s1, ($sp)		
	add $sp, $sp, 4
	lw $ra, ($sp)		
	add $sp, $sp, 4
	jr $ra


#------------------------------- Insert the pixel---------------------------------
insert_the_pixel:
	#arguments to the function:
	# $a0 - x coordinate of the pixel
	# $a1 - y coordinate of the pixel
	# returns: nothing

	sub $sp, $sp, 4		
	sw $ra,($sp)

	la $t1, imageBuff + 10	#adress of image offset to get pixels array
	lw $t2, ($t1)		#loading the image offset to pixels array in $t2
	la $t1, imageBuff	#loading the image buffer in $t1
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BMP_BYTES_PER_ROW 	#mulitplying the y coordinate by the number of bytes in a row to be at proper height
	move $t3, $a0		#moving the x coordinate into $t3 register
	sll $a0, $a0, 1		#multiplying the x coordinate by 2
	add $t3, $t3, $a0	#adding to the $t3 => x multiplication of x by 3 => 3x
	add $t1, $t1, $t3	#adding the 3x to y*BYTES_PER_ROW to be at proper position to insert the pixel
	add $t2, $t2, $t1	#storing the pixel address in $t2 as sum of $t2 and $t1
	
#setting new color of current pixel
	sb $a2,($t2)		#storing byte the B color in $a2
	srl $a2,$a2,8		#shifting to the right the bytes of the pixel by 1 to have an access to G color address
	sb $a2,1($t2)		#storing byte the G color in $a2
	srl $a2,$a2,8		#shifting to the right the bytes of the pixel by 1 to have an access to R color address
	sb $a2,2($t2)		#storing byte the R color in $a2

	lw $ra, ($sp)		
	add $sp, $sp, 4
	jr $ra
#------------------------------- Getting the pixel ---------------------------------
get_pixel:
	#arguments to the function:
	# $a0 - x coordinate of the current pixel
	# $a1 - y coordinate of the current pixel
	#loading each of the color R => $t8, G => $s7, B => $s6 
	# returns: $v0 - the color of the pixel => 0x00RRGGBB
	
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)

	la $t1, imageBuff + 10	#adress of image offset to get pixels array
	lw $t2, ($t1)		#loading the image offset to pixels array in $t2
	la $t1, imageBuff	#loading the image buffer in $t1
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
#calculating the address of the pixel
	mul $t1, $a1, BMP_BYTES_PER_ROW  #t1= y*BYTES_PER_ROW
	move $t3, $a0		#moving the x coordinate into $t3 register
	mul $t3, $a0, 3
	add $t1, $t1, $t3	#adding the 3x to y*BYTES_PER_ROW to be at proper position to insert the pixel
	add $t2, $t2, $t1	#storing the pixel address in $t2 as sum of $t2 and $t1
	
#getting the color of the current pixel and storing each color => R,G,B into the registers $t8, $s7, $s6
	lbu $v0,($t2)		#loading the B
	move $s6, $v0
	lbu $t1,1($t2)		#loading the G
	move $s7, $t1
	sll $t1,$t1,8
	or $v0, $v0, $t1
	lbu $t1,2($t2)		#loading the R
	move $t8, $t1
        sll $t1,$t1,16
	or $v0, $v0, $t1
					
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

#------------------------------- Checking the given inequality---------------------------------
check_inequality: 
	#arguments:
	# $t8 => R, $s7 => G, $s6 => B
	# checking the inequality: thres >= 0.21R + 0.72G + 0.07B
	# if its fulfilled then the pixel is WHITE => set_pixel_to_white
	# it it's not then the pixel is BLACK => set_pixel_to_black
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	#in the function "reading_threshold_value" I have muliplied the read threshold value by 100 to form:
	# 100thres >= 21R + 72G + 7B
	#thanks to that I have ommited the issues with floatings points arithmetic
	mulu $t1, $t8, 21
	mulu $t2, $s7, 72
	mulu $t3, $s6, 7
		
	#addition of each of the colors
	addu $t1, $t1, $t2	#sum of R + G
	addu $t1, $t1, $t3	#sum of R + G + B
	ble $t1, $s5, set_pixel_to_white	#checking if the iinequality is fulfilled, then pixel is set to white
#check_if_its_already_white:
	bgt $t1, $s5, set_pixel_to_black	#checking if the iinequality isn't fulfilled, then pixel is set to black
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
	
set_pixel_to_white:
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
		
	li $a2, 0xFFFFFFFF	#white color in hex
	jal insert_the_pixel	#inserting the pixel with arguments $a0, $a1 and $a2
	
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
	
	
set_pixel_to_black:
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
		
	li $a2, 0x00000000	#color color in hex
	jal insert_the_pixel	#inserting the pixel with arguments $a0, $a1 and $a2
	
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

reading_top_left_corner_coordinate:
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	
	#prompt message for user
	li $v0, 4		#syscall 4 instruction for printing the string
	la $a0, first_input_msg	#loading the address of first_input_msg string
	syscall
	
	#reading x1
	li $v0, 5		#syscall 5 instruction for reading the integer
	syscall
	move $s0, $v0		#moving the read value to $s0 to store this data for further usage
	move $k0, $s0		#moving the read value to register $k0 to be able to 
				#begin the iterating the line of pixels from the same x1 (it's changing in the loop)
	
	lw $t0, max_width	#loading the max_width value of the BMP file
	#checking if the read x1 is not out of the dimensions of the BMP file
	bgt $s0, $t0, throw_first_input_error
	
	#reading y1
	li $v0, 5		#syscall 5 instruction for reading the integer
	syscall
	move $s4, $v0		#moving the read value to $s0 to store this data for further usage
	
	lw $t0, max_height	#loading the max_height value of the BMP file
	#checking if the read y1 is not out of the dimensions of the BMP file
	bgt $s4, $t0, throw_first_input_error	
	
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
	
reading_bottom_right_corner_coordinates:
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	
	#prompt message for user
	li $v0, 4			#syscall 4 instruction for printing the string for user
	la $a0, second_input_msg	#loading the address of the message
	syscall
	
	#reading x2
	li $v0, 5			#syscall 5 instruction for reading the integer
	syscall
	move $s2, $v0			#moving the read value to $s2 to store this data for further usage
	
	lw $t0, max_width		#loading the max_width value of the BMP file
	#checking if the read x1 is not out of the dimensions of the BMP file
	bgt $s2, $t0, throw_first_input_error
	
	#reading y2
	li $v0, 5			#syscall 5 instruction for reading the integer
	syscall
	move $s3, $v0			#moving the read value to $s3 to store this data for further usage
	
	lw $t0, max_height		#loading the max_height value of the BMP file
	#checking if the read x1 is not out of the dimensions of the BMP file
	bgt $s3, $t0, throw_first_input_error
	
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

reading_threshold_value	:
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	
	#prompt message
	li $v0, 4			#syscall 4 instruction for printing the string for user
	la $a0, threshold_input_msg	#loading the address of the message	
	syscall
	
	#reading thres
	li $v0, 5			#syscall 5 instruction for reading the integer
	syscall
	mul $s5, $v0, 100 		#multiplying the read threshold value by 100 => explanation why in 
					#function "check_inequality"
	lw $t0, max_thres
	mul $t0, $t0, 100
	bgt $s5, $t0, throw_threshold_input_error
	blt $s5, $zero, throw_threshold_input_error
	
	
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
	
checking_the_correctness_of_points:
	# $s0 -> x1, $s4 -> y1	
	# $s2 -> x2, $s3 -> y2					
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,($sp)
	
	blt $s2, $s0, throw_x2_less_than_x1_error
	
	lw $ra, ($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

throw_opening_file_error:
	li $v0, 4			#loading the address of string to be printed
	la $a0, error_file_opening		
	syscall
	li $v0, 10
	syscall


throw_reading_file_error:	
	li $v0, 4			#loading the address of string to be printed
	la $a0, error_file_reading		
	syscall
	li $v0, 10
	syscall
	
throw_writing_file_error:
	li $v0, 4			#loading the address of string to be printed
	la $a0, error_file_writing		
	syscall
	li $v0, 10
	syscall

throw_file_width_error:
	li $v0, 4
	la $a0, error_file_width
	syscall
	li $v0, 10
	syscall

throw_file_height_error:
	li $v0, 4
	la $a0, error_file_height
	syscall
	li $v0, 10
	syscall

throw_first_input_error:
	li $v0, 4
	la $a0, error_first_input
	syscall
	jal readings_of_x1_y1

throw_second_input_error:
	li $v0, 4
	la $a0, error_second_input
	syscall
	jal readings_of_x2_y2

throw_threshold_input_error:
	li $v0, 4
	la $a0, error_threshold
	syscall
	jal reading_of_threshold

throw_file_format_error:
	li $v0, 4
	la $a0, error_file_format
	syscall
	li $v0, 10
	syscall	
	
throw_x2_less_than_x1_error:
	li $v0, 4
	la $a0, error_x2_less_than_x1
	syscall
	jal readings_of_x1_y1
