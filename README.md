# Snake
Written in MIPS Assembly Language

## Run Instructions

1. open MARS 4.4
2. open Keyboard and LED Display Simuator from TOOLS 
3. connect LED window to MIPS
4. open and assemble snake.asm
5. run
6. begin game by tapping d or the right arrow key

### Global Variables

- $t5 = FRONT // begining of memory address for snake body 
- $t6 = END // end of memory address for snake body 
- $t7 = TAIL // address of tail
- $t8 = HEAD // address of head
- $t9 = total score 
- $s3 = time // time played in milliseconds
- $s4 = score // temporary score
- $s6 = button map // value of input from button presses
- $s7 = length // logical size of snake
	
### LED Values

- 00: off
- 01: red
- 10: yellow
- 11: green

### Button Values
 
- 0xE0: UP 
- 0XE1: DOWN 
- 0XE2: LEFT
- 0XE3: RIGHT 
- 0X42: B BUTTON
	
### Snake Data Structure
 
- ADT: Queue
- IMPLEMENTATION: Circular Buffer
	
### PART I: Initialization

#### _loadWalls
uses a series of loops that increment the x and y coordinates to build the walls for the board
```	
void _loadWalls(int x, int y)
//	arguments: $a0 is x, $a1 is y
//	returns: none
```
	
#### _initSnake
initiates the snake data structure and sets the yellow LEDs on the board for the snake body. Also, finds initial length, tail address, and head address.
```
void _initSnake()
//	arguments: none
//	returns: none
```
	
#### _initFrogs
populates the board with 32 green frogs placed random location, using the _getRand method
```
void _initFrogs()
//	arguments: none
//	returns: none
```

### PART 2: Main Loop
 
#### tick
sleep syscall for 200 milliseconds. Serves as our clock tick between moves. This makes the game playable.
```
void tick()
// 	arguments: none
// 	returns: none
```
	
#### _getButtonPress
Retrieves new button value from memory address if a button has been pressed. Otherwise the button value remains the same from the last tick. This function also deals with when the user tries to move in a direction opposite the one they're moving, ie. trying to move up when they're moving down. To deal with with, we add the last button value with the current value and mask off the last bit. If the bit is a 1 or 5, then the new button press is in the opposite direction and we don't assign the new button value by jumping to the end.
```
byte _getButtonPress()
//	arguments: none
//	returns: $t4 is button value
```

#### _peek
fetches and returns the coordinate from the head of the snake (end of queue)
```
half _peek()
//	arguments: none
//	returns: $v0 is x, $v1 is y
```

#### _remove
removes and returns the coordinate from the tail of the snake (front of the queue)
```	
half _remove()
//	arguments: none
//	returns: $v0 is x, $v1 is y
```
	
#### _insert
inserts coordinate at the head of the snake (end of queue). Appends coordinate to head of snake and lights up LED.
```
void _insert(int x, int y)
//	arguments: $a0 is x, $a1 is y
//	returns: none
```
	
#### _getRand
randomly generates an integer between 0 and 63
```
byte _getRand()
//	arguments: none
//	returns: $v0 is random integer
```
	
#### _setLED
sets the LED at coordinate (x,y) to the value of $a2
```
void _setLED(int x, int y)
//	arguments: $a0 is x, $a1 is y
//	returns: none
```
	
#### _getLED
returns the LED value at coordinate (x,y)
```
byte _getLED(int x, int y)
//	arguments: $a0 is x, $a1 is y
//	returns: $v0 is LED value
```

#### events
This is the action function that moves the snake. From within events, we call the _move functions to move in different directions based on the button value. This is called after we tick the clock and retrieve that status of the button in the main loop. We implement movement by inserting at the end of the queue and removing from the front of the queue.
```
void events(int value)
//	arguments: $t4 is button value (direction)
//	returns: none
```

#### _moveRight
checks the space to the right of the head. If the coordinate is a wall, it reacts accordingly. Else if the coordinate is a frog, then it is eaten by the snake. Else if the coordinate is the snake body, then the game is over and we jump to the exit loop. Else the snake moves to the spot.
```
byte _moveRight()
//	arguments: none
//	returns: $t4 is button value (direction)
```

#### _moveLeft
checks the space to the left of the head. If the coordinate is a wall, it reacts accordingly. Else if the coordinate is a frog, then it is eaten by the snake. Else if the coordinate is the snake body, then the game is over and we jump to the exit loop. Else the snake moves to the spot.
```
byte _moveLeft()
//	arguments: none
//	returns: $t4 is button value (direction)
```

#### _moveUp
checks the space above the head. If the coordinate is a wall, it reacts accordingly. Else if the coordinate is a frog, then it is eaten by the snake. Else if the coordinate is the snake body, then the game is over and we jump to the exit loop. Else the snake moves to the spot. 

With moveUp, we also check to see if we're moving through the slot in the top wall. If so, we add 63 to our coordinates to send it through the hole at the bottom wall.
```
byte _moveUp()
//	arguments: none
//	returns: $t4 is button value (direction)
```

#### _moveDown
checks the space below the head. If the coordinate is a wall, it reacts accordingly. Else if the coordinate is a frog, then it is eaten by the snake. Else if the coordinate is the snake body, then the game is over and we jump to the exit loop. Else the snake moves to the spot.
	
With moveDown, we check to see if we're moving through the hole in the bottom wall. If so, we subtract 63 from the y coordinate to send it through the hole in the top wall.
```
byte _moveDown()
//	arguments: none
//	returns: $t4 is button value (direction)
```
### PART 3: Exit Loop
 The exit loop prints both the time spent in the game and the total points to the console. The program is then terminated.

