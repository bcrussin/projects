import processing.serial.*;
Serial myPort;
 
//customizable variables:
int numRows = 100;
int avgBuffer = 10;
float borderHeight = 90;
 
boolean paused = false;
boolean tracking = true;
boolean selecting = false;
boolean hovering;
boolean PID;
int recentSet;
int recentAct;
int mouseCellX;
float screenHeight;
float rowSize;
float startTime = -1;
float totalTime;
float elapsedTime;
float speedDiffTotal;
float selectDiffTotal;
float hoverSet;
float hoverAct;
float millisClicked;
float recentLength;
float average = 0;
float[] newVals = {0, 0};
float[] select = new float[3];
String myStr;
FloatList setSpeed;
FloatList actSpeed;
FloatList setAvg;
FloatList actAvg;
FloatList setAvgSel;
FloatList actAvgSel;
FloatList setDisp;
FloatList actDisp;
FloatList speedDiff;
FloatList secPos;
FloatList pausePos;
IntList secList;
ArrowButton b1, b2;
 
class ArrowButton {  //a quick constructor that allows the easy creation of clickable buttons
  float x, y, w, h, clickTime;
  int dir;
  color onCol, offCol, arrowCol, clickCol, col;
  boolean clicked, justClicked, held = false;
 
  ArrowButton(float tx, float ty, float tw, float th, int tDir, color tOffCol, color tOnCol, color tClickCol, color tArrowCol) {
    x = tx;
    y = ty;
    w = tw;
    h = th;
    dir = tDir;
    onCol = tOnCol;
    offCol = tOffCol;
    clickCol = tClickCol;
    arrowCol = tArrowCol;
  }
 
  void update() {  //update the arrow's colors depending on if the mouse is over it or it is being clicked
    if (mouseRect(x, y, x + w, y + h)) {
      if (mousePressed && justClicked == false) {
        col = clickCol;
        clicked = true;
        clickTime = totalTime;
      } else if(mousePressed && totalTime - clickTime > 500) {
        clicked = true;
        held = true;
      } else if(mousePressed) {
        col = clickCol;
      } else {
        col = onCol;
      }
    } else {
      col = offCol;
    }
 
     if (!mousePressed) {
        justClicked = false;
        held = false;
     }
  }
 
  void disp() {  //manually render the arrow depending on its direction
    fill(col);
    strokeWeight(1);
    rect(x, y, w, h);
    fill(arrowCol);
    if (dir == 1) triangle(x + (w / 2), y + (h / 4), x + (w / 4), y + h - (h / 4), x + w - (w / 4), y + h - (h / 4));  //up
    else if (dir == 2) triangle(x + (w / 4), y + (w / 4), x + w - (w / 4), y + (h / 2), x + (w / 4), y + w - (w / 4));  //right
    else if (dir == 3) triangle(x + (w / 2), y + h - (h / 4), x + (w / 4), y + (h / 4), x + w - (w / 4), y + (h / 4));  //down
    else triangle(x + w - (w / 4), y + (w / 4), x + (w / 4), y + (h / 2), x + w - (w / 4), y + w - (w / 4));  //left
  }
 
}
 
void setup() {
  size(1000, 1000);
  screenHeight = height - borderHeight;
  setSpeed = new FloatList();
  actSpeed = new FloatList();
  setAvg = new FloatList();
  actAvg = new FloatList();
  setAvgSel = new FloatList();
  actAvgSel = new FloatList();
  speedDiff = new FloatList();
  secPos = new FloatList();
  pausePos = new FloatList();
  secList = new IntList();
  setDisp = new FloatList();
  actDisp = new FloatList();
  rowSize = float(width) / numRows;
  b1 = new ArrowButton((width / 1.5) - 22, 0, 20.0, 15.0, 1, #d9d9d9, #999999, #333333, #666666);  //both arrow buttons are initialized
  b2 = new ArrowButton((width / 1.5) - 22, 15, 20.0, 15.0, 3, #d9d9d9, #999999, #333333, #666666);
  println("Available serial ports:");
  println(Serial.list());
  myPort = new Serial(this, Serial.list()[1], 9600);
}
 
void draw() {
  background(#3399ff);
 
  if (!paused) {
 
  if ( myPort.available() > 0)  //begin reading data from the serial port
  { 
    if (startTime < 0) startTime = millis();
    else totalTime = millis() - startTime;
    myStr = myPort.readStringUntil('\n');
    if(myStr != null) 
    {
      myStr = myStr.trim();
      println("myStr: " + myStr);
      String[] newValsStr = split(myStr, ',');  //separate the string recieved from Arduino to two variables (setSpeed, actSpeed, and PID enabled/disabled)
      for (int i = 0; i < newValsStr.length - 1; i++) newVals[i] = map(float(newValsStr[i]), 0, 1000, 0, screenHeight);
      if(newValsStr.length > 2 && int(newValsStr[2]) == 1) PID = true;  //determine if PID is enabled or not
      else PID = false;
      setSpeed.append(newVals[0]);  //add the new data to either the setSpeed list or the actSpeed list
      if (setSpeed.size() > numRows) setSpeed.remove(0);  
      actSpeed.append(newVals[1]);
      if (actSpeed.size() > numRows) actSpeed.remove(0);  //add the difference between set and actual to another list
      speedDiff.append(setSpeed.get(setSpeed.size() - 1) - actSpeed.get(actSpeed.size() - 1));
      if (speedDiff.size() > numRows) speedDiff.remove(0);
 
      if(avgBuffer < 1) avgBuffer = 1;
      if(avgBuffer > numRows - 1) avgBuffer = numRows - 1;
      if(setSpeed.size() > avgBuffer) {  //average the speed variables depending on the buffer
        average = 0;       
        for(int i = 0; i < avgBuffer; i++) average += setSpeed.get(setSpeed.size() - i - 1);
        average /= avgBuffer;
        setAvg.append(average);
        setDisp.append(map(average, 0, screenHeight, screenHeight, 0));
        if(setAvg.size() > numRows) {
          setAvg.remove(0);
          setDisp.remove(0);
        }
        average = 0;
 
        for(int i = 0; i < avgBuffer; i++) average += actSpeed.get(actSpeed.size() - i - 1);
        average /= avgBuffer;
        actAvg.append(average);
        actDisp.append(map(average, 0, screenHeight, screenHeight, 0));
        if(actAvg.size() > numRows) {
          actAvg.remove(0);
          actDisp.remove(0);
        }
      }
 
      for(int i = 0; i < pausePos.size(); i++) {  //keep track of when the code is paused to display a break line
        pausePos.sub(i, rowSize);
        if(pausePos.get(i) < 0) pausePos.remove(i);
      }
 
      speedDiffTotal = 0;  //calculate the average of the set and actual speed differences
      for (int i = 0; i < speedDiff.size(); i++) {
        speedDiffTotal += speedDiff.get(i);
      }
      speedDiffTotal /= speedDiff.size();
 
      selectDiffTotal = 0;  //calculate the average difference of points within the selection
      if(select[0] > 0 && select[1] > 0) {
        for (int i = int(select[0] / rowSize); i < int(select[1] / rowSize); i++) {
          if(speedDiff.size() > i) selectDiffTotal += speedDiff.get(i);
        }
        selectDiffTotal /= int(select[1] / rowSize) - int(select[0] / rowSize);
      }
 
      for (int i = 0; i < secPos.size(); i++) {  //move the time counters accross the screen
        if (!(setSpeed.size() < numRows)) secPos.sub(i, rowSize);
        if (secPos.get(i) < 0) {
          secPos.remove(i);
          secList.remove(i);
        }
      }
 
      if (totalTime >= elapsedTime + 1000) {  //add a time counter every second
        secPos.append(setSpeed.size() * rowSize);
        secList.append(round(totalTime / 1000));
        elapsedTime = totalTime;
      }
 
      if(tracking && (select[0] > 0 || select[1] > 0)) {  //move the selection
        if(select[0] <= rowSize) select[0] = rowSize;
        else select[0] -= rowSize;
        if(select[1] <= rowSize) select[1] = rowSize;
        else select[1] -= rowSize;
      }
    }
  }
 
  } else if (myPort.available() > 0) {  //(this is the else statement for the if paused statement
    myStr = myPort.readStringUntil('\n');
  } 
 
  //end 'if !paused' statement
 
  fill(#ff9966);
  stroke(#ff6600);
 
  //DISPLAY ALL PLOT POINTS:
 
  if (str(recentAct).length() > str(recentSet).length()) recentLength = str(recentAct).length();  //store the length of the most recent set or actual value, depending on which is longer (used for text purposes)
  else recentLength = str(recentSet).length();
 
  if(setDisp.size() > 5) {
    for (int i = 0; i < setDisp.size(); i++) {  //plot the set-speed points
       strokeWeight(3);
       if (i > 1) line((i - 1) * rowSize, setDisp.get(i - 1) + borderHeight, i * rowSize, setDisp.get(i) + borderHeight);
       strokeWeight(1);
       fill(#ff9966);
       stroke(#ff6600);
       rect((i * rowSize) - (rowSize / 2), setDisp.get(i) - (rowSize / 2) + borderHeight, rowSize, rowSize);
    }
  }
 
  fill(#66ff33);
  stroke(#33cc33);
 
  if(actDisp.size() > 5) {
    for (int i = 0; i < actAvg.size(); i++) {  //plot the actual-speed points
       strokeWeight(3);
       if (i > 1) line((i - 1) * rowSize, actDisp.get(i - 1) + borderHeight, i * rowSize, actDisp.get(i) + borderHeight);
       strokeWeight(1);
       fill(#66ff33);
       stroke(#33cc33);
       rect((i * rowSize) - (rowSize / 2), actDisp.get(i) - (rowSize / 2) + borderHeight, rowSize, rowSize);
    }
  }
 
  stroke(#808080);
  strokeWeight(2);
  for(int i = 0; i < pausePos.size(); i++) {  //display a break line for every code pause
    line(pausePos.get(i), borderHeight, pausePos.get(i), height);
  }
 
  //DISPLAY ALL TEXT:
 
  fill(#0066ff, 200);
  rect(0, 0, width, borderHeight);
 
  fill(#000000);
  stroke(#000000);
  textSize(constrain(rowSize * 2, 10, 75));
 
  for(int i = 0; i < secPos.size(); i++) {  //plot the time counters
    text(secList.get(i), secPos.get(i), height);
  }
 
  textSize(sqrt(width) - 5);
  if (speedDiff.size() > 0) text("Speed Difference: " + str(roundNum(speedDiff.get(speedDiff.size() - 1), 2)), 5, sqrt(screenHeight) - 5);
  text("Average Speed Difference: " + str(roundNum(speedDiffTotal, 2)), 5, (sqrt(screenHeight) - 5) * 2);
  text("Selection Speed Difference: " + str(roundNum(selectDiffTotal, 2)), 5, (sqrt(screenHeight) - 5) * 3);
  text("Buffer: " + str(avgBuffer), width / 1.5, sqrt(screenHeight) - 5);
  text("PID", width / 1.17, sqrt(screenHeight) - 5);
  if(PID) {
    fill(#33cc33);
    text("ON", width / 1.167, (sqrt(screenHeight) - 5) * 2);
  } else {
    fill(#cc0000);
    text("OFF", width / 1.175, (sqrt(screenHeight) - 5) * 2);
  }
 
  fill(#000000);
  text("'p' = pause", width / 1.95, (sqrt(screenHeight) - 5) * 2.25);
  text("space = toggle selection movement", width / 1.95, (sqrt(screenHeight) - 5) * 3.25);
 
  fill(#000000);
 
  if (setAvg.size() > 0) recentSet = int(setAvg.get(setAvg.size() - 1));  //store most recent set value
  if (actAvg.size() > 0) recentAct = int(actAvg.get(actAvg.size() - 1));  //store most recent actual value
  fill(#ff9966);
  if (setSpeed.size() > 0) text(recentSet, width - (str(recentSet).length() * (((sqrt(width) - 5) + rowSize) / 2)), (sqrt(width) - 5));
  fill(#66ff33);
  if (actSpeed.size() > 0) text(recentAct, width - (str(recentAct).length() * (((sqrt(width) - 5) + rowSize) / 2)), (sqrt(width) - 5) * 2);
 
  //ADD BUTTON FUNCTIONALITY:
 
  b1.update();
  if (b1.clicked) {
    avgBuffer += 1;
    if(!b1.held) b1.clicked = false;
    b1.justClicked = true;
  }
  b1.disp();
 
  b2.update();
  if (b2.clicked) {
    avgBuffer -= 1;
    if(!b2.held) b2.clicked = false;
    b2.justClicked = true;
  }
  b2.disp();
 
  //RENDER SELECTION AND HOVER VALUES:
 
  checkMouse();
  textSize(sqrt(width) / 2.5);
  if(hovering) {
    fill(#FFFFFF, 75);
    stroke(#FFFFFF);
    String hoverText = str(hoverSet) + ", " + str(hoverAct);
    if(mouseX + (hoverText.length() * (sqrt(width) / 5) + 15) > width) {  //renders the mouse-over bubble differently depending on if it hits the right border or not
      rect(mouseX - 5 - ((mouseX + (hoverText.length() * (sqrt(width) / 5) + 15)) - width), mouseY - 20, hoverText.length() * (sqrt(width) / 5) + 15, 20, 5);
      fill(#000000);
      text(str(hoverSet) + ", " + str(hoverAct), mouseX - ((mouseX + (hoverText.length() * (sqrt(width) / 5) + 15)) - width), mouseY - 5);
    } else {
      rect(mouseX - 5, mouseY - 20, hoverText.length() * (sqrt(width) / 5) + 15, 20, 5);
      fill(#000000);
      text(str(hoverSet) + ", " + str(hoverAct), mouseX, mouseY - 5);
    }
  }
 
  fill(#ffcc99, 50);
  stroke(#ffcc99, 0);
  if(select[0] > select[1]) rect(select[1], 0, select[0] - select[1], screenHeight);
  else rect(select[0], borderHeight, select[1] - select[0], height);
  if(tracking) fill(#33cc33);
  else fill(#cc0000);
  ellipse(width / 2.025, (sqrt(screenHeight) - 5) * 2.9, 25, 25);
}
 
void keyPressed() {  //quick pause function
  if (key == 'p') {
    if (paused) {
      paused = false;
    } else {
      paused = true;
      pausePos.append(width);
    }
  }
 
  if (key == ' ') tracking = !tracking;
}
 
boolean mouseRect(float x1, float y1, float x2, float y2) {  //function to determine if the mouse is within a rectangular area
  if (mouseX > x1 && mouseX < x2 && mouseY > y1 && mouseY < y2) return true;
  else return false;
}
 
float roundNum(float number, int places) {
  number = round(number * pow(10, places)) / pow(10, places);
  return number;
}
 
void checkMouse() {  //update selection and hover text
  if(!mouseRect(b1.x,  b1.y, b2.x + b2.w, b2.y + b2.h)) {
    if(mousePressed && !selecting) {  //two variables store the start and endpoints of the selection
      select[0] = mouseX;
      select[1] = mouseX;
      millisClicked = millis();
      selecting = true;
    } else if(selecting) {
      select[1] = mouseX;
      if(!mousePressed) {
        selecting = false;
        if(millis() < millisClicked + 150) select[0] = select[1] = 0;
      }
    }
  }
 
  if(!mousePressed && select[0] > select[1]) {  //make sure the startpoint is smaller than the endpoint
    select[2] = select[0];
    select[0] = select[1];
    select[1] = select[2];
  }
 
  mouseCellX = int(mouseX / rowSize);
  if(setSpeed.size() > mouseCellX) {  //if the mouse is near a plot point, the set and actual points are stored for that X position
    if(setDisp.size() > mouseCellX && (abs(setDisp.get(mouseCellX) - map(mouseY, 0, screenHeight, screenHeight, 0)) < 25 || abs(actDisp.get(mouseCellX) - map(mouseY, 0, screenHeight, screenHeight, 0)) < 25)) hovering = true;
    else hovering = false;
 
    hoverSet = roundNum(setSpeed.get(mouseCellX), 2);
    hoverAct = roundNum(actSpeed.get(mouseCellX), 2);
  }
}
