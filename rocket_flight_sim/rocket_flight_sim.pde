import java.awt.*;
import java.awt.event.*;
import damkjer.ocd.*;

Camera cam;
Robot robot;
JSONObject keys;
PShape rocket;

float[] camPos, camAtt, camTarg;
float x, y, z, t = 0;
float dmouseX, dmouseY;
float spd = 25;

  //INPUT FUNCTIONS
void keyPressed() {
  if(key == CODED) setKeyState(str(keyCode), true);
  else setKeyState(str(key), true);
}

void keyReleased() {
  if(key == CODED) setKeyState(str(keyCode), false);
  else setKeyState(str(key), false);
}


  //MAIN FUNCTIONS
void setup() {
  fullScreen(P3D);
  noCursor();
  
  try {
    robot = new Robot();
    robot.setAutoDelay(0);
  } catch (Exception e) {
    e.printStackTrace();
  }
  
  cam = new Camera(this);
  keys = parseJSONObject("{}");
  rocket = loadShape("rocket.obj");
}

void draw() {
  camPos = cam.position();
  camAtt = cam.attitude();
  camTarg = cam.target();
  cam.feed();
  
  background(0);
  lights();
  
  //rectPrism(vec3(0, 0, -100), vec3(100, 100, 100), vec3(0, 0, 0), #3399ff);
  shape(rocket);
  
  t += float(mouseX) / 640;
  x = mouseX;
  y = mouseY;
  
    //input
  if(isPressed("w")) cam.dolly(-spd);
  if(isPressed("s")) cam.dolly(spd);
  if(isPressed("d")) cam.truck(spd);
  if(isPressed("a")) cam.truck(-spd);
  if(isPressed("enter")) cam.aim(0, 0, 0);
  //if(isPressed("shift")) cam.jump(camPos[0], camPos[1] - spd, camPos[2]);
  //if(isPressed("ctrl")) cam.jump(camPos[0], camPos[1] + spd, camPos[2]);
  if(isPressed("shift")) moveCam(0, -spd, 0);
  if(isPressed("ctrl")) moveCam(0, spd, 0);
  dmouseX = mouseX - (width/2);
  dmouseY = mouseY - (height/2);
  robot.mouseMove(width/2, height/2);
  cam.look(radians(dmouseX) / 4.0, radians(dmouseY) / 4.0);
}