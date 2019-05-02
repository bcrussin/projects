  //VOID FUNCTIONS
void graphLine(int i, float x1, float y1, float x2, float y2) {
  x1 = map(x1, camX[0], camX[1], xBound[0], width - xBound[1]);
  x2 = map(x2, camX[0], camX[1], xBound[0], width - xBound[1]);
  y1 = map(y1, camY[0], camY[1], height - yBound[1], yBound[0]);
  y2 = map(y2, camY[0], camY[1], height - yBound[1], yBound[0]);
  //println(x1 + ", " + y1 + ", " + x2 + ", " + y2);
  if(lineHover == i) stroke(hoverCol);
  else stroke(colors[i]);
  line(x1, y1, x2, y2);
  return;
}

void graphPoint(float x1, float y1, color c, float r) {
  x1 = map(x1, camX[0], camX[1], xBound[0], width - xBound[1]);
  y1 = map(y1, camY[0], camY[1], height - yBound[1], yBound[0]);
  
  fill(c);
  noStroke();
  ellipse(x1, y1, r, r);
}

void zoomToSelected(float spd) {
  float yRange = getSelectedRange()[0] - getSelectedRange()[1];
  float[] zoomx = {0, (numPoints - 1) * dataInterval};
  float[] zoomy = {getSelectedRange()[1] - (yRange * 0.05), getSelectedRange()[0] + (yRange * 0.05)};
  if(yRange == 0) {
    zoomy[0] -= 1;
    zoomy[1] += 1;
  }
  zoomToPos(zoomx, zoomy, spd);
  return;
}

void zoomToPos(float[] cx, float[] cy, float spd) {
  //println("[" + cx[0] + ", " + cx[1] + "], [" + cy[0] + ", " + cy[1] + "]");
  if(allTrueFalse(lineToggle, false)) return;
  autoZooming = true;
  autoZoomSpd = spd;
  zoomTargetX[0] = cx[0];
  zoomTargetX[1] = cx[1];
  zoomTargetY[0] = cy[0];
  zoomTargetY[1] = cy[1];
  
  return;
}

  //credit to jdeisenberg (https://processing.org/discourse/beta/num_1202486379.html#4)
void dashLine(float x0, float y0, float x1, float y1, float[ ] spacing) {
  float distance = dist(x0, y0, x1, y1); 
  float [ ] xSpacing = new float[spacing.length]; 
  float [ ] ySpacing = new float[spacing.length]; 
  float drawn = 0.0;  // amount of distance drawn 
 
  if (distance > 0) 
  { 
    int i; 
    boolean drawLine = true;
    for (i = 0; i < spacing.length; i++) 
    { 
      xSpacing[i] = lerp(0, (x1 - x0), spacing[i] / distance); 
      ySpacing[i] = lerp(0, (y1 - y0), spacing[i] / distance); 
    } 
 
    i = 0; 
    while (drawn < distance) 
    { 
      if (drawLine) 
      { 
        line(x0, y0, x0 + xSpacing[i], y0 + ySpacing[i]); 
      } 
      x0 += xSpacing[i]; 
      y0 += ySpacing[i]; 
      /* Add distance "drawn" by this line or gap */ 
      drawn = drawn + mag(xSpacing[i], ySpacing[i]); 
      i = (i + 1) % spacing.length;  // cycle through array 
      drawLine = !drawLine;  // switch between dash and gap 
    } 
  } 
}

void drawOriginLines(boolean onTop) {
  float[] spacing;
  if(onTop) {
    stroke(#333333);
    strokeWeight(6);
    spacing = new float[] {10, 14};
  } else {
    stroke(#cccccc);
    strokeWeight(3);
    spacing = new float[] {5, 7};
  }
  if(camX[0] < 0 && camX[1] > 0) {
    float zeroX = map(0, camX[0], camX[1], xBound[0], width - xBound[1]);
    dashLine(zeroX, yBound[0], zeroX, height - yBound[1], spacing);
  }
  if(camY[0] < 0 && camY[1] > 0) {
    float zeroY = map(0, camY[1], camY[0], yBound[0], height - yBound[1]);
    dashLine(xBound[0], zeroY, width - xBound[1], zeroY, spacing);
  }
  return;
}



  //NON-ARRAY FUNCTIONS
int getDataIndex(float input) {
  if(input < 0) return 0;
  if(input > numPoints * dataInterval) return numPoints;
  return (int) map(input, 0, numPoints * dataInterval, 0, numPoints);
}

float getPowerOfTen(float input) {
  int counter = 0;
  if(input <= 0) {
    return Float.NaN;
  } else if(input < 10 && input >= 1) {
    return 0;
  } else if(input >= 10) {
    while(input >= 10) {
      input /= 10;
      counter++;
    }
    return counter;
  } else {
    while(input < 1) {
      input *= 10;
      counter--;
    }
    return counter;
  }
}

float roundToPowOfTen(float input) {
  return pow(10, getPowerOfTen(input));
}

float getTextWidth(String input, int size) {
  float oldSize = g.textSize;
  textSize(size);
  float output = textWidth(input);
  textSize(oldSize);
  return output;
}

float roundUpTo(float num, double interval) {
  return (float) (Math.ceil(num / interval) * interval);
}

float roundDownTo(float num, double interval) {
  return (float) (Math.floor(num / interval) * interval);
}

boolean arrContains(float[] arr, float check) {
  for(int i = 0; i < arr.length; i++) {
    if(arr[i] == check) return true;
  }
  return false;
}

boolean arrContains(int[] arr, int check) {
  for(int i = 0; i < arr.length; i++) {
    if(arr[i] == check) return true;
  }
  return false;
}


boolean allTrueFalse(boolean[] arr, boolean check) {
  for(int i = 0; i < arr.length; i++) {
    if(arr[i] != check) return false;
  }
  return true;
}

boolean checkRect(float inputX, float inputY, float rectX, float rectY, float rectW, float rectH) {
  return inputX >= rectX && inputX <= rectX + rectW && inputY >= rectY && inputY <= rectY + rectH;
}



  //ARRAY FUNCTIONS
float[] getGraphPos(float x, float y) {
  float[] result = {map(x, xBound[0], width - xBound[1], 0, graphWidth), map(y, height - yBound[1], yBound[0], 0, graphHeight)};
  return result;
}

float[] getSelectedRange() {
  float max = Float.NaN;
  float min = Float.NaN;
  
  for(int i = 0; i < numLines; i++) {
    if(lineToggle[i]) {
      if(maxPoint[i] > max || max != max) max = maxPoint[i];
      if(minPoint[i] < min || min != min) min = minPoint[i];
    }
  }
  
  float[] result = {max, min};
  
  return result;
}

float[] getRangeWithinDomain(int id, float[] xRange) {
  float max = data[id][getDataIndex(xRange[0])];
  float min = data[id][getDataIndex(xRange[0])];
  
  for(int i = getDataIndex(xRange[0]) + 1; i < getDataIndex(xRange[1]); i++) {
    if(data[id][i] > max) max = data[id][i];
    if(data[id][i] < min) min = data[id][i];
  }
  
  float[] result = {max, min};
  
  return result;
}

float[] getRangeWithinDomain(int[] id, float[] xRange) {
  float max = data[id[0]][getDataIndex(xRange[0])];
  float min = data[id[0]][getDataIndex(xRange[0])];
  
  println(id);
  
  for(int j = 0; j < numLines; j++) {
    if(id[j] == 1) {
      for(int i = getDataIndex(xRange[0]) + 1; i < getDataIndex(xRange[1]); i++) {
        if(data[j][i] > max) max = data[j][i];
        if(data[j][i] < min) min = data[j][i];
      }
    }
  }
  
  float[] result = {max, min};
  
  return result;
}


  //CONVERSION ARRAYS
int[] floatToInt(float[] arr) {
  int[] output = {};
  for(int i = 0; i < arr.length; i++) {
    append(output, (int) arr[i]);
  }
  
  return output;
}

int[] boolToInt(boolean[] arr) {
  int[] output = new int[arr.length];
  for(int i = 0; i < arr.length; i++) {
    output[i] = int(arr[i]);
  }
  
  return output;
}