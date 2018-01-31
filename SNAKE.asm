# SNAKE - Michael Plazek - mlp93@pitt.edu

.data

lower: .space 4096 # 64*64 --> enough spaces for the whole board to be safe 
snake: .byte 4 31 5 31 6 31 7 31 8 31 9 31 10 31 11 31
upper: .space 4096
score: .byte 64

intro: .asciiz "WELCOME TO SNAKE\n\n"
start: .asciiz "Game starting...\n"

lose: .asciiz "Game over...\n\nThe playing time was "
lose2: .asciiz "ms.\nThe game score was "
lose3: .asciiz " frogs.\n"
between: .asciiz "||"

.text

# MAIN VARIABLES
#
#	$s7 = LENGTH
#	$t6 = END
#	$t7 = TAIL
#	$t8 = HEAD
#	$t5 = FRONT
#	$s6 = button address
#	$t9 = total score
# 	$s4 = score
#	$s3 = time
#

main:

# ----------------------
# INTRO MESSAGE
# ----------------------

	la $a0, intro
	li $v0, 4
	syscall
	
	la $a0, start
	syscall

# ----------------------
# INITIALIZE DISPLAY
# ----------------------

jal _loadWalls
jal _initSnake
jal _initFrogs

# ----------------
# MAIN LOOP - main loop for runtime
# ----------------

# clear variables before main loop
andi $t9, $zero, 0x0000 # score
li $s4, 0 
li $t2, 0

main_loop:
	jal _getButtonPress
	beq $t9, 32, exit_loop
	jal tick # 200ms clock tick
	jal _peek 
	jal events # check action listeners
	jal _loadWalls
j main_loop

# ----------------
# EXIT - print results and end program
# ----------------

exit_loop:
	li $v0, 4
	la $a0, lose
	syscall
	
	li $v0, 1
	move $a0, $s3
	syscall
	
	li $v0, 4
	la $a0, lose2
	syscall
	
	li $v0, 1
	move $a0, $t9
	syscall
	
	li $v0, 4
	la $a0, lose3
	syscall
	
	li $v0, 10
	syscall

# -----------------------------
# FUNCTIONS
# -----------------------------

# void events()
#	
#	This is the method that handles all the movement that happen during the course of the game
#	arguments: none
#	returns: none
#
events:
	addi $sp, $sp, -4
	sw $ra, ($sp)

	beq $t4, 0x42, exit_loop # exit game is b is pressed
	beq $t4, 0xE0, _moveUp
	beq $t4, 0xE1, _moveDown
	beq $t4, 0xE2, _moveLeft
	beq $t4, 0xE3, _moveRight
	
	exit_events:
	lw $ra, ($sp)
	addi $sp, $sp, 4
jr $ra

# void tick()
#
#	Clock tick to drive the game engine
#	arguments: none
#	returns: none
#
tick:
	# push $v0 and $a0
	addi $sp, $sp, -8
	sw $v0, ($sp)
	sw $a0, 4($sp)
	
	li $v0, 32	# syscall sleep
	li $a0, 200	# 200 ms
	syscall
	
	# increment the game clock
	addi $s3, $s3, 200

	# pop $v0 and $a0
	lw $v0, ($sp)
	lw $a0, 4($sp)
	addi $sp, $sp, 8
jr $ra				# Return

# byte getButtonPress()
#
#	arguments: none
#	returns: $v0 is direction (0xE0 = up, 0xE1 = left, 0xE2 = down, 0xE3 = right)
#	$t4 is last button press
#	$t3 is current button press
#
_getButtonPress:
	# push onto stack
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	# clear old direction
	lui $v0, 0x0000
	andi $v0, $v0, 0x0000
	
	lui $t2, 0x0000
	andi $t2, $t2, 0x0000
	
	lui $t3, 0x0000
	andi $t3, $t3, 0x0000
	
	# load base address of button map
	andi $s6, $zero, 0x0000
	lui $s6, 0xFFFF
	lbu $v0, ($s6)
	
	# if we don't get any more button input - just keep current direction value
	beq $v0, 0, no_press
	lbu $t3, 4($s6) # load button value into temp register
		
	# now, deal with forbidden button presses
	add $t2, $t4, $t3 # add last and current direction
	andi $t2, $t2, 0x0F # find last bit with mask
	
	# don't assign new button push if it's in the opposite direction
	beq $t2, 1, no_press 
	beq $t2, 5, no_press
	
	# if everything passes, we reassign the new value of button
	move $t4, $t3
	
	no_press:
	# pop off stack
	lw $ra, ($sp)
	addi $sp, $sp, 4
jr $ra

# half remove()
#
#  removes coord (x,y) at front of queue (tail of snake)
#  returns:   $v0 is (x,y) coord stored in half
#  arguments: none
#
_remove:
	# allocate stack space
	addi $sp, $sp, -12
	sw $t1, 8($sp)
	sw $t0, 4($sp)
	sw $ra, ($sp)
	
	# if the tail is greater than the size of the memory, 
	# then we assign it back to the first spot to wrap around
	bgt $t7, $t6, reset_remove
	end_rreset:
	
	# otherwise, we load the tail bytes and turn them to zero
	# then we remove them
	lbu $t0, 0($t7)
	lbu $t1, 1($t7)
	
	move $v0, $t0
	move $v1, $t1
	
	andi $t0, $t0, 0x0000
	andi $t1, $t1, 0x0000
	
	# load segment
	move $a0, $v0
	move $a1, $v1
	li $a2, 0
	jal _setLED
	
	# remove the tail element
	sh $t0, ($t7)
	addi $t7, $t7, 2
	addi $s7, $s7, -1 # decrement count
	
	# pop off stack
	lw $t1, 8($sp)
	lw $t0, 4($sp)
	lw $ra, ($sp)
	addi $sp, $sp, 12
jr $ra

reset_remove:
	la $t7, lower
	j end_rreset

# byte peek()
#
#  return coord from the end of the queue (head of snake)
#  returns:   $v0 as x, $v1 as y
#  arguments: none
#
_peek:
	lbu $v0, 0($t8)
	lbu $v1, 1($t8)
jr $ra

# void insert(int x, int y)
#
#  inserts coord (x,y) at end of queue (head of snake)
#  returns:   none
#  arguments: $a0 is x, $a1 is y
#
_insert:
	# allocate stack space
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# set color
	li $a2, 2 
	
	# check if the index is in bounds of the memory space
	# if not, we wrap it around by loading the base memory address again
	beq $t8, $t6, reset_insert
	
	# add new segment to data structure
	end_reset:
	addi $t8, $t8, 2 # increment head
	sb $a0, 0($t8) # x-coord
	sb $a1, 1($t8) # y-coord
	jal _setLED
	addi $s7, $s7, 1 # increment length
	
	# pop back from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
jr $ra # return

reset_insert:
	la $t8, lower
	j end_reset

# int _getRand()
#
#  randomly generates an int between 0 and 63
#  returns:   $v0
#  trashes: $a0, $a1
#
_getRand:
	# push stack
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	sw $a1, 4($sp)
	
	# syscall to generate pseudorandom number
	li $a1, 63 
	li $v0, 42
	syscall
	# return int
	move $v0, $a0 
	
	# pop stack
	lw $ra, 0($sp)
	lw $a1, 4($sp)
	addi $sp, $sp, 8
jr $ra


# ----------------
# MOVEMENT
# ----------------	

_moveRight:

	addi $sp, $sp, -8
	sw $v0, 4($sp)
	sw $ra, ($sp)
	
	# get next location of head
	jal _peek

	addi $a0, $v0, 1
	addi $a1, $v1, 0
	
	# check if the next spot is a wall
	jal _getLED
	bne $v0, 1, else_right
	addi $a0, $a0, -1
	addi $a1, $a1, 1
	li $t4, 0xE1

	# now, check if the spot is a froggie
	else_right:
	bne $v0, 3, end_right
	
	# if it is, add segment on end of snake
	jal _insert
	addi $t7, $t7, -2
	addi $t9, $t9, 1
	end_right:
	
	# if we hit ourselves, the game is over - jump to display score 
	bne $v0, 2, dead_right
	j exit_loop
	
	dead_right:
	# else store the location and move one spot
	jal _insert
	jal _remove
	
	lw $ra, ($sp)
	lw $v0, 4($sp)
	addi $sp, $sp, 8
	
j exit_events


_moveUp:

	addi $sp, $sp, -8
	sw $v0, 4($sp)
	sw $ra, ($sp)
	
	jal _peek
	
	# check if we're moving through the top of the board
	bne  $v1, $zero, check1
	
	# if so, we add 63 to send it to the bottom of the board, through the hole
	addi $a0, $v0, 0
	addi $a1, $v1, 63
	j check2
	
	check1:
	addi $a0, $v0, 0
	addi $a1, $v1, -1
	
	check2:
	# check if the next spot is a wall
	jal _getLED
	bne $v0, 1, else_up
	addi $a0, $a0, 1
	addi $a1, $a1, 1
	li $t4, 0xE3
	
	# now, check if the spot is a froggie
	else_up:
	bne $v0, 3, end_up
	
	# if it is, add segment on end of snake
	jal _insert
	addi $t7, $t7, -2
	addi $t9, $t9, 1
	end_up:
	
	# if we hit ourselves, the game is over - jump to display score 
	bne $v0, 2, dead_up
	j exit_loop
	
	dead_up:
	# else store the location and move one spot
	jal _insert
	jal _remove
	
	lw $ra, ($sp)
	lw $v0, 4($sp)
	addi $sp, $sp, 8
	
j exit_events

_moveDown:

	addi $sp, $sp, -8
	sw $v0, 4($sp)
	sw $ra, ($sp)
	
	jal _peek
	
	# check if we're moving through the bottom of the board
	bne  $v1, 63, checkd1
	
	# if so, we subtract 63 to send it to the top of the board, through the hole
	addi $a0, $v0, 0
	addi $a1, $v1, -63
	j checkd2
	
	checkd1:
	addi $a0, $v0, 0
	addi $a1, $v1, 1
	
	checkd2:
	# check if the next spot is a wall
	jal _getLED
	bne $v0, 1, else_down
	
	addi $a0, $a0, -1
	addi $a1, $a1, -1
	li $t4, 0xE2

	# now, check if the spot is a froggie
	else_down:
	bne $v0, 3, end_down
	
	# if it is, add segment on end of snake
	jal _insert
	addi $t7, $t7, -2
	addi $t9, $t9, 1
	end_down:
	
	# if we hit ourselves, the game is over - jump to display score 
	bne $v0, 2, dead_down
	j exit_loop
	
	dead_down:
	# else store the location and move one spot
	jal _insert
	jal _remove
	
	lw $ra, ($sp)
	lw $v0, 4($sp)
	addi $sp, $sp, 8
	
j exit_events

_moveLeft:

	addi $sp, $sp, -8
	sw $v0, 4($sp)
	sw $ra, ($sp)
	
	jal _peek
	
	addi $a0, $v0, -1
	addi $a1, $v1, 0
	
	# check if the next spot is a wall
	jal _getLED
	bne $v0, 1, else_left
	addi $a0, $a0, 1
	addi $a1, $a1, -1
	li $t4, 0xE0
	
	# now, check if the spot is a froggie
	else_left:
	bne $v0, 3, end_left
	
	# if it is, add segment on end of snake
	jal _insert
	addi $t7, $t7, -2
	addi $t9, $t9, 1
	end_left:
	
	# if we hit ourselves, the game is over - jump to display score 
	bne $v0, 2, dead_left
	j exit_loop
	
	dead_left:
	# else store the location and move one spot
	jal _insert
	jal _remove
	
	lw $ra, ($sp)
	lw $v0, 4($sp)
	addi $sp, $sp, 8
	
j exit_events

# void _setLED(int x, int y, int color)
	#   sets the LED at (x,y) to color
	#   color: 0=off, 1=red, 2=yellow, 3=green
	#
	# arguments: $a0 is x, $a1 is y, $a2 is color
	# trashes:   $t0-$t3
	# returns:   none
	#
_setLED:

	# push return address
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	# byte offset into display = y * 16 bytes + (x / 4)
	sll	$t0,$a1,4      # y * 16 bytes
	srl	$t1,$a0,2      # x / 4
	add	$t0,$t0,$t1    # byte offset into display
	li	$t2,0xffff0008 # base address of LED display
	add	$t0,$t2,$t0    # address of byte with the LED
	# now, compute led position in the byte and the mask for it
	andi	$t1,$a0,0x3    # remainder is led position in byte
	neg	$t1,$t1        # negate position for subtraction
	addi	$t1,$t1,3      # bit positions in reverse order
	sll	$t1,$t1,1      # led is 2 bits
	# compute two masks: one to clear field, one to set new color
	li	$t2,3		
	sllv	$t2,$t2,$t1
	not	$t2,$t2        # bit mask for clearing current color
	sllv	$t1,$a2,$t1    # bit mask for setting color
	# get current LED value, set the new field, store it back to LED
	lbu	$t3,0($t0)     # read current LED value	
	and	$t3,$t3,$t2    # clear the field for the color
	or	$t3,$t3,$t1    # set color field
	sb	$t3,0($t0)     # update display
	
	# pop return address
	lw $ra, ($sp)
	addi $sp, $sp, 4
jr	$ra
	
# int _getLED(int x, int y)
	#   returns the value of the LED at position (x,y)
	#
	#  arguments: $a0 holds x, $a1 holds y
	#  trashes:   $t0-$t2
	#  returns:   $v0 holds the value of the LED (0, 1, 2 or 3)
	#
_getLED:

	# push return address
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	# byte offset into display = y * 16 bytes + (x / 4)
	sll  $t0,$a1,4      # y * 16 bytes
	srl  $t1,$a0,2      # x / 4
	add  $t0,$t0,$t1    # byte offset into display
	la   $t2,0xffff0008
	add  $t0,$t2,$t0    # address of byte with the LED
	# now, compute bit position in the byte and the mask for it
	andi $t1,$a0,0x3    # remainder is bit position in byte
	neg  $t1,$t1        # negate position for subtraction
	addi $t1,$t1,3      # bit positions in reverse order
    	sll  $t1,$t1,1      # led is 2 bits
	# load LED value, get the desired bit in the loaded byte
	lbu  $t2,0($t0)
	srlv $t2,$t2,$t1    # shift LED value to lsb position
	andi $v0,$t2,0x3    # mask off any remaining upper bits
	
	# pop return address
	lw $ra, ($sp)
	addi $sp, $sp, 4
jr   $ra

# void _initSnake()
#
#	arguments: none
#	returns: none
#
_initSnake:
	# push return address
	addi $sp, $sp, -4
	sw $ra, ($sp)

	li $a2, 2 # color = yellow
	li $s4, 0 # count
	# load address of snake 
	la $t7, snake
	move $t5, $s7
	addi $t8, $t7, 14 # head
	li $s7, 8 # length
	la $t6, score
	la $t5, 0($t7) # load base address of snake into temp
	loadSnake:
	beq $s4, $s7, exit_snake # base case
	lbu $a0, 0($t5)
	lbu $a1, 1($t5)
	jal _setLED
	addi $t5, $t5, 2
	addi $s4, $s4, 1
	
	j loadSnake
	
exit_snake:
	lw $ra, ($sp)
	addi $sp, $sp, 4
jr $ra

# void _initFrogs()
#
#	arguments: none
#	returns: none
#
_initFrogs:
	addi $sp, $sp, -4
	sw $ra, ($sp)
	
	andi $s2, $zero, 0x0000
	li $a2, 3
	
	loadFrogs:
	beq $s2, 32, exitLoadFrogs
	# get x-coord
	jal _getRand
	move $s0, $v0
	# get y-coord
	jal _getRand
	move $s1, $v0
	# move coords into argument registers
	move $a0, $s0
	move $a1, $s1
	# get color of coord
	jal _getLED
	# loop again if coord is a wall, snake, or frog
	beq $v0, 1, loadFrogs
	beq $v0, 3, loadFrogs
	beq $v0, 2, loadFrogs
	# else load frog onto coord and increment
	jal _setLED
	addi $s2, $s2, 1
	j loadFrogs
	
exitLoadFrogs:
	lw $ra, ($sp)
	addi $sp, $sp, 4
jr $ra

# LOAD ALL THE WALLS - THE CODE BELOW HERE IS UGLY. BUT IT WORKS.

_loadWalls:
addi $sp, $sp, -4
sw $ra, 0($sp)

li $a0, 0
li $a1, 0
li $a2, 1
li $s0, 0 # count

lp1:
	beq $s0, 31, set3
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp1
set3:
	li $s0, 0
	li $a0, 0
	li $a1, 0
lp3:
	beq $s0, 63, set4
	jal _setLED
	addi $a1, $a1, 1
	addi $s0, $s0, 1
	j lp3
set4:
	li $s0, 0
	li $a0, 33
	li $a1, 0
lp4:
	beq $s0, 31, set5
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp4
set5:
	li $s0, 0
	li $a0, 0
	li $a1, 63
lp5:
	beq $s0, 31, set6
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp5
set6:
	li $s0, 0
	li $a0, 33
	li $a1, 63
lp6:
	beq $s0, 30, set7
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp6
set7:
	li $s0, 0
	li $a0, 63
	li $a1, 63
lp7:
	beq $s0, 63, set8
	jal _setLED
	addi $a1, $a1, -1
	addi $s0, $s0, 1
	j lp7
# *OBSTACLES*
set8:
	li $s0, 0
	li $a0, 20
	li $a1, 21
lp8:
	beq $s0, 7, set9
	jal _setLED
	addi $a1, $a1, 1
	addi $s0, $s0, 1
	j lp8
set9:
	li $s0, 0
	li $a0, 20
	li $a1, 21
lp9:
	beq $s0, 25, set10
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp9
set10:
	li $s0, 0
	li $a0, 20
	li $a1, 29
lp10:
	beq $s0, 7, set11
	jal _setLED
	addi $a1, $a1, 1
	addi $s0, $s0, 1
	j lp10
set11:
	li $s0, 0
	li $a0, 44
	li $a1, 29
lp11:
	beq $s0, 7, set12
	jal _setLED
	addi $a1, $a1, 1
	addi $s0, $s0, 1
	j lp11
set12:
	li $s0, 0
	li $a0, 44
	li $a1, 21
lp12:
	beq $s0, 7, set13
	jal _setLED
	addi $a1, $a1, 1
	addi $s0, $s0, 1
	j lp12
set13:
	li $s0, 0
	li $a0, 20
	li $a1, 35
lp13:
	beq $s0, 25, set14
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp13
set14:
	li $s0, 0
	li $a0, 4
	li $a1, 61
lp14:
	beq $s0, 14, set15
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp14
set15:
	li $s0, 0
	li $a0, 2
	li $a1, 61
lp15:
	beq $s0, 15, set16
	jal _setLED
	addi $a1, $a1, -1
	addi $s0, $s0, 1
	j lp15
set16:
	li $s0, 0
	li $a0, 2
	li $a1, 46
lp16:
	beq $s0, 14, set17
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp16
set17:
	li $s0, 0
	li $a0, 17
	li $a1, 46
lp17:
	beq $s0, 16, set18
	jal _setLED
	addi $a1, $a1, 1
	addi $s0, $s0, 1
	j lp17
set18:
	li $s0, 0
	li $a0, 60
	li $a1, 3
lp18:
	beq $s0, 8, set19
	jal _setLED
	addi $a1, $a1, 1
	addi $s0, $s0, 1
	j lp18
set19:
	li $s0, 0
	li $a0, 50
	li $a1, 3
lp19:
	beq $s0, 8, set20
	jal _setLED
	addi $a1, $a1, 1
	addi $s0, $s0, 1
	j lp19
set20:
	li $s0, 0
	li $a0, 50
	li $a1, 3
lp20:
	beq $s0, 10, set21
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp20
set21:
	li $s0, 0
	li $a0, 50
	li $a1, 11
lp21:
	beq $s0, 5, set22
	jal _setLED
	addi $a0, $a0, 1
	addi $s0, $s0, 1
	j lp21
set22:

lw $ra, 0($sp)
addi $sp, $sp, 4
jr $ra
