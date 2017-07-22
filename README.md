// README.txt - SNAKE by Michael Plazek - mlp93@pitt.edu

 *** RUN INSTRUCTIONS ***

	(1) open MARS 4.4-Pitt.1
	(2) open Keyboard and LED Display Simuator from TOOLS 
	(3) connect LED window to MIPS
	(4) open and assemble snake.asm
	(5) run
	(6) begin game by tapping d or the right arrow key

 *** GLOBAL VARIABLES ***

	$t5 = FRONT // begining of memory address for snake body 
	$t6 = END // end of memory address for snake body 
	$t7 = TAIL // address of tail
	$t8 = HEAD // address of head
	$t9 = total score 
	
	$s3 = time // time played in milliseconds
	$s4 = score // temporary score
	$s6 = button map // value of input from button presses
	$s7 = length // logical size of snake
	
 *** LED VALUES ***

	00: off
	01: red
	10: yellow
	11: green

 *** BUTTON VALUES ***
 
	0xE0: UP 
	0XE1: DOWN 
	0XE2: LEFT
	0XE3: RIGHT 
	0X42: B BUTTON
	
 *** SNAKE DATA STRUCTURE ***
 
	ADT: Queue
	IMPLEMENTATION: Circular Buffer
	
	DESCRIPTION: Each segment is a half word - 1 byte for x and 1 byte for y. Since x and y must be between 0 and 63, then 1 half will enough room to store any coordinate. The logical size (length), address of head, address of tail and start and end of memory space is stored in registers. The front and end space have far more than enough room for all possible combinations (64^2 = 4096 bytes). When the index is out of bounds, it wraps around to the front memory address again. Initially, I used a fixed array and shifted the elements each time a new segment was added, but I changed it to circular after reading the lab.
	
	ie.
	---------------------
	| y2 | x2 | y1 | x1 |
  3 --------------------- 0 : bytes
	
	|<------WORD------->|
	
	
 *** GENERAL EXPLANATION OF PROGRAM ***
 
	The general format of the program is 3 phases: (i) initialization, (ii) the main loop, and (iii) the exit loop. The functions for each phase are outlined below. During the initialization phases, we load the board and print the intro text. The walls are loaded with a long series of loops that load red LEDs. While this was NOT a good way to go about doing this, it works perfectly. It was the first portion I wrote and I was a bit out of practice. After the walls, the snake body was loaded from memory, starting at {3,31} and ending at {11,31}. The full description of the snake data structure is above. Next 32 frogs were generated in random coordinates, using my _getRand function. The frogs were loaded last, because if the LED was already green, yellow or red, then a new frog would be generated somewhere where the LED value was 0.  
	
	The main loop links to several functions and then jumps back to keep looping until the end conditions are met. First, the button input is checked. If a button was pressed, we check it against several conditions. If it is in the opposite direction of the snake's current movement, then we jump to the end of the function and don't do anything. Otherwise, we add the new direction value to our direction register and continue. If a button has NOT been pressed then we just jump to the end of the function and keep the current direction. Next, we check if we've collected all the frogs. If so, we break out of the main loop and exit. Otherwise, we tick the clock once. After our tick, we look at the position of our head segment. If it's moving through the top or bottom holes, we deal with that by adding or subtracting 63. Otherwise, based on the state of that LED, we go into one of several events. If it's red, the snake then checks if it is a corner. If it is, then you check the next available coordinate. If that is red too then you run into yourself and we jump to the exit loop. If it's clear, the snake makes an orthogonal turn and moves parallel to the wall. If it's green, we add a new slot to our snake data structure and turn the LED yellow. If it is yellow, then we have run into ourselves and we immediately jump to the exit loop. We deal with each case according the current direction it is moving, inside the _moveRight, _moveUp, etc. functions. If none of the end conditions have been met by this point, then we jump back to the start of the main loop and repeat. Also, if b is pressed, then the game ends.
	
	Once any of the end conditions are met, ie. we run into ourselves, eat all the frogs, or get trapped in a corner, then we jump to the exit loop. There we print our total game time and score. Then we end the program with a syscall.
	
	NOTE: 200ms clock is a bit slow.
	NOTE: 'b' button ends the game
	
	Below are descriptions of all the functions.
	
#################################################################################
	
						*** PART I: INITIALIZATION ***

#################################################################################

	_loadWalls: uses a series of loops that increment the x and y coordinates to build the walls for the board. This is not the best way to do it - but it works fine.
	
	void _loadWalls(int x, int y)
	//	arguments: $a0 is x, $a1 is y
	//	returns: none
	
################################################################################

	_initSnake: initiates the snake data structure and sets the yellow LEDs on the board for the snake body. Also, finds initial length, tail address, and head address.
	
	void _initSnake()
	//	arguments: none
	//	returns: none
	
#################################################################################

	_initFrogs: populates the board with 32 green frogs placed random location, using the _getRand method
	
	void _initFrogs()
	//	arguments: none
	//	returns: none
	
################################################################################

						*** PART 2: MAIN LOOP ***
 
################################################################################

	tick: sleep syscall for 200 milliseconds. Serves as our clock tick between moves. This makes the game playable.

	void tick()
	// arguments: none
	// returns: none
	
################################################################################

	_getButtonPress: Retrieves new button value from memory address if a button has been pressed. Otherwise the button value remains the same from the last tick. This function also deals with when the user tries to move in a direction opposite the one they're moving, ie. trying to move up when they're moving down. To deal with with, we add the last button value with the current value and mask off the last bit. If the bit is a 1 or 5, then the new button press is in the opposite direction and we don't assign the new button value by jumping to the end.
	
	byte _getButtonPress()
	//	arguments: none
	//	returns: $t4 is button value
	
################################################################################

	_peek: fetches and returns the coordinate from the head of the snake (end of queue)
	
	half _peek()
	//	arguments: none
	//	returns: $v0 is x, $v1 is y
	
################################################################################

	_remove: removes and returns the coordinate from the tail of the snake (front of the queue)
	
	half _remove()
	//	arguments: none
	//	returns: $v0 is x, $v1 is y
	
################################################################################

	_insert: inserts coordinate at the head of the snake (end of queue). Appends coordinate to head of snake and lights up LED.
	
	void _insert(int x, int y)
	//	arguments: $a0 is x, $a1 is y
	//	returns: none
	
################################################################################

	_getRand: randomly generates an integer between 0 and 63
	
	byte _getRand()
	//	arguments: none
	//	returns: $v0 is random integer
	
################################################################################

	_setLED: sets the LED at coordinate (x,y) to the value of $a2 - prewritten for the lab
	
	void _setLED(int x, int y)
	//	arguments: $a0 is x, $a1 is y
	//	returns: none
	
################################################################################

	_getLED: returns the LED value at coordinate (x,y)- prewritten for the lab
	
	byte _getLED(int x, int y)
	//	arguments: $a0 is x, $a1 is y
	//	returns: $v0 is LED value
	
################################################################################

	events: This is the action function that moves the snake. From within events, we call the _move functions to move in different directions based on the button value. This is called after we tick the clock and retrieve that status of the button in the main loop. We implement movement by inserting at the end of the queue and removing from the front of the queue.
	
	void events(int value)
	//	arguments: $t4 is button value (direction)
	//	returns: none
	
################################################################################

	_moveRight: checks the space to the right of the head. If the coordinate is a wall, it reacts accordingly. Else if the coordinate is a frog, then it is eaten by the snake. Else if the coordinate is the snake body, then the game is over and we jump to the exit loop. Else the snake moves to the spot.
	
	byte _moveRight()
	//	arguments: none
	//	returns: $t4 is button value (direction)
	
################################################################################

	_moveLeft: checks the space to the left of the head. If the coordinate is a wall, it reacts accordingly. Else if the coordinate is a frog, then it is eaten by the snake. Else if the coordinate is the snake body, then the game is over and we jump to the exit loop. Else the snake moves to the spot.
	
	byte _moveLeft()
	//	arguments: none
	//	returns: $t4 is button value (direction)
	
################################################################################

	_moveUp: checks the space above the head. If the coordinate is a wall, it reacts accordingly. Else if the coordinate is a frog, then it is eaten by the snake. Else if the coordinate is the snake body, then the game is over and we jump to the exit loop. Else the snake moves to the spot.
	
	With moveUp, we also check to see if we're moving through the slot in the top wall. If so, we add 63 to our coordinates to send it through the hole at the bottom wall.
	
	byte _moveUp()
	//	arguments: none
	//	returns: $t4 is button value (direction)
	
################################################################################

	_moveDown: checks the space below the head. If the coordinate is a wall, it reacts accordingly. Else if the coordinate is a frog, then it is eaten by the snake. Else if the coordinate is the snake body, then the game is over and we jump to the exit loop. Else the snake moves to the spot.
	
	With moveDown, we check to see if we're moving through the hole in the bottom wall. If so, we subtract 63 from the y coordinate to send it through the hole in the top wall.
	
	byte _moveDown()
	//	arguments: none
	//	returns: $t4 is button value (direction)
	
################################################################################

						*** PART 3: EXIT LOOP ***
 
################################################################################

	The exit loop prints both the time spent in the game and the total points to the console. The program is then terminated.
	
 *** BUGS/ISSUES ***
 
	(FIXED) Sometimes some of the wall LEDs will randomly go out as the snake grows in size. It only happens some times and I could not figure out the cause. 
	 *SOLVED THE ISSUE BY RELOADING WALLS EACH ITERATION 
	
	(1) The arrow keys don't work, but the WSAD do, as well as the direction keys on the LED simulator. Also, if you mash the buttons they tend to freeze up.
