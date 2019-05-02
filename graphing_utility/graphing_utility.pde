import java.util.*; 
import java.io.*;

int w = 1280;
int h = 720;

Table csvData;
String dataPath = "fifth_launch_smooth";
String[] fileData;
float[][] data;
float[] maxPoint;
float[] minPoint;
float[] maxLength;
float[] maxWidth;
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
float xInterval;
float yInterval;
int numLabels;
int numLines;
int numPoints;
int graphID;
int zoomFocus;
boolean autoZooming = false;
boolean zooming = false;
boolean zoomedToFit = false;
boolean graphMode = true;
boolean dragging = false;
boolean bothKeysPressed = true;
boolean spacePressed = false;
boolean ctrlPressed = false;
boolean altPressed = false;
boolean originOnTop = false;
color bgCol = #f2f2f2;

float[] xBound = {100, 300};
float[] yBound = {25, 25};
float[] startCamX = {-10, 15.4};
float[] startCamY = {-19000, 20000};
float[] zoomScale = {0.5, 10};
float zoomSpd = 0.4;
float clickZoomSpd = 5;

int dataTextSize = 20;
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
float dataScrolling = 0;
float offset;
float[] horScrollbar = {0, 100};
float[] verScrollbar = {0, 50};
boolean shiftPressed = false;

float minStroke = 3;
float maxStroke = 12;
float strokeScale = 1;
float hoverSize = 1.5;
int lineHover = -1;
color hoverCol = #4d4d4d;
color hoverPointCol = #cccccc;

String inputText;
int inputMode = 0;
int inputSlot = 0;
float inputStore;

String[] labels = {};
float boxSize = 20;

color[] colors = {#ff0000, #ff8000, #ffcc00, #ace600, #00e64a, #00e6b8, #00ace6, #0017e6, #d500e6};
boolean[] lineToggle;

boolean good = false;

void mousePressed() {
  clickPos[0] = mouseX;
  clickPos[1] = mouseY;
        
  if(checkRect(mouseX, mouseY, xBound[0], yBound[1], graphWidth, graphHeight)) {
    if(mouseButton == CENTER && graphMode) {
      if(!zooming) {
          //click (and zoom) graph
        for(int i = 0; i < 2; i++) {
          oldCamX[i] = camX[i];
          oldCamY[i] = camY[i];
        }
        if(shiftPressed) zoomFocus = 1;
        else if(ctrlPressed) zoomFocus = 2;
        else zoomFocus = 0;
        zooming = true;
      }
    } else if(mouseButton == LEFT) {
      if(!dragging) {
          //click (and drag) graph
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
  } else if(!graphMode && checkRect(mouseX, mouseY, horScrollbar[0], height - yBound[1] + 5, horScrollbar[1], 10)) {
      //click + drag horizontal data scroll bar
    offset = clickPos[0] - horScrollbar[0];
    dataScrolling = 1;
  } else if(!graphMode && checkRect(mouseX, mouseY, width - xBound[1] + 5, verScrollbar[0], 10, verScrollbar[1])) {
      //click + drag vertical data scroll bar
    offset = clickPos[1] - verScrollbar[0];
    dataScrolling = 2;
  } else if(checkRect(mouseX, mouseY, width - xBound[1] + 20, yBound[0] * 1.25, 100, 45)) {
        //show/hide all lines
      if(allTrueFalse(lineToggle, true)) Arrays.fill(lineToggle, false);
      else Arrays.fill(lineToggle, true);
  } else if(checkRect(mouseX, mouseY, width - xBound[1] + 140, yBound[0] * 1.25, 140, 45)) {
        //toggle graph mode
      graphMode = !graphMode;
  } else {
      //show/hide a single line
    if(mouseX > width - xBound[1] + 50 && mouseX < width - xBound[1] + 50 + boxSize) {
      for(int i = 1; i < numLabels; i++) {
        if(mouseY > (graphHeight / numLabels) * i + (yBound[0] * 2)
          && mouseY < (graphHeight / numLabels) * i + (yBound[0] * 2) + boxSize) {
            
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
          } else if(shiftPressed) {
              //zoom to fit selected points within current camera view
            zoomWithinDomain(camX, 7);
          }
        }
      }
    }
  }
}

void mouseReleased() {
  dragging = false;
  zooming = false;
  dataScrolling = 0;
}

void mouseWheel(MouseEvent event) {
  autoZooming = false;
  if(mouseX > xBound[0] && mouseX < width - xBound[1] && mouseY > yBound[0] && mouseY < height - yBound[1]) {
    if(graphMode) {
      bothKeysPressed = ctrlPressed == shiftPressed;
      float e = event.getCount();
      float mx = altPressed ? 0.5 : map(mouseX, xBound[0], width - xBound[1], 0, 1);
      float my = altPressed ? 0.5 : map(mouseY, height - yBound[1], yBound[0], 0, 1);
      float cw = camX[1] - camX[0];
      float ch = camY[1] - camY[0];
      float[] zoomx = {camX[0], camX[1]};
      float[] zoomy = {camY[0], camY[1]};
      if(bothKeysPressed || shiftPressed) zoomx[0] += (zoomSpd * cw) * mx * (e * -1);
      if(bothKeysPressed || shiftPressed) zoomx[1] += (zoomSpd * cw) * (1-mx) * e;
      if(bothKeysPressed || ctrlPressed) zoomy[0] += (zoomSpd * ch) * my * (e * -1);
      if(bothKeysPressed || ctrlPressed) zoomy[1] += (zoomSpd * ch) * (1-my) * e;
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
  if(inputMode == 0) {
    switch(key) {
      case ' ':
        spacePressed = true;
        break;
      case 'x':
        inputMode = 1;
        inputSlot = 0;
        inputText = "";
        inputStore = Float.NaN;
        zooming = false;
        autoZooming = false;
        break;
      case 'y':
        inputMode = 2;
        inputSlot = 0;
        inputText = "";
        inputStore = Float.NaN;
        zooming = false;
        autoZooming = false;
        break;
      case 'o':
        originOnTop = !originOnTop;
        break;
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
        if(shiftPressed) zoomWithinDomain(camX, 10);
        else zoomToSelected(10);
        break;
      case ESC:
        key = 0;
        inputMode = 0;
        break;
    }
  } else {
    if(keyCode == ESC) {
      key = 0;
      inputMode = 0;
      inputText = "";
      return;
    }
    if(keyCode == ENTER || key == ',' || key == ' ' && inputText.length() > 0) {
      if(inputSlot == 1) {
        if(inputMode == 1) {
          camX[0] = inputStore;
          camX[1] = float(inputText);
          if(camX[0] > camX[1]) {
            float store = camX[0];
            camX[0] = camX[1];
            camX[1] = store;
          } else if(camX[0] == camX[1]) {
            camX[0]--;
            camX[1]++;
          }
        } else {
          camY[0] = inputStore;
          camY[1] = float(inputText);
          if(camX[0] > camY[1]) {
            float store = camY[0];
            camY[0] = camY[1];
            camY[1] = store;
          } else if(camY[0] == camY[1]) {
            camY[0]--;
            camY[1]++;
          }
        }
        inputMode = 0;
      } else {
        inputStore = float(inputText);
        inputSlot++;
        inputText = "";
      }
      return;
    }
    if(key == '=') {
      inputText = str(inputMode == 1 ? camX[inputSlot] : camY[inputSlot]);
    } else if(str(key).matches("-?[.0-9]+") || (str(key).matches("-?[-]") && inputText.length() == 0)) {
      if(inputText.length() < 7) inputText += key;
    } else if(keyCode == BACKSPACE && inputText.length() > 0) {
      inputText = inputText.substring(0, inputText.length() - 1);
    }
  }
}

void keyReleased() {
  switch(key) {
    case ' ':
      spacePressed = false;
      break;
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
  graphHeight = (height - yBound[1]) - yBound[0];
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
    maxWidth = new float[numLines];
    Arrays.fill(maxPoint, Float.NaN);
    Arrays.fill(minPoint, Float.NaN);
    for(int i = 0; i < numLines; i++) {
      labels[i] = csvData.getColumnTitle(i);
      for(int j = 0; j < numPoints; j++) {
        data[i][j] = csvData.getFloat(j, i);
        if(data[i][j] > maxPoint[i] || maxPoint[i] != maxPoint[i]) maxPoint[i] = data[i][j];
        //println(data[i][j] + ", " + getTextWidth(str(data[i][j]), dataTextSize) + ", " + maxWidth[i]);
        if(getTextWidth(str(data[i][j]), dataTextSize) > maxWidth[i]) {
          maxLength[i] = data[i][j];
          if(round(maxPoint[i]) == maxPoint[i]) maxWidth[i] = getTextWidth(str(int(maxLength[i])), dataTextSize) + 25;
          else maxWidth[i] = getTextWidth(str(maxLength[i]), dataTextSize) + 25;
          if(maxWidth[i] < getTextWidth(labels[i], dataTextSize) + 15) maxWidth[i] = getTextWidth(labels[i], dataTextSize) + 15;
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
    maxWidth = new float[numLines];
    Arrays.fill(maxPoint, Float.NaN);
    Arrays.fill(minPoint, Float.NaN);
    for(int i = 0; i < numPoints; i++) {
      temp = split(fileData[i + 1], ",");
      for(int j = 0; j < temp.length; j++) {
        data[j][i] = float(temp[j]);
        if(float(temp[j]) > maxPoint[j] || maxPoint[j] != maxPoint[j]) maxPoint[j] = float(temp[j]);
        
        if(getTextWidth(str(data[i][j]), dataTextSize) > maxWidth[j]) {
          maxLength[j] = data[j][i];
          if(round(maxPoint[j]) == maxPoint[j]) maxWidth[j] = getTextWidth(str(int(maxLength[j])), dataTextSize) + 25;
          else maxWidth[j] = getTextWidth(str(maxLength[j]), dataTextSize) + 25;
          if(maxWidth[j] < getTextWidth(labels[j], dataTextSize) + 15) maxWidth[j] = getTextWidth(labels[j], dataTextSize) + 15;
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
  for(int i = 0; i < maxWidth.length; i++) {
    dataTotalWidth += maxWidth[i];
  }
  dataTotalWidth += (dataPadX) - graphWidth + (dataTextSize) - 10;
  dataTotalHeight = dataPadY + ((dataTextSize + 5) * numPoints * 2) - graphHeight;
  
  camX[0] = startCamX[0];
  camX[1] = startCamX[1];
  camY[0] = startCamY[0];
  camY[1] = startCamY[1];
  
  zoomToSelected(15);
}

void draw() {
  if((shiftPressed && ctrlPressed) || (!shiftPressed && !ctrlPressed)) bothKeysPressed = true;
  else bothKeysPressed = false;
  
  if(autoZooming && !allTrueFalse(lineToggle, false)) {
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
    autoZoomSpd *= 0.99;
  } else {
    autoZooming = false;
  }
  
  if(mousePressed) {
    if(dragging) {
      if(graphMode) {
        zoomedToFit = false;
        autoZooming = false;
        for(int i = 0; i < 2; i++) {
          if(bothKeysPressed || shiftPressed) {
            camX[i] = oldCamX[i] - ((mouseX - clickPos[0]) / (graphWidth / (camX[1] - camX[0])));
          } else {
            clickPos[0] = mouseX;
            oldCamX[i] = camX[i];
          }
          if(bothKeysPressed || ctrlPressed) {
            camY[i] = oldCamY[i] - ((clickPos[1] - mouseY) / (graphHeight / (camY[1] - camY[0])));
          } else {
            clickPos[1] = mouseY;
            oldCamY[i] = camY[i];
          }
        }
      } else {
        if(bothKeysPressed || shiftPressed) {
          dataCamX = oldDataCamX - ((mouseX - clickPos[0]));
        } else {
          clickPos[0] = mouseX;
          oldDataCamX = dataCamX;
        }
        if(bothKeysPressed || ctrlPressed) {
          dataCamY = oldDataCamY - ((clickPos[1] - mouseY)) * -1;
        } else {
          clickPos[1] = mouseY;
          oldDataCamY = dataCamY;
        }
      }
    } else if(zooming && graphMode) {
      zoomedToFit = false;
      autoZooming = false;
      float[] graphPos = getGraphPos(mouseX, mouseY);
      float[] oldGraphPos = getGraphPos(clickPos[0], clickPos[1]);
      if(zoomFocus == 0 || zoomFocus == 1) {
        camX[0] += map(graphPos[1], 0, graphHeight, camX[0], camX[1]) - map(oldGraphPos[1], 0, graphHeight, camX[0], camX[1]);
        camX[1] -= map(graphPos[1], 0, graphHeight, camX[0], camX[1]) - map(oldGraphPos[1], 0, graphHeight, camX[0], camX[1]);
      }
      if(zoomFocus == 0 || zoomFocus == 2) {
        camY[0] += map(graphPos[1], 0, graphHeight, camY[0], camY[1]) - map(oldGraphPos[1], 0, graphHeight, camY[0], camY[1]);
        camY[1] -= map(graphPos[1], 0, graphHeight, camY[0], camY[1]) - map(oldGraphPos[1], 0, graphHeight, camY[0], camY[1]);
      }
      clickPos[1] = mouseY;
    } else if(dataScrolling > 0 && !graphMode) {
      if(dataScrolling == 1) {
        horScrollbar[0] = mouseX - offset;
        dataCamX = map(horScrollbar[0], xBound[0] + dataPadX + 5, width - xBound[1] - horScrollbar[1] - 5, 0, dataTotalWidth);
      } else {
        verScrollbar[0] = mouseY - offset;
        dataCamY = map(verScrollbar[0], yBound[0] + dataPadY + 5, height - yBound[1] - verScrollbar[1] - 5, 0, dataTotalHeight);
      }
    }
  }
  
  background(bgCol);
  
  if(graphMode) {
      //draw origin lines
    if(!originOnTop) drawOriginLines(false);
    
      //draw graph lines
    stroke = constrain(maxStroke - ((camX[1] - camX[0]) / (numPoints * dataInterval) / strokeScale * (minStroke + (maxStroke / minStroke))), minStroke, maxStroke);
    strokeWeight(stroke);
    for(int i = 0; i < numLines; i++) {
      for(int j = 1; j < numPoints; j++) {
        if(lineToggle[i] && lineHover != i) {
            stroke(colors[i]);
            graphLine(i, (j-1) * dataInterval, data[i][j-1], j * dataInterval, data[i][j]);
        } else {
          continue;
        }
      }
    }
    if(lineHover != -1 && lineToggle[lineHover]) {
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
    
      //draw origin lines
    if(originOnTop) drawOriginLines(true);
  } else {
      //show data view
    if(dataCamX > dataTotalWidth) dataCamX = dataTotalWidth;
    if(dataCamY > dataTotalHeight) dataCamY = dataTotalHeight;
    if(dataCamX < 0) dataCamX = 0;
    if(dataCamY < 0) dataCamY = 0;
      
    textSize(dataTextSize);
    textAlign(LEFT, TOP);
    strokeWeight(2);
    
    float xpos = dataPadX - dataCamX;
    
    textAlign(LEFT, TOP);
    fill(#000000);
    
      //render data
    for(int i = 0; i < numLines; i++) {
      for(int j = 0; j < numPoints; j++) {
        float ypos = dataPadY + ((dataTextSize + 5) * j * 2) - dataCamY;
        if(round(data[i][j]) == data[i][j]) text(int(data[i][j]), xBound[0] + xpos + 10, yBound[0] + ypos);
        else text(str(data[i][j]), xBound[0] + xpos + 10, yBound[0] + ypos);
      }
      xpos += maxWidth[i];
    }
    
      
    fill(dataLabelBG);
    noStroke();
    rect(xBound[0], yBound[0], dataPadX, graphHeight);
    rect(xBound[0], yBound[0], graphWidth, dataPadY);
    stroke(#000000);
    
    xpos = dataPadX - dataCamX;
    
      //data labels (x-axis)
    for(int i = 0; i < numLines; i++) {
      if(xpos > dataPadX) line(xBound[0] + xpos, yBound[0], xBound[0] + xpos, height - yBound[1]);
      
      fill(colors[i]);
      text(labels[i], xBound[0] + xpos + 5, yBound[0] + (dataTextSize));
      if(xBound[0] + xpos > width - xBound[1]) break;
      xpos += (maxWidth[i]);
    }
    line(xBound[0] + xpos, yBound[0], xBound[0] + xpos, height - yBound[1]);
    
    
    textAlign(LEFT, TOP);
    fill(#000000);
    
      //data interval labels (y-axis)
    for(int i = 0; i < numPoints; i++) {
      float ypos = dataPadY + ((dataTextSize + 5) * i * 2) - dataCamY;
      if(ypos > dataPadY) line(0, yBound[0] + ypos, width - xBound[1] + dataTotalWidth - (dataTextSize / 2), yBound[0] + ypos);
      text(dataInterval * i, xBound[0] + 10, yBound[0] + ypos);
      if(yBound[0] + ypos > height - yBound[1]) break;
    }
    
    fill(dataLabelBG);
    noStroke();
    rect(xBound[0], yBound[0], dataPadX, dataPadY);
    stroke(#000000);
    strokeWeight(5);
    line(xBound[0] + (dataPadX), yBound[0], xBound[0] + (dataPadX), height - yBound[1]);
    line(0, yBound[0] + (dataPadY), width - xBound[1], yBound[0] + (dataPadY));
  }  //end data view
  
  
    //hide overflow
  fill(#ffffff);
  noStroke();
  rect(0, 0, xBound[0], height);
  rect(width - xBound[1], 0, width, height);
  rect(0, 0, width, yBound[0]);
  rect(0, height - yBound[1], width, height);
  
  if(!graphMode) {
      //data scroll bars
    fill(#a6a6a6);
    noStroke();
    verScrollbar[0] = map(dataCamY, 0, dataTotalHeight, yBound[0] + dataPadY + 5, height - yBound[1] - verScrollbar[1] - 5);
    horScrollbar[0] = map(dataCamX, 0, dataTotalWidth, xBound[0] + dataPadX + 5, width - xBound[1] - horScrollbar[1] - 5);
    if(dataTotalHeight + dataPadY > graphHeight) rect(width - xBound[1] + 5, verScrollbar[0], 10, verScrollbar[1], 5);
    if(dataTotalWidth > 0) rect(horScrollbar[0], height - yBound[1] + 5, horScrollbar[1], 10, 5);
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
    rect(width - xBound[1] + 50, (graphHeight / numLabels) * i + (yBound[0] * 2), boxSize, boxSize, 5);
    fill(colors[i-1]);
    textSize(25);
    textAlign(LEFT, CENTER);
    text(labels[i-1], width - xBound[1] + 60 + boxSize, (graphHeight / numLabels) * i + (yBound[0] * 2) + 7);
    if(mouseX > width - xBound[1] + 50 && mouseX < width - xBound[1] + 50 + boxSize && mouseY > (graphHeight / numLabels) * i + (yBound[0] * 2) && mouseY < (graphHeight / numLabels) * i + (yBound[0] * 2) + boxSize) {
      lineHover = i-1;
    }
  }
  
  fill(#aaaaaa);
  rect(width - xBound[1] + 20, yBound[0] * 1.25, 100, 45, 2);
  rect(width - xBound[1] + 140, yBound[0] * 1.25, 140, 45, 2);
  fill(#000000);
  textSize(20);
  textAlign(CENTER, CENTER);
  if(allTrueFalse(lineToggle, true)) text("Hide All", width - xBound[1] + 70, yBound[0] * 1.25 + 20);
  else text("Show All", width - xBound[1] + 70, yBound[0] * 1.25 + 20);
  if(graphMode) text("Show Data", width - xBound[1] + 210, yBound[0] * 1.25 + 20);
  else text("Show Graph", width - xBound[1] + 210, yBound[0] * 1.25 + 20);
  
  if(graphMode) {
       //grid lines
    stroke(#000000);
    
    strokeWeight(5);
    line(xBound[0], yBound[0], xBound[0], height - yBound[1]);
    line(xBound[0], height - yBound[1], width - xBound[1], height - yBound[1]);
    
    
      //axis intervals
    fill(#000000);
    xInterval = (camX[1] - camX[0]);
    yInterval = (camY[1] - camY[0]);
    
    if(xInterval > 2) xInterval = (xInterval / 2) * (0.2 + (0.07 * str((int) xInterval).length() / 2));
    else xInterval = (xInterval / 2) * ((0.7 * str(roundDownTo(xInterval, roundToPowOfTen(xInterval * 10.0f))).length() / 2) - 0.75);
    float powOfTwo;
    if(xInterval > 2) {
      powOfTwo = 2;
      while(powOfTwo < xInterval) {
        powOfTwo *= 2;
      }
      xInterval = powOfTwo / 2;
    } else {
      powOfTwo = 0.5;
      while(powOfTwo > xInterval) {
        powOfTwo /= 2;
      }
      xInterval = powOfTwo * 2;
    }
    
    yInterval = yInterval / 8;
    if(yInterval > 8) powOfTwo = 2;
    else powOfTwo = pow(10, (getPowerOfTen(yInterval) - 1)) * 2;
    
    while(powOfTwo < yInterval) {
      powOfTwo *= 2;
    }
    yInterval = powOfTwo / 2;
      
    for(float i = roundUpTo(camX[0], xInterval); i < camX[1]; i += xInterval) {
      textAlign(CENTER, CENTER);
      if(xInterval < 1) {
        text(str(floor(i * (100 / roundToPowOfTen(xInterval * 100.0f))) / (100 / roundToPowOfTen(xInterval * 100.0f))), map(i, camX[0], camX[1], xBound[0], width - xBound[1]), height - yBound[1] + 10);
      } else {
        text((int) i, map(i, camX[0], camX[1], xBound[0], width - xBound[1]), height - yBound[1] + 10);
      }
    }
    
    for(float i = roundUpTo(camY[0], yInterval); i < camY[1]; i += yInterval) {
      textAlign(RIGHT, CENTER);
      if(yInterval < 1) {
        text(str(floor(i * (100 / roundToPowOfTen(yInterval * 100.0f))) / (100 / roundToPowOfTen(yInterval * 100.0f))), xBound[0] - 5, map(i, camY[0], camY[1], height - yBound[1], yBound[0]));
      } else {
        text((int) i, xBound[0] - 5, map(i, camY[0], camY[1], height - yBound[1], yBound[0]));
      }
    }
    
    
      //show/hide coordinates
    if(spacePressed && mouseX > xBound[0] && mouseX < width - xBound[1] && mouseY > yBound[0] && mouseY < height - yBound[1]) {
      float hoverX = (float) round(map(mouseX, xBound[0], width - xBound[1], camX[0], camX[1]) * 10) / 10;
      float hoverY = (float) round(map(mouseY, height - yBound[1], yBound[0], camY[0], camY[1]) * 10) / 10;
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
  if(inputMode > 0) {
    textSize(20);
    textAlign(LEFT, CENTER);
    fill(#FFFFFF);
    rect(xBound[0] + 10, height - yBound[0] - 45, graphWidth - 20, 35);
    fill(#000000);
    if(inputStore == inputStore) text((inputMode == 1 ? "x" : "y") + " = {" + inputStore + ", " + inputText, xBound[0] + 20, height - yBound[0] - 30);
    else if(inputText.length() > 0) text((inputMode == 1 ? "x" : "y") + " = {" + inputText, xBound[0] + 20, height - yBound[0] - 30);
    else text((inputMode == 1 ? "x" : "y") + " = {", xBound[0] + 20, height - yBound[0] - 30);
  }
}