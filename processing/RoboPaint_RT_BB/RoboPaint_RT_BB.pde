/*
  RoboPaint RT "BB" -- Special edition for use with the original Buddha Board (http://www.buddhaboard.com), 
 for water painting.
 
 Real-time painting software for WaterColorBot
 
 https://github.com/evil-mad/robopaint-rt 
 
 
 
 */

import de.looksgood.ani.*;
import processing.serial.*;

import javax.swing.UIManager; 
import javax.swing.JFileChooser; 


// User Settings: 
float MotorSpeed = 1500.0;  // Steps per second, 1500 default

int ServoUpPct = 70;    // Brush UP position, %  (higher number lifts higher). 
int ServoPaintPct = 30;    // Brush DOWN position, %  (higher number lifts higher). 
int ServoWashPct = 20;    // Brush DOWN position for washing brush, %  (higher number lifts higher). 

boolean reverseMotorX = false;
boolean reverseMotorY = false;

int delayAfterRaisingBrush = 300; //ms
int delayAfterLoweringBrush = 300; //ms

int ColorFadeDist = 750;     // How slowly paint "fades" when drawing (higher number->Slower fading)
int ColorFadeStart = 200;     // How far you can paint before paint "fades" when drawing 

int minDist = 4; // Minimum drag distance to record

//boolean debugMode = true;
boolean debugMode = false;


// Offscreen buffer images for holding drawn elements, makes redrawing MUCH faster

PGraphics offScreen;

PImage imgBackground;   // Stores background data image only.
PImage imgMain;         // Primary drawing canvas
PImage imgLocator;      // Cursor crosshairs
PImage imgButtons;      // Text buttons
PImage imgHighlight;
String BackgroundImageName = "background.png"; 
String HelpImageName = "help.png"; 

float ColorDistance;
boolean segmentQueued = false;
int queuePt1 = -1;
int queuePt2 = -1;

//float MotorStepsPerPixel =  16.75;  // For use with 1/16 steps
float MotorStepsPerPixel = 8.36;// Good for 1/8 steps-- standard behavior.
int xMotorPaperOffset =  1400;  // For 1/8 steps  Use 2900 for 1/16?

// Positions of screen items

float paintSwatchX = 108.8;
float paintSwatchY0 = 84.5;
float paintSwatchyD = 54.55;
int paintSwatchOvalWidth = 64;
int paintSwatchOvalheight = 47;

int WaterDishX = 2;
int WaterDishY0 = 88;
float WaterDishyD = 161.25;
int WaterDishDia = 118;

int MousePaperLeft =  185;
int MousePaperRight =  769;
int MousePaperTop =  62;
int MousePaperBottom =  488;

int xMotorOffsetPixels = 0;  // Corrections to initial motor position w.r.t. lower plate (paints & paper)
int yMotorOffsetPixels = 4 ;


int xBrushRestPositionPixels = 18;     // Brush rest position, in pixels
int yBrushRestPositionPixels = MousePaperTop + yMotorOffsetPixels;

int ServoUp;    // Brush UP position, native units
int ServoPaint;    // Brush DOWN position, native units. 
int ServoWash;    // Brush DOWN position, native units

int MotorMinX;
int MotorMinY;
int MotorMaxX;
int MotorMaxY;

color[] paintset = new color[9]; 

color Brown =  color(139, 69, 19);  //brown
color Purple = color(148, 0, 211);  // Purple
color Blue = color(0, 0, 255);  // BLUE
color Green = color(0, 128, 0); // GREEN
color Yellow = color(255, 255, 0);  // YELLOW
color Orange = color(255, 140, 0);  // ORANGE
color Red = color(255, 0, 0);  // RED
color Black = color(25, 25, 25);  // BLACK
color Water = color(230, 230, 255);  // BLUE 

boolean firstPath;
boolean doSerialConnect = true;
boolean SerialOnline;
Serial myPort;  // Create object from Serial class
int val;        // Data received from the serial port

boolean BrushDown;
boolean BrushDownAtPause;
boolean DrawingPath = false;

int xLocAtPause;
int yLocAtPause;

int MotorX;  // Position of X motor
int MotorY;  // Position of Y motor
int MotorLocatorX;  // Position of motor locator
int MotorLocatorY; 
int lastPosition; // Record last encoded position for drawing

int selectedColor;
int selectedWater;
int highlightedWater;
int highlightedColor; 

int brushColor;

boolean recordingGesture;
boolean forceRedraw;
boolean shiftKeyDown;
boolean keyup = false;
boolean keyright = false;
boolean keyleft = false;
boolean keydown = false;
boolean hKeyDown = false;
int lastButtonUpdateX = 0;
int lastButtonUpdateY = 0;


color color_for_new_ToDo_paths = Black;
//color lastColor_DrawingPath = Water;
boolean lastBrushDown_DrawingPath;
int lastX_DrawingPath;
int lastY_DrawingPath;


int NextMoveTime;          //Time we are allowed to begin the next movement (i.e., when the current move will be complete).
int SubsequentWaitTime = -1;    //How long the following movement will take.
int UIMessageExpire;
int raiseBrushStatus;
int lowerBrushStatus;
int moveStatus;
int MoveDestX;
int MoveDestY; 
int getWaterStatus;
int WaterDest;
boolean WaterDestMode;
int PaintDest; 

int CleaningStatus;
int getPaintStatus; 
boolean Paused;


int ToDoList[];  // Queue future events in an integer array; executed when PriorityList is empty.
int indexDone;    // Index in to-do list of last action performed
int indexDrawn;   // Index in to-do list of last to-do element drawn to screen


// Active buttons
PFont font_ML16;
PFont font_CB; // Command button font
PFont font_url;


int TextColor = 75;
int LabelColor = 150;
color TextHighLight = Black;
int DefocusColor = 175;

SimpleButton pauseButton;
SimpleButton brushUpButton;
SimpleButton brushDownButton;
SimpleButton cleanButton;
SimpleButton parkButton;
SimpleButton motorOffButton;
SimpleButton motorZeroButton;
SimpleButton clearButton;
SimpleButton replayButton;
SimpleButton urlButton;
SimpleButton openButton;
SimpleButton saveButton;


SimpleButton brushLabel;
SimpleButton motorLabel;
SimpleButton UIMessage;

void setup() 
{
  size(800, 519);

  Ani.init(this); // Initialize animation library
  Ani.setDefaultEasing(Ani.LINEAR);


  firstPath = true;

  offScreen = createGraphics(800, 519, JAVA2D);

  //// Allow frame to be resized?
  //  if (frame != null) {
  //    frame.setResizable(true);
  //  }

  frame.setTitle("RoboPaint RT BB");

  shiftKeyDown = false;

  frameRate(60);  // sets maximum speed only


  paintset[0] = Black;
  paintset[1] = Red;
  paintset[2] = Orange;
  paintset[3] = Yellow;
  paintset[4] = Green;
  paintset[5] = Blue;
  paintset[6] = Purple;
  paintset[7] = Brown;
  paintset[8] = Water;

  MotorMinX = 0;
  MotorMinY = 0;
  MotorMaxX = int(floor(xMotorPaperOffset + float(MousePaperRight - MousePaperLeft) * MotorStepsPerPixel)) ;
  MotorMaxY = int(floor(float(MousePaperBottom - MousePaperTop) * MotorStepsPerPixel)) ;

  lastPosition = -1;

  //  if (debugMode) {
  //    println("MotorMinX: " + MotorMinX + "  MotorMinY: " + MotorMinY);
  //    println("MotorMaxX: " + MotorMaxX + "  MotorMaxY: " + MotorMaxY);
  //  }


  ServoUp = 7500 + 175 * ServoUpPct;    // Brush UP position, native units
  ServoPaint = 7500 + 175 * ServoPaintPct;   // Brush DOWN position, native units. 
  ServoWash = 7500 + 175 * ServoWashPct;     // Brush DOWN position, native units




  // Button setup

  font_ML16  = loadFont("Miso-Light-16.vlw"); 
  font_CB = loadFont("Miso-20.vlw"); 

  font_url = loadFont("Zar-casual-16.vlw"); 


  int xbutton = MousePaperLeft;
  int ybutton = MousePaperBottom + 20;

  pauseButton = new SimpleButton("Pause", xbutton, MousePaperBottom + 20, font_CB, 20, TextColor, TextHighLight);
  xbutton += 60; 

  brushLabel = new SimpleButton("Brush:", xbutton, ybutton, font_CB, 20, LabelColor, LabelColor);
  xbutton += 45;
  brushUpButton = new SimpleButton("Up", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 22;
  brushDownButton = new SimpleButton("Down", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 44;

  cleanButton = new SimpleButton("Clean", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 44;
  parkButton = new SimpleButton("Park", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 60;

  motorLabel = new SimpleButton("Motors:", xbutton, ybutton, font_CB, 20, LabelColor, LabelColor);
  xbutton += 55;
  motorOffButton = new SimpleButton("Off", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 30;
  motorZeroButton = new SimpleButton("Zero", xbutton, ybutton, font_CB, 20, TextColor, TextHighLight);
  xbutton += 70;
  clearButton = new SimpleButton("Clear All", xbutton, MousePaperBottom + 20, font_CB, 20, TextColor, TextHighLight);
  xbutton += 80;
  replayButton = new SimpleButton("Replay All", xbutton, MousePaperBottom + 20, font_CB, 20, TextColor, TextHighLight);

  xbutton = MousePaperLeft - 30;   
  ybutton =  30;

  openButton = new SimpleButton("Open File", xbutton, ybutton, font_url, 16, LabelColor, TextHighLight); 
  xbutton += 80;
  saveButton = new SimpleButton("Save File", xbutton, ybutton, font_url, 16, LabelColor, TextHighLight);

  xbutton = 655;

  urlButton = new SimpleButton("WaterColorBot.com", xbutton, ybutton, font_url, 16, LabelColor, TextHighLight);

  UIMessage = new SimpleButton("Welcome to RoboPaint RT! Hold 'h' key for help!", 
  MousePaperLeft, MousePaperTop - 5, font_CB, 20, LabelColor, LabelColor);




  UIMessage.label = "Searching For WaterColorBot... ";
  UIMessageExpire = millis() + 25000; 

  rectMode(CORNERS);


  MotorX = 0;
  MotorY = 0; 

  ToDoList = new int[0];
  ToDoList = append(ToDoList, -35);  // Command code: Go home (0,0)

  indexDone = -1;    // Index in to-do list of last action performed
  indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen

  highlightedWater = 8;
  highlightedColor = 8;
  selectedColor = 8; // No color selected, to begin with
  selectedWater = 8; // No water selected, to begin with
  brushColor = 8; // No paint on brush yet.  Use value 8, "water"
  ColorDistance = 0;


  raiseBrushStatus = -1;
  lowerBrushStatus = -1; 
  moveStatus = -1;
  MoveDestX = -1;
  MoveDestY = -1;

  WaterDest = -1;
  WaterDestMode = false;

  PaintDest = -1; 
  getWaterStatus = -1;
  CleaningStatus = -1;
  getPaintStatus = -1; 

  Paused = false;
  BrushDownAtPause = false;

  // Set initial position of indicator at carriage minimum 0,0
  int[] pos = getMotorPixelPos();

  background(255);
  MotorLocatorX = pos[0];
  MotorLocatorY = pos[1];

  NextMoveTime = millis();
  imgBackground = loadImage(BackgroundImageName);  // Load the image into the program  
  drawToDoList();
  redrawButtons();
  redrawHighlight();
  redrawLocator();
}


void pause()
{
  pauseButton.displayColor = TextColor;
  if (Paused)
  {
    Paused = false;
    pauseButton.label = "Pause";


    if (BrushDownAtPause)
    {
      int waitTime = NextMoveTime - millis();
      if (waitTime > 0)
      { 
        delay (waitTime);  // Wait for prior move to finish:
      }

      if (BrushDown) { 
        raiseBrush();
      }

      waitTime = NextMoveTime - millis();
      if (waitTime > 0)
      { 
        delay (waitTime);  // Wait for prior move to finish:
      }

      MoveToXY(xLocAtPause, yLocAtPause);

      waitTime = NextMoveTime - millis();
      if (waitTime > 0)
      { 
        delay (waitTime);  // Wait for prior move to finish:
      }

      lowerBrush();
    }
  }
  else
  {
    Paused = true;
    pauseButton.label = "Resume";
    //TextColor


    if (BrushDown) {
      BrushDownAtPause = true; 
      raiseBrush();
    }
    else
      BrushDownAtPause = false;

    xLocAtPause = MotorX;
    yLocAtPause = MotorY;
  }

  redrawButtons();
}

boolean serviceBrush()
{
  // Manage processes of getting paint, water, and cleaning the brush,
  // as well as general lifts and moves.  Ensure that we allow time for the
  // brush to move, and wait respectfully, without local wait loops, to
  // ensure good performance for the artist.

  // Returns true if servicing is still taking place, and false if idle.

  boolean serviceStatus = false;

  int waitTime = NextMoveTime - millis();
  if (waitTime >= 0)
  {
    serviceStatus = true;
    // We still need to wait for *something* to finish!
  }
  else {
    if (raiseBrushStatus >= 0)
    {
      raiseBrush();
      serviceStatus = true;
    }
    else if (lowerBrushStatus >= 0)
    {
      lowerBrush();
      serviceStatus = true;
    } 
    else if (moveStatus >= 0) {
      MoveToXY(); // Perform next move, if one is pending.
      serviceStatus = true;
    }
    else if (getWaterStatus >= 0) {
      getWater(); // Advance to next step of getting water
      serviceStatus = true;
    }
    else if (CleaningStatus >= 0) {
      cleanBrush(); // Advance to next cleaning step
      serviceStatus = true;
    }
    else if (getPaintStatus >= 0)
    {
//      getPaint(); // Advance to next paint-getting step
      serviceStatus = true;
    }
  }
  return serviceStatus;
}


void drawToDoList()
{  
  // Erase all painting on main image background, and draw the existing "ToDo" list
  // on the off-screen buffer.

  int j = ToDoList.length;
  int x1, x2, y1, y2;
  int intTemp = -100;

  color interA;
  float brightness;
  color white = color(255, 255, 255);

  if ((indexDrawn + 1) < j)
  {

    // Ready the offscreen buffer for drawing onto
    offScreen.beginDraw();

    if (indexDrawn < 0)
      offScreen.image(imgBackground, 0, 0);  // Copy original background image into place!
    else
      offScreen.image(imgMain, 0, 0);


    offScreen.strokeWeight(10); 
    offScreen.stroke(color_for_new_ToDo_paths);

    x1 = 0;
    y1 = 0;

    while ( (indexDrawn + 1) < j) {

      indexDrawn++;  
      // NOTE:  We increment the "Drawn" count here at the beginning of the loop,
      //        momentarily indicating (somewhat inaccurately) that the so-numbered
      //        list element has been drawn-- really, we're in the process of drawing it,
      //        and everything will be back to accurate once we're outside of the loop.


      intTemp = ToDoList[indexDrawn];

      if (intTemp >= 0)
      {  // Preview a path segment

        x2 = floor(intTemp / 10000);
        y2 = intTemp - 10000 * x2; 

        if (DrawingPath)
          if ((x1 + y1) == 0)    // first time through the loop
          {
            intTemp = ToDoList[indexDrawn - 1];
            if (intTemp >= 0)
            {  // first point on this segment can be taken from history!

              x1 = floor(intTemp / 10000);
              y1 = intTemp - 10000 * x1;
            }
          }

        if (DrawingPath == false) {  // Just starting a new path
          DrawingPath = true;
          x1 = x2;
          y1 = y2;
        }

        if (color_for_new_ToDo_paths == Water)
          interA = Water;
        else {
          //    interA = lerpColor(color_for_new_ToDo_paths, white, .55);

          if (ColorDistance <  ColorFadeStart)
            brightness = 0.3;
          else if (ColorDistance < (ColorFadeStart + ColorFadeDist))
            brightness = 0.3 + 0.6 * ((ColorDistance - ColorFadeStart) /ColorFadeDist);
          else
            brightness = 0.9;

          interA = lerpColor(color_for_new_ToDo_paths, white, brightness);
        }

        offScreen.stroke(interA);
        offScreen.line(x1, y1, x2, y2); 
        ColorDistance += getDistance(x1, y1, x2, y2); 

        x1 = x2;
        y1 = y2;
      }
      else
      {    // intTemp < 0, so we are doing something else.
        intTemp = -1 * intTemp;
        DrawingPath = false;

        if ((intTemp > 9) && (intTemp < 20)) 
        {  // Change paint color 
          intTemp -= 10; 
          color_for_new_ToDo_paths = paintset[intTemp];
          offScreen.stroke(paintset[intTemp]);
          //        ColorDistance = 0;
        }

        else if (intTemp == 40) 
        {  // Clean brush
//          offScreen.stroke(paintset[8]); // Water color!
          offScreen.stroke(paintset[0]); // Black color!
          
          
        }
        else if (intTemp == 30) 
        {  
          lastBrushDown_DrawingPath = false;
        }
        else if (intTemp == 31) 
        {  // Lower brush
          lastBrushDown_DrawingPath = true;
        }
      }
    }

    offScreen.endDraw();

    imgMain = offScreen.get(0, 0, offScreen.width, offScreen.height);
  }
}

void queueSegmentToDraw(int prevPoint, int newPoint)
{
  segmentQueued = true;
  queuePt1 = prevPoint;
  queuePt2 = newPoint;
}


void drawQueuedSegment()
{    // Draw new "done" segment, on the off-screen buffer.

  int x1, x2, y1, y2;  
  color interA;
  float brightness;

  if (segmentQueued)
  {
    segmentQueued = false;

    offScreen.beginDraw();     // Ready the offscreen buffer for drawing
    offScreen.image(imgMain, 0, 0);
    offScreen.strokeWeight(14); 

    interA = paintset[brushColor];

    if (interA != Water) {
      brightness = 0.25;
      color white = color(255, 255, 255);
      interA = lerpColor(interA, white, brightness);
    }

    offScreen.stroke(interA);

    x1 = floor(queuePt1 / 10000);
    y1 = queuePt1 - 10000 * x1;

    x2 = floor(queuePt2 / 10000);
    y2 = queuePt2 - 10000 * x2;  

    offScreen.line(x1, y1, x2, y2); 

    offScreen.endDraw();

    imgMain = offScreen.get(0, 0, offScreen.width, offScreen.height);
  }
}



void draw() {

  if (debugMode)
  {
    frame.setTitle("RoboPaint RT      " + int(frameRate) + " fps");
  }

  drawToDoList();

  // NON-DRAWING LOOP CHECKS ==========================================

  if (doSerialConnect == false)
    checkServiceBrush(); 


  checkHighlights();

  if (UIMessage.label != "")
    if (millis() > UIMessageExpire) {

      UIMessage.displayColor = lerpColor(UIMessage.displayColor, color(242), .5);
      UIMessage.highlightColor = UIMessage.displayColor;

      if (millis() > (UIMessageExpire + 500)) { 
        UIMessage.label = "";
        UIMessage.displayColor = LabelColor;
      }
      redrawButtons();
    }


  // ALL ACTUAL DRAWING ==========================================

  if  (hKeyDown)
  {  // Help display
    image(loadImage(HelpImageName), 0, 0);
  }
  else
  {

    image(imgMain, 0, 0, width, height);    // Draw Background image  (incl. paint paths)

    // Draw buttons image
    image(imgButtons, 0, 0);

    // Draw highlight image
    image(imgHighlight, 0, 0);

    // Draw locator crosshair at xy pos, less crosshair offset
    image(imgLocator, MotorLocatorX-10, MotorLocatorY-15);
  }


  if (doSerialConnect)
  {
    // FIRST RUN ONLY:  Connect here, so that 

      doSerialConnect = false;

    scanSerial();

    if (SerialOnline)
    {    
      myPort.write("EM,2\r");  //Configure both steppers to 1/8 step mode

        // Configure brush lift servo endpoints and speed
      myPort.write("SC,4," + str(ServoPaint) + "\r");  // Brush DOWN position, for painting
      myPort.write("SC,5," + str(ServoUp) + "\r");  // Brush UP position 

      //    myPort.write("SC,10,255\r"); // Set brush raising and lowering speed.
      myPort.write("SC,10,65535\r"); // Set brush raising and lowering speed.


      // Ensure that we actually raise the brush:
      BrushDown = true;  
      raiseBrush();    

      UIMessage.label = "Welcome to RoboPaint RT!  Hold 'h' key for help!";
      UIMessageExpire = millis() + 5000;
      println("Now entering interactive painting mode.\n");
      redrawButtons();
    }
    else
    { 
      println("Now entering offline simulation mode.\n");

      UIMessage.label = "WaterColorBot not found.  Entering Simulation Mode. ";
      UIMessageExpire = millis() + 5000;
      redrawButtons();
    }
  }
}

// Only need to redraw if hovering or changing state
void redrawButtons() {


  offScreen.beginDraw();
  offScreen.background(0, 0);

  DrawButtons(offScreen);

  offScreen.endDraw();

  imgButtons = offScreen.get(0, 0, offScreen.width, offScreen.height);
}


// Only need to redraw if hovering or change select on specific items
void redrawHighlight() {
  offScreen.beginDraw();
  offScreen.background(0, 0);

  // Indicate Highlighted Color or Water Dish:

  if ((highlightedWater >= 0)  && (highlightedWater < 8)) {
    // Indicate which water dish is highlighted
    offScreen.stroke(0, 0, 255, 50);
    offScreen.strokeWeight(15); 
    offScreen.noFill(); 
    offScreen.ellipse(WaterDishX, WaterDishY0 + highlightedWater * WaterDishyD, WaterDishDia, WaterDishDia);
  }


  // Indicate Selected Color or Water Dish: 
  if ((selectedWater >= 0)  && (selectedWater < 8)) {

    // Indicate which water dish is selected
    offScreen.stroke(0, 0, 255, 128);
    offScreen.strokeWeight(7); 
    offScreen.noFill(); 
    offScreen.ellipse(WaterDishX, WaterDishY0 + selectedWater * WaterDishyD, WaterDishDia, WaterDishDia);
  }

  //  if ((selectedColor >= 0)  && (selectedColor < 8)) {
  //    // Indicate which color is selected
  //    offScreen.stroke(0, 0, 0, 100);  
  //    offScreen.strokeWeight(4); 
  //    offScreen.noFill(); 
  //    offScreen.ellipse(paintSwatchX, paintSwatchY0 + selectedColor * paintSwatchyD, paintSwatchOvalWidth, paintSwatchOvalheight);
  //  }

  offScreen.endDraw();
  imgHighlight = offScreen.get(0, 0, offScreen.width, offScreen.height);
}


// Draw the locator crosshair to the offscreen buffer and fill imgLocator with it
// Only need to redraw this when it changes color
void redrawLocator() {
  offScreen.beginDraw();
  offScreen.background(0, 0);

  offScreen.stroke(0, 0, 0, 128); 
  offScreen.strokeWeight(2);  
  int x0 = 10;
  int y0 = 10; 

  if (BrushDown)
    offScreen.fill(paintset[brushColor]);
  else
    offScreen.noFill();

  offScreen.ellipse(x0, y0, 10, 10);

  offScreen.line(x0 + 5, y0, x0 + 10, y0);
  offScreen.line(x0 - 5, y0, x0 - 10, y0);
  offScreen.line(x0, y0 + 5, x0, y0 + 10);
  offScreen.line(x0, y0 - 5, x0, y0 - 10);
  offScreen.endDraw();

  imgLocator = offScreen.get(0, 0, 25, 25);
}

void mousePressed() {
  int i;
  int x1, x2, y1, y2;
  boolean doHighlightRedraw = false;

  //The mouse button was just pressed!  Let's see where the user clicked!

  if (highlightedWater >= 0)            // First, check if we are over water dishes:
  {
    selectedWater = highlightedWater;
    selectedColor = 0; //  Select BLACK color paint. [[WAS: 8: deselect color paint ]]

    i = -1 * (selectedWater + 20); 
    ToDoList = append(ToDoList, i);
    doHighlightRedraw = true;

    //    ColorDistance += ColorFadeDist/3;
    ColorDistance = 0;      // FOR RT BB ONLY
    selectedColor = highlightedColor;
    selectedWater = 8; // Deselect water dish
    brushColor = 0;
    
  }
  else  if ((mouseX >= MousePaperLeft) && (mouseX <= MousePaperRight) && (mouseY >= MousePaperTop) && (mouseY <= MousePaperBottom))
  {  // Begin recording gesture   // Over paper!
    recordingGesture = true;

    //  ***TODO
    // If just beginning and no color has yet selected, get water before beginning. 

    if (firstPath)
    {
      if (brushColor == 8)
      { 
        getWater(2, false);   // Brush is clean.  Dip in the clean water.
      }  
      firstPath = false;
    }


    ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)  (Only has an effect if the brush is already down.)

    ToDoList = append(ToDoList, xyEncodeInt2());    // Command Code: Move to first (X,Y) point
    ToDoList = append(ToDoList, -31);              // Command Code:  -31 (lower brush)
    doHighlightRedraw = true;
  }

  if (doHighlightRedraw) {
    redrawLocator();
    redrawHighlight();
  }


  if ( pauseButton.isSelected() )  
    pause(); 
  else if ( brushUpButton.isSelected() )  
  {

    if (Paused)
      raiseBrush();
    else
      ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)
  }
  else if ( brushDownButton.isSelected() ) {

    if (Paused)
      lowerBrush();
    else
      ToDoList = append(ToDoList, -31);   // Command Code:  -31 (lower brush)
  }
  else if ( cleanButton.isSelected() )  
  {

    if (Paused)
      cleanBrush();
    else
      ToDoList = append(ToDoList, -40);   // Command Code:  -40 (clean brush)

//    color_for_new_ToDo_paths = Water;
  } 
  else if (urlButton.isSelected()) {
    link("http://watercolorbot.com");
  } 
  else if ( parkButton.isSelected() )  
  {

    if (Paused)
    { 
      raiseBrush();
      MoveToXY(0, 0);
    }
    else
    {
      ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)
      ToDoList = append(ToDoList, -35);  // Command code: Go home (0,0)
    }
  }
  else if ( motorOffButton.isSelected() )  
    MotorsOff();    
  else if ( motorZeroButton.isSelected() )  
    zero();      
  else if ( clearButton.isSelected() )  
  {  // ***** CLEAR ALL *****

    ToDoList = new int[0];
    //    ToDoList = append(ToDoList, -1 * (brushColor + 10));

    ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)
    ToDoList = append(ToDoList, -35);  // Command code: Go home (0,0)

    indexDone = -1;    // Index in to-do list of last action performed
    indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen

    drawToDoList();

    Paused = true; 
    pause();
  }  
  else if ( replayButton.isSelected() )  
  {
    // Clear indexDone to "zero" (actually, -1, since even element 0 is not "done.")   & redraw to-do list.

    indexDone = -1;    // Index in to-do list of last action performed
    indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen

    drawToDoList();
  }
  else if ( saveButton.isSelected() )  
  {
    // Save file with dialog #####
    selectOutput("Output .rrt file name:", "SavefileSelected");
  }
  else if ( openButton.isSelected() )  
  {
    // Open file with dialog #####
    selectInput("Select a RoboPaint RT (.rrt) file to open:", "fileSelected");  // Opens file chooser
  }
}




void SavefileSelected(File selection) {    // SAVE FILE
  if (selection == null) {
    // If a file was not selected
    println("No output file was selected...");
    //       ErrorDisplay = "ERROR: NO FILE NAME CHOSEN.";

    UIMessage.label = "File not saved (reason: no file name chosen).";
    UIMessageExpire = millis() + 3000;
  } 
  else { 

    String[] FileOutput; 
    //        String rowTemp;

    String savePath = selection.getAbsolutePath();
    String[] p = splitTokens(savePath, ".");
    boolean fileOK = false;

    FileOutput = new String[0];

    if ( p[p.length - 1].equals("RRT"))
      fileOK = true;
    if ( p[p.length - 1].equals("rrt"))
      fileOK = true;      
    if (fileOK == false)
      savePath = savePath + ".rrt";

    // If a file was selected, print path to folder 
    println("Save file: " + savePath); 

    int listLength = ToDoList.length; 
    for ( int i = 0; i < listLength; ++i) {

      FileOutput = append(FileOutput, str(ToDoList[i]));
    } 

    saveStrings(savePath, FileOutput);

    UIMessage.label = "File Saved!";
    UIMessageExpire = millis() + 3000;


    //    ErrorDisplay = "SAVING FILE...";
  }
}



void fileSelected(File selection) {    // LOAD (OPEN) FILE
  if (selection == null) {
    println("Window was closed or the user hit cancel.");

    UIMessage.label = "File not loaded (reason: no file selected).";
    UIMessageExpire = millis() + 3000;
  } 
  else {
    //println("User selected " + selection.getAbsolutePath());

    String loadPath = selection.getAbsolutePath();

    // If a file was selected, print path to file 
    println("Loaded file: " + loadPath); 

    String[] p = splitTokens(loadPath, ".");
    boolean fileOK = false;
    int todoNew;


    if ( p[p.length - 1].equals("RRT"))
      fileOK = true;
    if ( p[p.length - 1].equals("rrt"))
      fileOK = true;      

    println("File OK: " + fileOK); 

    if (fileOK) {

      String lines[] = loadStrings(loadPath);


      Paused = false;
      pause();
      pauseButton.label = "BEGIN";
      pauseButton.displayColor = color(200, 0, 0);


      // Clear indexDone to "zero" (actually, -1, since even element 0 is not "done.")   & redraw to-do list.

      ToDoList = new int[0];   
      indexDone = -1;    // Index in to-do list of last action performed
      indexDrawn = -1;   // Index in to-do list of last to-do element drawn to screen

      drawToDoList();

      println("there are " + lines.length + " lines");
      for (int i = 0 ; i < lines.length; i++) { 
        todoNew = parseInt(lines[i]);
        //        println(str(todoNew));
        ToDoList = append(ToDoList, todoNew);
      }
    }
    else {
      // Can't load file
      //      ErrorDisplay = "ERROR: BAD FILE TYPE";
    }
  }
}










void mouseDragged() { 

  int i, j;
  int posOld, posNew;
  int tempPos;

  boolean addpoint = false;
  float distTemp = 0;

  if (recordingGesture)
  { 
    posNew = xyEncodeInt2();

    i = ToDoList.length; 

    if (i > 1)
    {
      posOld = ToDoList[i - 1];

      if (posOld != posNew) {  // Avoid adding duplicate points to ToDoList!

        addpoint = true;
        distTemp = getDistance(posOld, posNew) ;
        // Only add points that are some minimum distance away from each other 
        if (distTemp < minDist) {  
          addpoint = false;
        }  

        if (addpoint)
          ToDoList = append(ToDoList, posNew);  // Command code: XY coordinate pair
      }
    }
    else
    { // List length may be zero. 
      ToDoList = append(ToDoList, posNew);  // Command code: XY coordinate pair
    }
  }
}


void mouseReleased() {
  if (recordingGesture)
  {   
    recordingGesture = false; 
    ToDoList = append(ToDoList, -30);   // Command Code:  -30 (raise brush)
  }
}


void keyReleased()
{

  if (key == CODED) {

    if (keyCode == UP) keyup = false; 
    if (keyCode == DOWN) keydown = false; 
    if (keyCode == LEFT) keyleft = false; 
    if (keyCode == RIGHT) keyright = false; 

    if (keyCode == SHIFT) { 

      shiftKeyDown = false;
    }
  }

  if ( key == 'h')  // display help
  {
    hKeyDown = false;
  }
}



void keyPressed()
{

  int nx = 0;
  int ny = 0;

  if (key == CODED) {

    // Arrow keys are used for nudging, with or without shift key.

    if (keyCode == UP) 
    {
      keyup = true;
    }
    if (keyCode == DOWN)
    { 
      keydown = true;
    }
    if (keyCode == LEFT) keyleft = true; 
    if (keyCode == RIGHT) keyright = true; 
    if (keyCode == SHIFT) shiftKeyDown = true;
  }
  else
  {

    if ( key == 'b')   // Toggle brush up or brush down with 'b' key
    {
      if (BrushDown)
        raiseBrush();
      else
        lowerBrush();
    }

    if ( key == 'z')  // Zero motor coordinates
      zero();

    if ( key == ' ')  //Space bar: Pause
      pause();

    if ( key == 'q')  // Move home (0,0)
    {
      raiseBrush();
      MoveToXY(0, 0);
    }


    if ( key == 'h')  // display help
    {
      hKeyDown = true;
    }


    if ( key == 't')  // Disable motors, to manually move carriage.  
      MotorsOff();

    if ( key == '1')
      MotorSpeed = 100;  
    if ( key == '2')
      MotorSpeed = 250;        
    if ( key == '3')
      MotorSpeed = 500;        
    if ( key == '4')
      MotorSpeed = 750;        
    if ( key == '5')
      MotorSpeed = 1000;        
    if ( key == '6')
      MotorSpeed = 1250;        
    if ( key == '7')
      MotorSpeed = 1500;        
    if ( key == '8')
      MotorSpeed = 1750;        
    if ( key == '9')
      MotorSpeed = 2000;
  }
}

