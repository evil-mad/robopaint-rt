/**
 * RoboPaint RT - watercolorbot control functions
 */



void raiseBrush() 
{  
  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    raiseBrushStatus = 1; // Flag to raise brush when no longer busy.
  }
  else
  {
    if (BrushDown == true) {
      if (SerialOnline) {
        myPort.write("SP,0\r");           
        BrushDown = false;
        NextMoveTime = millis() + delayAfterRaisingBrush;
      }
      //      if (debugMode) println("Raise Brush.");
    }
    raiseBrushStatus = -1; // Clear flag.
  }
}



void ConfigBrushDownHeight(int state) 
{ 
  // State 0: Wash      ConfigBrushDownHeight(0);// Set Brush to WASH height
  // State 1: Paint     ConfigBrushDownHeight(1);// Set Brush to PAINT height

  int position;

  if (state == 0)
    position = ServoWash;
  else
    position = ServoPaint;

  if (SerialOnline) {
    myPort.write("SC,4," + str(position) + "\r");  // Brush DOWN position
  }
}




void lowerBrush() 
{
  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    lowerBrushStatus = 1;  // Flag to lower brush when no longer busy.
    // delay (waitTime);  // Wait for prior move to finish:
  }
  else
  { 
    if  (BrushDown == false)
    {      
      if (SerialOnline) {
        myPort.write("SP,1\r");           // Lower Brush
        BrushDown = true;
        NextMoveTime = millis() + delayAfterLoweringBrush;
        lastPosition = -1;
      }
      //      if (debugMode) println("Lower Brush.");
    }
    lowerBrushStatus = -1; // Clear flag.
  }
}


void MoveRelativeXY(int xD, int yD)
{
  // Change carriage position by (xDelta, yDelta), with XY limit checking, time management, etc.

  int xTemp = MotorX + xD;
  int yTemp = MotorY + yD;

  MoveToXY(xTemp, yTemp);
}


void cleanBrush()
{ 


  if (CleaningStatus < 0)
  { 
    CleaningStatus = 0;
    ConfigBrushDownHeight(0);// Set Brush to WASH height

    getWater(0, true);
  }
  else if (CleaningStatus == 1)
  {
    CleaningStatus = 2;
    getWater(1, true);
  }
  else if (CleaningStatus == 3)
  {
    CleaningStatus = 4;
    getWater(2, true);
  } 
  else if (CleaningStatus == 5)
  {
    CleaningStatus = -1; 
    // Cleaning done. 

//    selectedColor = 8; // No color selected. 
//    brushColor = 8; // No paint on brush.  Use value 8, "water"
    redrawLocator();
    ConfigBrushDownHeight(1);// Set Brush to PAINT height

    //    selectedWater = 2;
  }
}  





void getWater(int waterDish, boolean washMode)
{

  WaterDest = waterDish;
  WaterDestMode = washMode; 

  if ((waterDish >= 0) && (waterDish <= 2))
  {
    getWaterStatus = 0;  // Begin getWater process
    getWater();
  }
  else 
    getWaterStatus = -1;
}


void getWater()
{

  int xC, yC;
  int yD;
  int waterDish = WaterDest;
  boolean washMode = WaterDestMode;

  int waitTime = NextMoveTime - millis();
  if (waitTime <= 0)
  { // If wait time is > 0, this section does not execute, and status is left unchanged.

    xC = 0; // Always use brush X rest position as over top water dish; x is not changed.
    yC = round((WaterDishY0 + waterDish * WaterDishyD - yBrushRestPositionPixels) * MotorStepsPerPixel);
    yD = round((WaterDishDia * MotorStepsPerPixel)/4);

    boolean done = false;

    if (getWaterStatus == 0)
      raiseBrush();
    else if (getWaterStatus == 1)   
      MoveToXY(xC, yC);  // Usually home position
    else if (getWaterStatus == 2)   
      lowerBrush();
    else if (washMode)
    { 
      if (getWaterStatus == 3) 
        MoveToXY(xC, yC + yD);  
      else if (getWaterStatus == 4) 
        MoveToXY(xC, yC); 
      else if (getWaterStatus == 5) 
        MoveToXY(xC, yC + yD);  
      else if (getWaterStatus == 6) 
        MoveToXY(xC, yC); 
      else if (getWaterStatus == 7) 
        raiseBrush();
      else if (getWaterStatus == 8) 
        lowerBrush();
      else if (getWaterStatus == 9) 
        MoveToXY(xC, yC + yD);  
      else if (getWaterStatus == 10) 
        MoveToXY(xC, yC); 
      else if (getWaterStatus == 11) 
        MoveToXY(xC, yC + yD);  
      else if (getWaterStatus == 12) 
        MoveToXY(xC, yC);
      else
        done = true;
    } 
    else 
      done = true;   

    if (done == true) {
      raiseBrush();

      getWaterStatus = -1;  // Flag that we are done.
      WaterDest = -1;
      
//      brushColor = 0;    // FOR RT BB ONLY: Label the paint color as BLACK now.
      redrawLocator();

      if (CleaningStatus >= 0)
        CleaningStatus += 1;  // If we are in a cleaning process, tell it that we've finished one dip.
    }
    else
      getWaterStatus += 1;
  }
}



/*
void getPaint(int paintColor)
{
  PaintDest = paintColor;


  if (PaintDest == 8)
  {
    cleanBrush();  // Changing color to "water" -- just clean the brush.
  }
  else if ((PaintDest >= 0) && (PaintDest <= 7))
  {
    selectedWater = 8;
    getPaintStatus = 0;  // Begin getPaint process
    getPaint();
  }
  else 
    getPaintStatus = -1;
}
*/

void MoveToXY(int xLoc, int yLoc)
{
  MoveDestX = xLoc;
  MoveDestY = yLoc;

  MoveToXY();
}

void MoveToXY()
{
  int traveltime_ms;

  // Absolute move in motor coordinates, with XY limit checking, time management, etc.
  // Use MoveToXY(int xLoc, int yLoc) to set destinations.

  int waitTime = NextMoveTime - millis();
  if (waitTime > 0)
  {
    moveStatus = 1;  // Flag this move as not yet completed.
  }
  else
  {
    if ((MoveDestX < 0) || (MoveDestY < 0))
    { 
      // Destination has not been set up correctly.
      // Re-initialize varaibles and prepare for next move.  
      MoveDestX = -1;
      MoveDestY = -1;
    }
    else {

      moveStatus = -1;
      if (MoveDestX > MotorMaxX) 
        MoveDestX = MotorMaxX; 
      else if (MoveDestX < MotorMinX) 
        MoveDestX = MotorMinX; 

      if (MoveDestY > MotorMaxY) 
        MoveDestY = MotorMaxY; 
      else if (MoveDestY < MotorMinY) 
        MoveDestY = MotorMinY; 

      int xD = MoveDestX - MotorX;
      int yD = MoveDestY - MotorY;

      if ((xD != 0) || (yD != 0))
      {   

        MotorX = MoveDestX;
        MotorY = MoveDestY;

        int MaxTravel = max(abs(xD), abs(yD)); 
        traveltime_ms = int(floor( float(1000 * MaxTravel)/MotorSpeed));


        NextMoveTime = millis() + traveltime_ms -   ceil(1000 / frameRate);
        // Important correction-- Start next segment sooner than you might expect,
        // because of the relatively low framerate that the program runs at.
      
        

        if (SerialOnline) {
          if (reverseMotorX)
            xD *= -1;
          if (reverseMotorY)
            yD *= -1; 

          myPort.write("SM," + str(traveltime_ms) + "," + str(xD) + "," + str(yD) + "\r");
          //General command "SM,<duration>,<penmotor steps>,<eggmotor steps><CR>"
        }

        // Calculate and animate position location cursor
        int[] pos = getMotorPixelPos();
        float sec = traveltime_ms/1000.0;

        Ani.to(this, sec, "MotorLocatorX", pos[0]);
        Ani.to(this, sec, "MotorLocatorY", pos[1]);

        //        if (debugMode) println("Motor X: " + MotorX + "  Motor Y: " + MotorY);
      }
    }
  }
  
  // Need 
  // SubsequentWaitTime
}













/*


void getPaint()
{
  int xC, yC;
  int xD, yD;

  int waitTime = NextMoveTime - millis();
  if (waitTime <= 0)
  { // If wait time is > 0, this section does not execute, and status is left unchanged.


    int paintColor = PaintDest;
    boolean done = false;
    //    if (debugMode) println("Get Paint!  Color: " + paintColor);


    // Center positions:
    xC = round((paintSwatchX - xBrushRestPositionPixels)* MotorStepsPerPixel);
    yC = round((paintSwatchY0 + paintColor * paintSwatchyD - yBrushRestPositionPixels) * MotorStepsPerPixel);

    // xDelta, yDelta:
    xD = round((paintSwatchOvalWidth * MotorStepsPerPixel)/3);
    yD = round((paintSwatchOvalheight * MotorStepsPerPixel)/3);

    if (getPaintStatus == 0) 
    {  
      if (brushColor == 8)
      { 
        getWater(2, false);   // Brush is already clean.  Dip in the clean water.
      }
      else if (brushColor == paintColor)
        getWater(0, false);   // Brush is already colored.  Dip in the dirty water.
      else
        cleanBrush();  // Changing color!  Clean brush first!
    }
    else if (getPaintStatus == 1) 
      raiseBrush();
    else if (getPaintStatus == 2) 
      MoveToXY(xC, yC);  // Center of paint
    else if (getPaintStatus == 3) 
      lowerBrush();

    else if (getPaintStatus == 4) 
      MoveToXY(xC - xD, yC);  // Left side
    else if (getPaintStatus == 5) 
      MoveToXY(xC, yC-yD);    // Top side
    else if (getPaintStatus == 6) 
      MoveToXY(xC + xD, yC);  // Right side
    else if (getPaintStatus == 7) 
      MoveToXY(xC, yC+yD);    // Bottom side

    else if (getPaintStatus == 8) 
      MoveToXY(xC - xD, yC);  // Left side
    else if (getPaintStatus == 9) 
      MoveToXY(xC, yC-yD);    // Top side
    else if (getPaintStatus == 10) 
      MoveToXY(xC + xD, yC);  // Right side
    else if (getPaintStatus == 11) 
      MoveToXY(xC, yC+yD);    // Bottom side

    else if (getPaintStatus == 12) 
      MoveToXY(xC, yC);  // Center of paint -- so that if we stop there, we'll drip over the paint.

    else { 
      raiseBrush();
      brushColor = paintColor;
      redrawLocator();
      getPaintStatus = -1;  // Flag that we are done with this operation.
      PaintDest = -1;
    }

    if (getPaintStatus >= 0)
      getPaintStatus += 1;  // Increment stage, if we are not finished.
  }
}


*/

void MotorsOff()
{
  if (SerialOnline)
  {    
    myPort.write("EM,0,0\r");  //Disable both motors

    //    if (debugMode) println("Motors disabled.");
  }
}

void zero()
{
  // Mark current location as (0,0) in motor coordinates.  
  // Manually move the motor carriage to the left-rear (upper left) corner before executing this command.

  MotorX = 0;
  MotorY = 0;

  moveStatus = -1;
  MoveDestX = -1;
  MoveDestY = -1;


  //  if (debugMode) println("Motor X: " + MotorX + "  Motor Y: " + MotorY);
}

