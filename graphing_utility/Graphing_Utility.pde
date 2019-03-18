import java.util.*; 
import java.io.*;

int w = 1280;
int h = 720;

Table csvData;
String dataPath = "piData";
String[] fileData;
float[][] data;
float[] maxPoint;
float[] minPoint;
float[] maxLength;
float trueMax;
float trueMin;
float[] camX = {0, 0};
float[] camY = {0, 0};
float[] oldCamX = {0, 0};
float[] oldCamY = {0, 0};
float[] clickPos = {0, 0};
float[] savedCamX = {0, 0};
float[] savedCamY = {0, 0};
float[] zoomTargetX = {0, 0};
float[] zoomTargetY = {0, 0};
float graphWidth;
float graphHeight;
float stroke;
float selectedRange;
float maxToggled;
float minToggled;
float autoZoomSpd;
double xInterval;
double yInterval;
int numLabels;
int numLines;
int numPoints;
int graphID;
boolean autoZooming = false;
boolean zooming = false;
boolean zoomedToFit = false;
boolean graphMode = true;
boolean dragging = false;
boolean zoomBoth = true;
boolean spacePressed = false;
boolean ctrlPressed = false;
boolean altPressed = false;
color bgCol = #f2f2f2;

float[] xBound = {100, 300};
float[] yBound = {25, 25};
float[] startCamX = {-10, 15.4};
float[] startCamY = {-19000, 20000};
float[] zoomScale = {0.5, 10};
float zoomSpd = 0.4;
float clickZoomSpd = 5;

int dataTextSize = 25;
color dataLabelBG = #e6e6e6;
float dataScrollSpd = 20;
float dataInterval = 0.2;
float dataPadX = 4.5;
float dataPadY = 2.5;
float dataCamX = 0;
float dataCamY = 0;
float oldDataCamX;
float oldDataCamY;
float dataTotalWidth = 0;
float dataTotalHeight;
boolean shiftPressed = false;

float minStroke = 3;
float maxStroke = 12;
float strokeScale = 1;
float hoverSize = 1.5;
int lineHover = -1;
color hoverCol = #4d4d4d;
color hoverPointCol = #cccccc;

String[] labels = {};
float boxSize = 20;

color[] colors = {#ff0000, #ff8000, #ffcc00, #ace600, #00e64a, #00e6b8, #00ace6, #0017e6, #d500e6};
boolean[] lineToggle;

void graphLine(int i, float x1, float y1, float x2, float y2) {
  x1 = map(x1, camX[0], camX[1], xBound[0], width - xBound[1]);
  x2 = map(x2, camX[0], camX[1], xBound[0], width - xBound[1]);
  y1 = map(y1, camY[0], camY[1], height - yBound[0], yBound[1]);
  y2 = map(y2, camY[0], camY[1], height - yBound[0], yBound[1]);
  //println(x1 + ", " + y1 + ", " + x2 + ", " + y2);
  if(lineHover == i) stroke(hoverCol);
  else stroke(colors[i]);
  line(x1, y1, x2, y2);
  return;
}

void graphPoint(float x1, float y1, color c, float r) {
  x1 = map(x1, camX[0], camX[1], xBound[0], width - xBound[1]);
  y1 = map(y1, camY[0], camY[1], height - yBound[0], yBound[1]);
  
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

float[] getGraphPos(float x, float y) {
  float[] result = {map(x, xBound[0], width - xBound[1], 0, graphWidth), map(y, height - yBound[0], yBound[1], 0, graphHeight)};
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
  
  float result[] = {max, min};
  
  return result;
}

boolean allTrueFalse(boolean[] arr, boolean check) {
  for(int i = 0; i < arr.length; i++) {
    if(arr[i] != check) return false;
  }
  return true;
}

float roundUpTo(float num, double interval) {
  return (float) (Math.ceil(num / interval) * interval);
}

float roundDownTo(float num, double interval) {
  return (float) (Math.floor(num / interval) * interval);
}

void mousePressed() {
  if(mouseX > xBound[0] && mouseX < width - xBound[1] && mouseY > yBound[1] && mouseY < height - yBound[0]) {
    if(mouseButton == CENTER && graphMode) {
      if(!zooming) {
          //click (and zoom) graph
        clickPos[0] = mouseX;
        clickPos[1] = mouseY;
        for(int i = 0; i < 2; i++) {
          oldCamX[i] = camX[i];
          oldCamY[i] = camY[i];
        }
        zooming = true;
      }
    } else if(mouseButton == LEFT) {
      if(!dragging) {
          //click (and drag) graph
        clickPos[0] = mouseX;
        clickPos[1] = mouseY;
        if(graphMode) {
          for(int i = 0; i < 2; i++) {
            oldCamX[i] = camX[i];
            oldCamY[i] = camY[i];
          }
        } else {
          oldDataCamX = dataCamX;
          oldDataCamY = dataCamY;
        }
        dragging = true;
      }
    }
  } else if(mouseX > width - xBound[1] + 20 && mouseX < width - xBound[1] + 120
    && mouseY > yBound[1] * 1.25 && mouseY < yBound[1] * 1.25 + 45) {
        //show/hide all lines
      if(allTrueFalse(lineToggle, true)) Arrays.fill(lineToggle, false);
      else Arrays.fill(lineToggle, true);
  } else if(mouseX > width - xBound[1] + 140 && mouseX < width - xBound[1] + 280
    && mouseY > yBound[1] * 1.25 && mouseY < yBound[1] * 1.25 + 45) {
        //toggle graph mode
      graphMode = !graphMode;
  } else {
      //show/hide a single line
    if(mouseX > width - xBound[1] + 50 && mouseX < width - xBound[1] + 50 + boxSize) {
      for(int i = 1; i < numLabels; i++) {
        if(mouseY > (graphHeight / numLabels) * i + (yBound[1] * 2)
          && mouseY < (graphHeight / numLabels) * i + (yBound[1] * 2) + boxSize) {
            
          if(mouseButton == LEFT) {
              //show/hide single line
            lineToggle[i-1] = !lineToggle[i-1];
          } else if(mouseButton == RIGHT) {
              //show only selected line
            Arrays.fill(lineToggle, false);
            lineToggle[i-1] = true;
          }
          
          if(ctrlPressed) {
              //zoom to fit selected points
            zoomToSelected(7);
          }
        }
      }
    }
  }
}

void mouseReleased() {
  dragging = false;
  zooming = false;
}

void mouseWheel(MouseEvent event) {
  autoZooming = false;
  if(mouseX > xBound[0] && mouseX < width - xBound[1] && mouseY > yBound[1] && mouseY < height - yBound[0]) {
    if(graphMode) {
      zoomBoth = ctrlPressed == shiftPressed;
      float e = event.getCount();
      float mx = altPressed ? 0.5 : map(mouseX, xBound[0], width - xBound[1], 0, 1);
      float my = altPressed ? 0.5 : map(mouseY, height - yBound[0], yBound[1], 0, 1);
      float cw = camX[1] - camX[0];
      float ch = camY[1] - camY[0];
      float[] zoomx = {camX[0], camX[1]};
      float[] zoomy = {camY[0], camY[1]};
      if(zoomBoth || shiftPressed) zoomx[0] += (zoomSpd * cw) * mx * (e * -1);
      if(zoomBoth || shiftPressed) zoomx[1] += (zoomSpd * cw) * (1-mx) * e;
      if(zoomBoth || ctrlPressed) zoomy[0] += (zoomSpd * ch) * my * (e * -1);
      if(zoomBoth || ctrlPressed) zoomy[1] += (zoomSpd * ch) * (1-my) * e;
      zoomToPos(zoomx, zoomy, 5);
    } else {
      float e = event.getCount();
      if(shiftPressed) {
        dataCamX += e * dataScrollSpd * -1;
      } else {
        dataCamY += e * dataScrollSpd;
      }
    }
  }
}

void keyPressed() {
  if(key == ' ') {
    spacePressed = true;
  }
  switch(keyCode) {
    case CONTROL:
      ctrlPressed = true;
      break;
    case SHIFT:
      shiftPressed = true;
      break;
    case ALT:
      altPressed = true;
      break;
    case ENTER:
      zoomToSelected(10);
      break;
  }
}

void keyReleased() {
  if(key == ' ') {
    spacePressed = false;
  }
  switch(keyCode) {
    case CONTROL:
      ctrlPressed = false;
      break;
    case SHIFT:
      shiftPressed = false;
      break;
    case ALT:
      altPressed = false;
      break;
  }
}

void settings() {
  size(w, h);
}

void setup() {
  graphWidth = (width - xBound[1]) - xBound[0];
  graphHeight = (height - yBound[0]) - yBound[1];
  File f = dataFile(dataPath + ".csv");
  boolean exist = f.isFile();
  if(exist) {
    println("Loading .csv file");
    dataPath += ".csv";
    csvData = loadTable(dataPath, "header");
    numLines = csvData.getColumnCount();
    numPoints = csvData.getRowCount();
    labels = new String[numLines];
    data = new float[numLines][numPoints];
    maxPoint = new float[numLines];
    minPoint = new float[numLines];
    maxLength = new float[numLines];
    Arrays.fill(maxPoint, Float.NaN);
    Arrays.fill(minPoint, Float.NaN);
    for(int i = 0; i < numLines; i++) {
      labels[i] = csvData.getColumnTitle(i);
      for(int j = 0; j < numPoints; j++) {
        data[i][j] = csvData.getFloat(j, i);
        if(data[i][j] > maxPoint[i] || maxPoint[i] != maxPoint[i]) {
          maxPoint[i] = data[i][j];
          maxLength[i] = str(maxPoint[i]).length() * dataTextSize;
        }
        
        if(data[i][j] < minPoint[i] || minPoint[i] != minPoint[i]) minPoint[i] = data[i][j];
      }
    }
  } else {
    println("Loading .txt file");
    dataPath += ".txt";
    fileData = loadStrings(dataPath);
    String[] temp = loadStrings(dataPath);
    labels = temp[0].split(",");
    numLines = parseInt(split(fileData[0], ",").length);
    numPoints = parseInt(fileData.length) - 1;
    data = new float[numLines][numPoints];
    maxPoint = new float[numLines];
    minPoint = new float[numLines];
    maxLength = new float[numLines];
    Arrays.fill(maxPoint, Float.NaN);
    Arrays.fill(minPoint, Float.NaN);
    for(int i = 0; i < numPoints; i++) {
      temp = split(fileData[i + 1], ",");
      for(int j = 0; j < temp.length; j++) {
        data[j][i] = float(temp[j]);
        if(float(temp[j]) > maxPoint[j] || maxPoint[j] != maxPoint[j]) {
          maxPoint[j] = float(temp[j]);
          maxLength[j] = str(maxPoint[j]).length() * dataTextSize;
        }
        
        if(float(temp[j]) < minPoint[j] || minPoint[j] != minPoint[j]) minPoint[j] = float(temp[j]);
      }
    }
  }
  
  println(numLines + " rows, " + numPoints + " columns");
  
  for(int i = 0; i < numLines; i++) {
    if(maxPoint[i] != maxPoint[i]) maxPoint[i] = 0;
    if(minPoint[i] != minPoint[i]) minPoint[i] = 0;
  }
  
  lineToggle = new boolean[numLines];
  Arrays.fill(lineToggle, true);
  numLabels = numLines + 1;
  
  dataPadX *= dataTextSize;
  dataPadY *= dataTextSize;
  for(int i = 0; i < maxLength.length; i++) {
    dataTotalWidth += maxLength[i];
  }
  dataTotalWidth += (dataPadX) - graphWidth + (dataTextSize);
  dataTotalHeight = (dataPadY * numPoints) - graphHeight;
  
  camX[0] = startCamX[0];
  camX[1] = startCamX[1];
  camY[0] = startCamY[0];
  camY[1] = startCamY[1];
  
  lineToggle[1] = false;
  
  zoomToSelected(15);
}

void draw() {
    //update mouse
  if(autoZooming) {
    //println((zoomTargetX[1] - camX[1]) / zoomSpd);
    camX[0] += (zoomTargetX[0] - camX[0]) / autoZoomSpd;
    camX[1] += (zoomTargetX[1] - camX[1]) / autoZoomSpd;
    camY[0] += (zoomTargetY[0] - camY[0]) / autoZoomSpd;
    camY[1] += (zoomTargetY[1] - camY[1]) / autoZoomSpd;
    float zoomDist = 0.1;
    if(abs(camX[0] - zoomTargetX[0]) < zoomDist && abs(camX[1] - zoomTargetX[1]) < zoomDist && abs(camY[0] - zoomTargetY[0]) < zoomDist && abs(camY[1] - zoomTargetY[1]) < zoomDist) {
      //println("ZOOM COMPLETE");
      //println(camY[0] - zoomTargetY[0]);
      autoZooming = false;
    }
  }
  
  if(mousePressed) {
    if(dragging) {
      if(graphMode) {
        zoomedToFit = false;
        autoZooming = false;
        for(int i = 0; i < 2; i++) {
          camX[i] = oldCamX[i] - ((mouseX - clickPos[0]) / (graphWidth / (camX[1] - camX[0])));
          camY[i] = oldCamY[i] - ((clickPos[1] - mouseY) / (graphHeight / (camY[1] - camY[0])));
        }
      } else {
        dataCamX = oldDataCamX - ((mouseX - clickPos[0]));
        dataCamY = oldDataCamY - ((clickPos[1] - mouseY)) * -1;
      }
    } else if(zooming && graphMode) {
      zoomedToFit = false;
      autoZooming = false;
      float[] graphPos = getGraphPos(mouseX, mouseY);
      float[] oldGraphPos = getGraphPos(clickPos[0], clickPos[1]);
      camX[0] += map(graphPos[1], 0, graphHeight, camX[0], camX[1]) - map(oldGraphPos[1], 0, graphHeight, camX[0], camX[1]);
      camY[0] += map(graphPos[1], 0, graphHeight, camY[0], camY[1]) - map(oldGraphPos[1], 0, graphHeight, camY[0], camY[1]);
      camX[1] -= map(graphPos[1], 0, graphHeight, camX[0], camX[1]) - map(oldGraphPos[1], 0, graphHeight, camX[0], camX[1]);
      camY[1] -= map(graphPos[1], 0, graphHeight, camY[0], camY[1]) - map(oldGraphPos[1], 0, graphHeight, camY[0], camY[1]);
      clickPos[1] = mouseY;
    }
  }
  
  
  //Arrays.fill(maxPoint, 2000);
  //Arrays.fill(minPoint, -1000);
  background(bgCol);
  
  if(graphMode) {
      //draw graph lines
    stroke = constrain(maxStroke - ((camX[1] - camX[0]) / (numPoints * dataInterval) / strokeScale * (minStroke + (maxStroke / minStroke))), minStroke, maxStroke);
    strokeWeight(stroke);
    //strokeWeight(map(constrain((camX[1] - camX[0]) * 0.5, 1, numPoints * dataInterval), 2, (numPoints * dataInterval), (numPoints * dataInterval), 2));
    for(int i = 0; i < numLines; i++) {
      for(int j = 1; j < numPoints; j++) {
        if(lineToggle[i]) {
          if(lineHover != i) {
            stroke(colors[i]);
            graphLine(i, (j-1) * dataInterval, data[i][j-1], j * dataInterval, data[i][j]);
          }
        } else {
          continue;
        }
      }
    }
    if(lineHover != -1 && lineToggle[lineHover]) {
      /*hoverCol = colors[lineHover];
      float hRed = red(hoverCol);
      float hGreen = green(hoverCol);
      float hBlue = blue(hoverCol);
      hRed += (255 - hRed) * hoverMod;
      hGreen += (255 - hGreen) * hoverMod;
      hBlue += (255 - hBlue) * hoverMod;
      stroke(hRed, hGreen, hBlue);*/
      stroke(hoverCol);
      strokeWeight(stroke * hoverSize);
      float pointSize = stroke * hoverSize;
      for(int j = 1; j < numPoints; j++) {
        graphLine(lineHover, (j-1) * dataInterval, data[lineHover][j-1], j * dataInterval, data[lineHover][j]);
      }
      for(int j = 1; j < numPoints; j++) {
        graphPoint(j * dataInterval, data[lineHover][j], hoverPointCol, pointSize);
      }
    }
  } else {
      //show data view
    if(dataCamX < 0) dataCamX = 0;
    if(dataCamY < 0) dataCamY = 0;
    if(dataCamX > dataTotalWidth) dataCamX = dataTotalWidth;
    if(dataCamY > dataTotalHeight) dataCamY = dataTotalHeight;
      
    textSize(dataTextSize);
    textAlign(LEFT, TOP);
    strokeWeight(2);
    
    float xpos = (dataPadX) - dataCamX;
    
    textAlign(LEFT, TOP);
    fill(#000000);
    
      //render data
    for(int i = 0; i < numLines; i++) {
      for(int j = 0; j < numPoints; j++) {
        float ypos = (dataPadY) + ((dataTextSize + 5) * j * 2) - dataCamY;
        text(data[i][j], xBound[0] + xpos, yBound[1] + ypos);
      }
      xpos += maxLength[i];
    }
    
      
    fill(dataLabelBG);
    noStroke();
    rect(xBound[0], yBound[1], dataPadX, graphHeight);
    rect(xBound[0], yBound[1], graphWidth, dataPadY);
    stroke(#000000);
    xpos = (dataPadX) - dataCamX;
    
      //data labels
    for(int i = 0; i < numLines; i++) {
      //println(maxPoint[i] + ", " + maxLength[i]);
      //float xpos = (maxLength[i] * (i * 5) + 4);
      if(xpos > dataPadX) line(xBound[0] + xpos, yBound[1], xBound[0] + xpos, height - yBound[0]);
      
      fill(colors[i]);
      text(labels[i], xBound[0] + xpos + 5, yBound[1] + (dataTextSize));
      if(xBound[0] + xpos > width - xBound[1]) break;
      xpos += (maxLength[i]);
    }
    
    
    textAlign(LEFT, TOP);
    fill(#000000);
    
      //data interval labels
    for(int i = 0; i < numPoints; i++) {
      float ypos = (dataPadY) + ((dataTextSize + 5) * i * 2) - dataCamY;
      if(ypos > dataPadY) line(0, yBound[1] + ypos, width - xBound[1], yBound[1] + ypos);
      text(dataInterval * i, xBound[0] + 10, yBound[1] + ypos);
      if(yBound[1] + ypos > height - yBound[0]) break;
    }
    
    fill(dataLabelBG);
    noStroke();
    rect(xBound[0], yBound[1], dataPadX, dataPadY);
    stroke(#000000);
    strokeWeight(5);
    line(xBound[0] + (dataPadX), yBound[1], xBound[0] + (dataPadX), height - yBound[0]);
    line(0, yBound[1] + (dataPadY), width - xBound[1], yBound[1] + (dataPadY));
  }  //end data view
  
  
    //hide overflow
  fill(#ffffff);
  noStroke();
  rect(0, 0, xBound[0], height);
  rect(width - xBound[1], 0, width, height);
  rect(0, 0, width, yBound[1]);
  rect(0, height - yBound[0], width, height);
  
  if(!graphMode) {
      //scroll lines
    fill(#a6a6a6);
    noStroke();
    if(dataTotalHeight + dataPadY > graphHeight) rect(width - xBound[1] + 5, map(dataCamY, 0, dataTotalHeight, yBound[1] + dataPadY + 5, height - yBound[0] - 55), 10, 50, 5);
    if(dataTotalWidth > 0) rect(map(dataCamX, 0, dataTotalWidth, xBound[0] + dataPadX + 5, width - xBound[1] - 55), height - yBound[0] + 5, 50, 10, 5);
  }
  
  
    //draw ui
  lineHover = -1;
  for(int i = 1; i < numLabels; i++) {
    stroke(#000000);
    strokeWeight(2);
    
    if(lineToggle[i-1]) {
      fill(colors[i-1]);
    } else {
      noFill();
    }
    rect(width - xBound[1] + 50, (graphHeight / numLabels) * i + (yBound[1] * 2), boxSize, boxSize, 5);
    fill(colors[i-1]);
    textSize(25);
    textAlign(LEFT, CENTER);
    text(labels[i-1], width - xBound[1] + 60 + boxSize, (graphHeight / numLabels) * i + (yBound[1] * 2) + 7);
    if(mouseX > width - xBound[1] + 50 && mouseX < width - xBound[1] + 50 + boxSize && mouseY > (graphHeight / numLabels) * i + (yBound[1] * 2) && mouseY < (graphHeight / numLabels) * i + (yBound[1] * 2) + boxSize) {
      lineHover = i-1;
    }
  }
  
  fill(#aaaaaa);
  rect(width - xBound[1] + 20, yBound[1] * 1.25, 100, 45, 2);
  rect(width - xBound[1] + 140, yBound[1] * 1.25, 140, 45, 2);
  fill(#000000);
  textSize(20);
  textAlign(CENTER, CENTER);
  if(allTrueFalse(lineToggle, true)) text("Hide All", width - xBound[1] + 70, yBound[1] * 1.25 + 20);
  else text("Show All", width - xBound[1] + 70, yBound[1] * 1.25 + 20);
  if(graphMode) text("Show Data", width - xBound[1] + 210, yBound[1] * 1.25 + 20);
  else text("Show Graph", width - xBound[1] + 210, yBound[1] * 1.25 + 20);
  
  if(graphMode) {
       //grid lines
    stroke(#000000);
    
    strokeWeight(5);
    line(xBound[0], yBound[1], xBound[0], height - yBound[0]);
    line(xBound[0], height - yBound[0], width - xBound[1], height - yBound[0]);
    
    
      //axis intervals
    fill(#000000);
    xInterval = (camX[1] - camX[0]);
    yInterval = (camY[1] - camY[0]);
    boolean xRounding, yRounding;
    float tempx = camX[1] - camX[0];
    
    xInterval = (xInterval / 2) * (0.2 + (0.07 * str((int) xInterval).length() / 2));
    float powOfTwo;
    
    if(xInterval > 8) powOfTwo = 2;
    else powOfTwo = pow(10, (getPowerOfTen((float) xInterval) - 1)) * 2;
    
    while(powOfTwo < xInterval) {
      powOfTwo *= 2;
    }
    xInterval = powOfTwo / 2;
    
    yInterval = yInterval / 2 / 2;
    if(yInterval > 8) powOfTwo = 2;
    else powOfTwo = pow(10, (getPowerOfTen((float) yInterval) - 1)) * 2;
    
    while(powOfTwo < yInterval) {
      powOfTwo *= 2;
    }
    yInterval = powOfTwo / 2;
      
    
    
    //println(xInterval);
    
    
    //xInterval = (int) (floor(tempx / (pow(10, powx) * 2)) + 1) * (pow(10, powx - 1) * 2);
    /*if(tempx >= 10 || tempx < 1) {
      if(tempx < pow(10, powx) * 2) {
        xInterval = (int) pow(10, powx - 1) * 2;
      } else if(tempx < pow(10, powx) * 4) {
        xInterval = (int) pow(10, powx - 1) * 4;
      } else if(tempx < pow(10, powx) * 8) {
        xInterval = (int) pow(10, powx - 1) * 8;
      } else {
        xInterval = (int) pow(10, powx);
      }
    }*/
    
    //println(tempx + ", " + (pow(10, powx)) + ", " + (tempx - pow(10, powx)));
    
    /*if(xInterval >= 10) {
      xInterval = (int) roundTo((float) xInterval, (double) 5);
      xRounding = true;
    } else if(xInterval >= 0.75) {
      xInterval = roundTo((camX[1] - camX[0]) / 10, (double) 2);
      xRounding = true;
    } else {
      double xi = xInterval;
      int counter = 0;
      while(xi < 1) {
        xi *= 10;
        counter++;
      }
      xInterval = roundTo((camX[1] - camX[0]) / 10, (double) pow(10, -counter));
      xRounding = false;
    }*/
    
    if(yInterval >= 10) {
      yInterval = (int) roundUpTo((float) yInterval, (double) 5);
      yRounding = true;
    } else if(yInterval >= 0.75) {
      yInterval = roundUpTo((camY[1] - camY[0]) / 10, (double) 2);
      yRounding = true;
    } else {
      double yi = yInterval;
      int counter = 0;
      while(yi < 1) {
        yi *= 10;
        counter++;
      }
      yInterval = roundUpTo((camY[1] - camY[0]) / 10, (double) pow(10, -counter));
      yRounding = false;
    }
    
    for(float i = roundUpTo(camX[0], xInterval); i < camX[1]; i += xInterval) {
      textAlign(CENTER, CENTER);
      if(xInterval < 1) {
        text(str(round(i * 10.0f) / 10.0f), map(i, camX[0], camX[1], xBound[0], width - xBound[1]), height - yBound[0] + 10);
      } else {
        text((int) i, map(i, camX[0], camX[1], xBound[0], width - xBound[1]), height - yBound[0] + 10);
      }
      /*if(xRounding) {
        text((int) i, map(i, camX[0], camX[1], xBound[0], width - xBound[1]), height - yBound[0] + 10);
      } else {
        String iString = nf(i);
        int decLen = split(iString, '.').length > 1 ? split(iString, '.')[1].length() : 0;
        iString = iString.substring(0, decLen);
        //if(i == roundTo(camX[0], xInterval)) println(xInterval + ", " + decLen + ", " + i + ", " + iString);
        text(iString, map(i, camX[0], camX[1], xBound[0], width - xBound[1]), height - yBound[0] + 10);
      }*/
    }
    
    for(float i = roundUpTo(camY[0], yInterval); i < camY[1]; i += yInterval) {
      textAlign(RIGHT, CENTER);
      if(yInterval < 1) {
        text(str(round(i * 10.0f) / 10.0f), xBound[0] - 5, map(i, camY[0], camY[1], height - yBound[0], yBound[1]));
      } else {
        text((int) i, xBound[0] - 5, map(i, camY[0], camY[1], height - yBound[0], yBound[1]));
      }
      /*if(yRounding) {
        text((int) i, xBound[0] - 5, map(i, camY[0], camY[1], height - yBound[0], yBound[1]));
      } else {
        String iString = nf(i);
        int decLen = split(iString, '.').length > 1 ? split(iString, '.')[1].length() : 0;
        iString = iString.substring(0, iString.length() - decLen + (decLen == 0 ? 0 : 1));
        text(iString, xBound[0] - 5, map(i, camY[0], camY[1], height - yBound[0], yBound[1]));
      }*/
    }
    
    
      //show/hide coordinates
    if(spacePressed && mouseX > xBound[0] && mouseX < width - xBound[1] && mouseY > yBound[1] && mouseY < height - yBound[0]) {
      float hoverX = (float) round(map(mouseX, xBound[0], width - xBound[1], camX[0], camX[1]) * 10) / 10;
      float hoverY = (float) round(map(mouseY, height - yBound[0], yBound[1], camY[0], camY[1]) * 10) / 10;
      String text = str(hoverX) + ", " + str(hoverY);
      fill(#ffffff);
      stroke(#cccccc);
      strokeWeight(2);
      rect(mouseX, mouseY - 25, text.length() * 10 - 12, 25, 3);
      textSize(15);
      textAlign(LEFT, BOTTOM);
      fill(#000000);
      text(hoverX + ", " + hoverY, mouseX + 5, mouseY - 3);
    }
  }
}
