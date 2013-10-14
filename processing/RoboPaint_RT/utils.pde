int xyEncodeInt2() {

  // Perform XY limit checks on user input, and then encode position of mouse into a single int.
  // Constrain inputs to be within range of paper size, but all numbers are w.r.t. absolute window origin.
  // This is essentially only called when the mouse position changes.

  int xpos = mouseX;
  int ypos = mouseY;

  if (xpos < MousePaperLeft)
    xpos = MousePaperLeft;
  if (xpos > MousePaperRight)
    xpos = MousePaperRight;

  if (ypos < MousePaperTop)
    ypos = MousePaperTop;
  if (ypos > MousePaperBottom )
    ypos = MousePaperBottom;

  return (xpos * 10000) + ypos ;
}


int[] xyDecodeInt2(int encodedInt) {

  // Decode position coordinate from a single int.

  int x = floor(encodedInt / 10000);
  int y = encodedInt - 10000 * x;
  int[] out = {
    x, y
  };
  return out;
}


// Return the [x,y] of the motor position in pixels
int[] getMotorPixelPos() {
  int[] out = {
    int (float (MotorX) / MotorStepsPerPixel) + xBrushRestPositionPixels, 
    int (float (MotorY) / MotorStepsPerPixel) + yBrushRestPositionPixels
  };
  return out;
}

// Get float distance between two int encoded coordinates
float getDistance(int coord1Int, int coord2Int)
{
  int[] c1 = xyDecodeInt2(coord1Int);
  int[] c2 = xyDecodeInt2(coord2Int);

  int xdiff = abs(c1[0] - c2[0]);
  int ydiff = abs(c1[1] - c2[1]);

  return sqrt(pow(xdiff, 2) + pow(ydiff, 2));
}



// Get float distance between two non-encoded (x,y) positions. 
float getDistance(int x1, int y1, int x2, int y2)
{
  int xdiff = abs(x2 - x1);
  int ydiff = abs(y2 - y1);
  return sqrt(pow(xdiff, 2) + pow(ydiff, 2));
}













