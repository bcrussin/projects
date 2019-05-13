  //VOID FUNCTIONS
void setKeyState(String keyName, boolean state) {
  switch(keyName) {
    case "enter":
      keys.setBoolean("\n", state);
      break;
    case "shift":
      keys.setBoolean("16", state);
      break;
    case "ctrl":
      keys.setBoolean("17", state);
      break;
    default:
      keys.setBoolean(keyName, state);
      break;
  }
  return;
}
  
void rectPrism(float[] pos, float[] size, float[] rot, color col) {
  pushMatrix();
  translate(pos[0], pos[1], pos[2]);
  rotateX(rot[0]);
  rotateY(rot[1]);
  rotateZ(rot[2]);
  fill(col);
  noStroke();
  
  box(size[0], size[1], size[2]);
  
  popMatrix();
}

void moveCam(float deltaX, float deltaY, float deltaZ) {
  cam.jump(camPos[0] + deltaX, camPos[1] + deltaY, camPos[2] + deltaZ);
  cam.aim(camTarg[0] + deltaX, camTarg[1] + deltaY, camTarg[2] + deltaZ);
}

  //ARRAY FUNCTIONS
float[] vec3(float v1, float v2, float v3) {
  float[] output = new float[] {v1, v2, v3};
  return output;
}

  //NON-ARRAY FUNCTIONS
boolean isPressed(String keyName) {
  switch(keyName) {
    case "enter":
      keyName = "\n";
      break;
    case "shift":
      keyName = "16";
      break;
    case "ctrl":
      keyName = "17";
      break;
  }
  if(keys.isNull(keyName)) return false;
  else return keys.getBoolean(keyName);
}