/**
 * The MIT License (MIT)
 *
 * Copyright (c) chionic
 * chionic128@outlook.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */


//imports
import ddf.minim.*;

//assets
PImage cloud;
PImage power;
PImage[] powerups;
PImage turtleAnimation;
PImage[] turtle;
PImage turtleAnimationReverse;
PImage[] turtleReverse;
Minim minim;
AudioPlayer death;
AudioPlayer eat;
AudioPlayer pickup;

//player related variables
float xPos = 300; //x position of player
float yPos  = 300;  //y position of player
float velX = 0; //player x velocity
float velY = 0; //player y velocity
float playerSize=10; //size of the player, defines the shorter length (height) of the player rectangle
float playerWidth = playerSize * 1.3; //width of the player, defines the greater length (width) of the player rectangle
int lives = 3;
int score = 0;
int invincibilityTimer = 1500; //time before you can eat/be eaten after dying
float maxSpeed = 6;
int maxSpawnRate = 1000; //how often clouds spawn, right now fastest rate is every second
boolean playerDirection =false; //keeps track of which way the player is facing

//class objects
ArrayList<Blob> blobs = new ArrayList<Blob>(); //blobs ARRAYlist (variable length, can add and remove objects at will)
Collision collision;
Powerups powerup;

int timer; //timer to keep track of when next blob spawns
int timerLength = 3000; //length timer takes to count down which spawns the next blob
int frame; //counts the frame of the turtle animation cycle
boolean odd = false; //makes it so turtle updates animation only every other frame


//runs at the start of the program
void setup(){
  //size of game window and number of times it updates per second
  size(600, 600);
  frameRate(30);
  
  //loading up image assets and dividing up sprite sheets
  imageMode(CENTER);
  rectMode(CENTER);
  cloud = loadImage("cloudA.png");
  power = loadImage("powerups.png");
  powerups = new PImage[5];
  for (int i=0; i<=80; i = i+20){
    powerups[i/20] = power.get(i,0,20,20);
  }
  turtleAnimation = loadImage("turtleAnimation2.png");
  turtleAnimationReverse = loadImage("turtleAnimation.png");
  turtle = new PImage[8];
  turtleReverse = new PImage[8];
  for (int i=0; i<8;i++){
    turtle[i] = turtleAnimation.get(i*115, 0, 115, 100);
    turtleReverse[i] = turtleAnimationReverse.get(i*115, 0, 115, 100);
  } //finished loading image assets
  
  //loading sound assets
   minim = new Minim(this);
   death = minim.loadFile("Hit_Hurt53.wav");
  pickup = minim.loadFile("Powerup42.wav");
  eat = minim.loadFile( "Powerup25.wav");
  
  //setting up timers
  timer = millis()+ timerLength;
  invincibilityTimer = millis() + timerLength;
  
  //creating instances of other classes
  collision = new Collision();
  powerup = new Powerups();
}



//redrawn every frame
void draw(){
  
  //when all lives lost, pauses the game for two seconds then exits the window
  if (lives<=0 ){
    delay(2000);
    exit();
  }
  background(120,170,240);
  
  //deals with player movement input, if w/a/s/d pressed player moves
  if (keyPressed == true) {
     if (key == 'd' && velX <= maxSpeed){
       velX += 0.2;
       playerDirection = false;
     }
     if (key == 'a' && velX >= -maxSpeed){
       velX += -0.2;
       playerDirection = true;
     }
     if (key == 's' && velY <= maxSpeed){
       velY += 0.2;
     }
     if (key == 'w' && velY >= -maxSpeed){
       velY += -0.2;
     } //end player input
  } 
  
  //adds 'drag' to player so they slow down if a key is not pressed
  else {
    if (velX > 0){
      velX -= 0.02;
    }
    else if (velX < 0){
      velX += 0.02;
    }
      
    if (velY > 0){
      velY -= 0.02;
    }
    else if (velY < 0){
      velY += 0.02;
    }
  } //end player drag
  
  //redefines the position of the player object (so it looks like the player moves)
  xPos = xPos + velX;
  yPos = yPos + velY;
  
  //makes the player wrap around the screen
  if (yPos < 0) {
    yPos = height;
  }
  else if (yPos > height){
    yPos = 0;
  }
  
  if (xPos < 0){
    xPos = width;
  }
  else if (xPos > width){
    xPos = 0;
  } //end player wrap
    
  //checks if the timer has run out and creates a new blob if it has
  if (timer <= millis()){
    blobs.add(new Blob());
    blobs.get(blobs.size()-1).blobSpawn();
    timer += timerLength;
    if (timerLength > maxSpawnRate){
      timerLength -= 50;
    } 
  }
  
  //draws and moves each blob on the screen, also removes them once they're off screen
  for (int i= 0; i<blobs.size();i++){
    Blob blob = blobs.get(i);
    if(blob.xBlob < -30 || blob.yBlob < -30 || blob.xBlob > width + 30 || blob.xBlob > height + 30){
      blobs.remove(i);
    }
    blob.blobMove();
    tint(blob.bColor);
    image(cloud, blob.xBlob, blob.yBlob, blob.bWidth+(blob.bWidth/5), blob.bHeight+(blob.bHeight/5));
  }
  
  //spawns/despawns powerups to the screen an update if the player has eaten them
  powerup.powerupSpawn();
  powerup.powerupLife();
  
  //checks if the player is colliding with any blobs (unless they've just died, in which case they briefly can't be eaten/eat)
  if (invincibilityTimer <= millis()){
    collision.collide(blobs,  xPos, yPos, playerWidth, playerSize/2, (int)(playerSize*playerSize));
    tint(255,255,255);
  }
  else{
    tint(50,50,50);
  }
 
  //draws the player
  odd = !odd;
  if (odd){
  frame = (frame+1) % 8;
  }
  if(playerDirection) {
    image(turtleReverse[frame], xPos, yPos, playerWidth, playerSize); 
  }
  else {
    image(turtle[frame], xPos, yPos, playerWidth, playerSize); 
  }
  
  //draws the score and number of lives player has to the screen
  fill(0,0,0);
  textSize(30);
  text(score, 10,40);
  for (int i=lives; i>0; i--){
    tint(255,255,255);
    image(turtle[0], 480 + (i*30), 25, 30,20);
  }
  
  //does the aesthetic part of the game over when all lives are lost
  if (lives <= 0){
    clear();
    background(200,0,0);
    fill(0,0,0);
    text("Game Over",width/2 - 80,height/2 - 40);
    text( "Your score:   " + score, width/2 - 120, height/2 + 20);
  }
}





//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Blob Class~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\\
//Blobs are the enemy things you run into
class Blob{
  //defines size of the blob
  float bHeight; 
  float bWidth;
  float bSize; 
  
  float speed;
  color bColor;
  
  //defines the position of the blob
  float xBlob = 0;
  float yBlob = 0;
  
  //lets the programme know if the blob is moving vertically up/down on the game field or horizontal left/right on the game field
  boolean isVertical = false;
  boolean isHorizontal = false;
  
  //initialises a new blob, assigning it a random size, colour and speed
  Blob(){
    //creates a larger proportion of smaller blobs before player has eaten anything
    if (playerSize < 20){
      bHeight =  random(5,50);
      bWidth = bHeight;
    }
    else {
      bHeight =random(5,200);
      bWidth = bHeight + random(-5,5);
    }
    
    bSize = 3 * ((bHeight/2) * (bHeight/2));
    speed = (random(1,4))*2;
    bColor = color(random(230,255),random(230,255),random(230,255), random(200,250));
  }
  
  //movement logic for the blob
  void blobMove() {
    
    if (isVertical == true){
      yBlob += speed;
    }
    
    else if (isHorizontal == true){
      xBlob += speed;
    }
  }
   
   //called when the timer runs out to spawn a new blob, mostly focuses on the movement and position of the blob rather than its basic size/shape properties
   void blobSpawn(){
     //two random booleans to pick the directions in which the blob is moving up/down/left/right and from what point it starts
     float a = random(0,1);
     float b =random (0,1);
     if (a >= 0.5){
       isHorizontal = true;
       if (b >= 0){
         xBlob = width + 10;
         speed = -speed; //the negative speed allows the blob to move in the opposite direction
       }
       else{
         xBlob = 0;
       }
       yBlob = random(1,height);
     }
     else {
       isVertical = true;
       if (b >=0){
         yBlob = height + 10;
         speed = -speed;
       }
       else{
         yBlob = 0;
       }
       xBlob =random(1,width);
     }
  }
  
} //end blob class





//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Collision Class~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\\
class Collision {
  float pointX;
  float pointY;

  //function that runs through all the functions in this class as required.
  void collide(ArrayList<Blob> blobs, float boxX,float boxY, float w, float h, int boxSize){
     for (int i = 0; i<blobs.size(); i++){
       pointY =blobs.get(i).yBlob;
       pointX =  blobs.get(i).xBlob;
     
       //handles what happens when the player eats other blobs or is eaten by them.
       if (collisionPlayer(pointX, pointY, (blobs.get(i).bHeight/2), w , h, boxX, boxY)){
         if(isEaten(boxSize, (int) blobs.get(i).bSize)){
           lives -= 1;
           score -= 10;
           death.rewind();
           death.play();
           xPos = width/2;
           yPos = height/2;
           velX = 0;
           velY = 0;
           invincibilityTimer = millis() + 1500;
         }
         else {
           eat.rewind();
           eat.play();
           score += blobs.get(i).bSize;
           playerSize += 2;
           playerWidth += 3;
           blobs.remove(i);
         }
       }
     }
   }

 
   //checks if a cloud is colliding with a player given the x/y coordinate of the circle center, the hieght and width of th eplayer hit box and the player's x/y coordinates.
   boolean collisionPlayer(float centerX, float centerY, float r, float w, float h, float posX, float posY){
     if (abs(r + w/2 + posX) < centerX || centerX < abs(posX - w/2 - r)) return false;
     if (abs(r + h/2 + posY) < centerY || centerY < abs(posY - h/2 -r)) return false;
     return true;
  }
 

  //compare size of blob hit to size of player, return true if blob is bigger than player, otherwise false
  boolean isEaten(int playerSize, int blobSize){
     if (playerSize < blobSize) {
      return true;
     }
     return false;
  }
} //end collision class





//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~Powerups Class~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\\
class Powerups{
  //powerup timers
  int powerTimer = 5000; //keeps track of how long it takes until next powerup spawns
  int powerIndex; //keeps track of which power up has spawned
  int powerLife; //timer that keeps powerup in game for about 8s before making it disappear
  
  //power up placement
  float powerX;
  float powerY;
  int pSize = 15;
  
  //power up colour
  PImage powerC;
  
  
  //power up functions - effect of each power up
  void startShield(){
    invincibilityTimer = millis() + 2000;
  }
  
  void speedUp(){
    maxSpeed += 2;
  }
  
  void speedDown(){
    if (maxSpeed > 2){
      maxSpeed -= 2;
    }
  }
  
  void moreBlobs(){
    maxSpawnRate -= 50;
  }
  
  void lessBlobs(){
    maxSpawnRate += 100;
  }
  
  //spawns the powerups and resets the timers
  void powerupSpawn(){
    if (powerTimer < millis()){
      powerIndex = (int) random(0,5);
      switch(powerIndex){
        case 0: powerC = powerups[2]; break;
        case 1: powerC = powerups[3]; break;
        case 2: powerC = powerups[4]; break;
        case 3: powerC = powerups[0]; break;
        case 4: powerC = powerups[1]; break;
        default: System.out.println("error occured o switch"); break;
      }
      powerX = random(0,width);
      powerY = random(0,height);
      powerTimer = millis() + 20000 + (int)random(0,1000);
      powerLife = millis() + 8000;
    }
  }
  
  //redraws the power up each frame until the timer runs out and checks for collision, runs the reaction function if the player hits the powerup
  void powerupLife(){
    if(powerLife > millis()){
      tint(255,255,255);
      image(powerC, powerX, powerY, pSize,pSize);
      if(collision.collisionPlayer(powerX, powerY, pSize/2, playerWidth,  playerSize ,xPos , yPos)){
        pickup.rewind();
        pickup.play();
        switch(powerIndex){
        case 0: startShield(); break;
        case 1: speedUp(); break;
        case 2: speedDown(); break;
        case 3: moreBlobs(); break;
        case 4: lessBlobs(); break;
        default: System.out.println("error occured on switch"); break;
        
      }
      powerLife = millis();
      }
    }
  }
  
  
} //end power up class