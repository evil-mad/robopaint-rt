/**
 * RoboPaint RT - Draw loop check functions (not for drawing)
 */


// Manage checking if the brush needs servicing, and moving to the next path
void checkServiceBrush() {
  serviceBrush(); // Is this one actually needed if it's being called below?
  if (serviceBrush() == false)

    if (millis() > NextMoveTime)
    {

      boolean actionItem = false;
      int intTemp = -1;


      if ((ToDoList.length > (indexDone + 1))   && (Paused == false))
      {
        actionItem = true;
        intTemp = ToDoList[1 + indexDone];  

        indexDone++;
      }


      if (actionItem)
      {  // Perform next action from ToDoList::

        //
        //        intTemp = ToDoList[0];  
        //        ToDoList = subset(ToDoList, 1); // Drop first element from ToDoList
        //        DoneList = append(DoneList, intTemp); // Add the element to the end of DoneList

        if (segmentQueued)
          drawQueuedSegment();


        if (intTemp >= 0)
        { // Move the carriage to paint a path segment! 
          // "This is where the magic happens..."
          int x2 = floor(intTemp / 10000);
          int y2 = intTemp - 10000 * x2;

          int x1 = round( float(x2 - MousePaperLeft) * MotorStepsPerPixel + xMotorPaperOffset);
          int y1 = round( float(y2 - MousePaperTop) * MotorStepsPerPixel); 


          // TODO: Draw the segment that is being painted, here.
          MoveToXY(x1, y1);


          if (BrushDown == true) { 
            if (lastPosition == -1)
              lastPosition = intTemp;
            //            drawDoneSegment(lastPosition, intTemp); 

            queueSegmentToDraw(lastPosition, intTemp); 
            //          if (segmentQueued)
            //        drawQueuedSegment();


            lastPosition = intTemp;
          }
        }
        else
        {
          lastPosition = -1;  // For drawing DoneList

          intTemp = -1 * intTemp;

          if ((intTemp > 9) && (intTemp < 20)) 
          {  // Change paint color  

            intTemp -= 10; 

            getPaint(intTemp);
            //            color TempColor = paintset[intTemp];
            //            stroke(color_for_new_ToDo_paths);
          }
          else if ((intTemp >= 20) && (intTemp < 30)) 
          {  // Get water from dish  
            intTemp -= 20;
            getWater(intTemp, false);
          }  
          else if (intTemp == 40) 
          { 
            cleanBrush();
          }
          else if (intTemp == 30) 
          {
            raiseBrush();
          }
          else if (intTemp == 31) 
          {  
            lowerBrush();
          }
          else if (intTemp == 35) 
          {  
            MoveToXY(0, 0);
          }
        }
      }
    }
}

// Manage checking mouse position for highlights
void checkHighlights() {
  boolean doHighlightRedraw = false;
  int i;
  float tempFloat;

  if (recordingGesture == false) {
    int x1 = -1;
    int x2 = -1;

    // Check for mouse over water dishes:
    if (mouseX < WaterDishX + (WaterDishDia/2))
    {
      // Mouse is far enough left to be over the water dishes.
      for (i = 0; i < 3; i++) { 
        tempFloat = WaterDishY0 + i * WaterDishyD - ( WaterDishDia / 2);
        if ((mouseY > tempFloat ) && (mouseY < (tempFloat + WaterDishDia)))
        {
          x1 = i;
          break;
        }
      }
    }
    else if ((mouseX > paintSwatchX - (paintSwatchOvalWidth /2) ) &&
      (mouseX < paintSwatchX + (paintSwatchOvalWidth / 2)))
    {   // Check for mouse over paint swatches:

      for ( i = 0; i < 8; i++) { 
        tempFloat = paintSwatchY0 + i * paintSwatchyD - ( paintSwatchOvalheight / 2);
        if ((mouseY > tempFloat ) && (mouseY < (tempFloat + paintSwatchOvalheight)))
        {
          x2 = i;
          break;
        }
      }
    }

    if (x1 != highlightedWater)
    {
      doHighlightRedraw = true;
      highlightedWater = x1;
    }

    if (x2 != highlightedColor)
    {
      doHighlightRedraw = true;
      highlightedColor = x2;
    }
  }



  // Manage highlighting of text buttons
  if (mouseY >= MousePaperBottom)  
    if ((mouseY <= height)  && (mouseX >=  (MousePaperLeft - 50)))
    { 
      if ((abs(mouseX - lastButtonUpdateX) + abs(mouseY - lastButtonUpdateY)) > 5)  
        redrawButtons();
      lastButtonUpdateX = mouseX;
      lastButtonUpdateY = mouseY;
    } 

  if (doHighlightRedraw) {
    redrawHighlight();
    //    redrawButtons();
  }
}

