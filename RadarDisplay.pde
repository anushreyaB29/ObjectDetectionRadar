import processing.serial.*;

Serial myPort;

String angle = "";
String distance = "";
String data = "";

float iAngle, iDistance;

// Sweep trail
float[] trailAngles = new float[60];
int trailHead = 0;

// Detected objects buffer
float[] objAngle = new float[20];
float[] objDist = new float[20];
int objCount = 0;

// Pulse animation
int pulseTimer = 0;
boolean objectDetected = false;

color GREEN = color(0, 255, 100);
color DIM_GREEN = color(0, 100, 50);
color RED = color(255, 50, 50);
color AMBER = color(255, 180, 0);
color BG = color(5, 10, 5);

PFont monoFont;

void setup() {
  size(1400, 800);
  smooth(4);

  monoFont = createFont("Courier New", 14, true);
  textFont(monoFont);

  // Initialize trail
  for (int i = 0; i < trailAngles.length; i++) trailAngles[i] = 0;

  printArray(Serial.list());
  if (Serial.list().length > 0) {
    myPort = new Serial(this, Serial.list()[0], 9600);
    myPort.bufferUntil('.');
  }
}

void draw() {
  background(BG);

  // Scanline overlay effect
  for (int y = 0; y < height; y += 4) {
    stroke(0, 0, 0, 30);
    line(0, y, width, y);
  }

  // Store trail
  trailAngles[trailHead % trailAngles.length] = iAngle;
  trailHead++;

  // Track objects
  objectDetected = iDistance < 20 && iDistance > 0;
  if (objectDetected) {
    if (objCount < objAngle.length) {
      objAngle[objCount] = iAngle;
      objDist[objCount] = iDistance;
      objCount++;
    } else {
      // Shift and add
      for (int i = 0; i < objAngle.length - 1; i++) {
        objAngle[i] = objAngle[i + 1];
        objDist[i] = objDist[i + 1];
      }
      objAngle[objAngle.length - 1] = iAngle;
      objDist[objDist.length - 1] = iDistance;
    }
    pulseTimer = 20;
  }
  if (pulseTimer > 0) pulseTimer--;

  // Draw all components
  drawTopBar();
  drawRadar();
  drawSweepTrail();
  drawLine();
  drawAllObjects();
  drawRangeLabels();
  drawSidePanel();
  drawPulse();
}

void drawTopBar() {
  noStroke();
  fill(0, 20, 0);
  rect(0, 0, width, 40);

  fill(GREEN);
  textSize(13);
  textAlign(LEFT);
  text("██ RADAR SYSTEM ACTIVE", 20, 26);

  textAlign(CENTER);
  fill(DIM_GREEN);
  text("SECTOR SCAN  |  MODE: CONTINUOUS  |  RANGE: 0-100 cm", width / 2, 26);

  textAlign(RIGHT);
  String t = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  fill(GREEN);
  text(t, width - 20, 26);

  stroke(DIM_GREEN);
  strokeWeight(1);
  line(0, 40, width, 40);
}

void drawRadar() {
  int cx = width / 2 - 100;
  int cy = height - 60;
  int maxR = 560;

  pushMatrix();
  translate(cx, cy);

  // Background fill for radar dome
  noStroke();
  fill(0, 15, 0);
  arc(0, 0, maxR * 2, maxR * 2, PI, TWO_PI, PIE);

  // Threat zones (concentric fills)
  noStroke();
  fill(255, 0, 0, 12);
  arc(0, 0, maxR * 2 * 0.25, maxR * 2 * 0.25, PI, TWO_PI, PIE);

  fill(255, 180, 0, 8);
  arc(0, 0, maxR * 2 * 0.5, maxR * 2 * 0.5, PI, TWO_PI, PIE);

  fill(0, 255, 100, 5);
  arc(0, 0, maxR * 2 * 0.75, maxR * 2 * 0.75, PI, TWO_PI, PIE);

  // Grid rings
  strokeWeight(1);
  noFill();
  for (int i = 1; i <= 4; i++) {
    float r = maxR * i / 4.0;
    if (i == 1) stroke(255, 50, 50, 140);
    else if (i == 2) stroke(255, 180, 0, 100);
    else stroke(0, 255, 100, 80);
    arc(0, 0, r * 2, r * 2, PI, TWO_PI);
  }

  // Angle lines every 30°
  stroke(0, 255, 100, 50);
  strokeWeight(1);
  for (int i = 0; i <= 180; i += 30) {
    float x = -maxR * cos(radians(i));
    float y = -maxR * sin(radians(i));
    line(0, 0, x, y);
  }

  // Finer lines every 10°
  stroke(0, 255, 100, 20);
  for (int i = 0; i <= 180; i += 10) {
    float x = -maxR * cos(radians(i));
    float y = -maxR * sin(radians(i));
    line(0, 0, x, y);
  }

  // Horizon line
  stroke(GREEN);
  strokeWeight(2);
  line(-maxR, 0, maxR, 0);

  // Origin crosshair
  stroke(GREEN);
  strokeWeight(1);
  line(-10, 0, 10, 0);
  line(0, -10, 0, 10);
  fill(GREEN);
  noStroke();
  ellipse(0, 0, 6, 6);

  popMatrix();
}

void drawSweepTrail() {
  int cx = width / 2 - 100;
  int cy = height - 60;

  pushMatrix();
  translate(cx, cy);

  int len = trailAngles.length;
  for (int i = 0; i < len; i++) {
    int idx = ((trailHead - 1 - i) + len * 100) % len;
    float a = trailAngles[idx];
    float alpha = map(i, 0, len, 180, 0);
    float r = 560;
    stroke(0, 255, 100, alpha);
    strokeWeight(2.5);
    float x = r * cos(radians(a));
    float y = -r * sin(radians(a));
    line(0, 0, x, y);
  }
  popMatrix();
}

void drawLine() {
  int cx = width / 2 - 100;
  int cy = height - 60;

  pushMatrix();
  translate(cx, cy);

  strokeWeight(3);
  stroke(0, 255, 100, 255);
  float r = 560;
  line(0, 0,
    r * cos(radians(iAngle)),
    -r * sin(radians(iAngle)));

  // Leading glow tip
  noStroke();
  fill(0, 255, 100, 200);
  float tx = r * cos(radians(iAngle));
  float ty = -r * sin(radians(iAngle));
  ellipse(tx, ty, 8, 8);

  popMatrix();
}

void drawAllObjects() {
  int cx = width / 2 - 100;
  int cy = height - 60;
  int maxR = 560;

  pushMatrix();
  translate(cx, cy);

  for (int i = 0; i < objCount; i++) {
    float pixD = objDist[i] * (maxR / 100.0);
    float px = pixD * cos(radians(objAngle[i]));
    float py = -pixD * sin(radians(objAngle[i]));

    // Glow rings
    noStroke();
    fill(255, 50, 50, 20);
    ellipse(px, py, 30, 30);
    fill(255, 50, 50, 40);
    ellipse(px, py, 18, 18);
    fill(255, 50, 50, 200);
    ellipse(px, py, 8, 8);

    // Crosshair
    stroke(255, 50, 50, 160);
    strokeWeight(1);
    line(px - 12, py, px + 12, py);
    line(px, py - 12, px, py + 12);
  }
  popMatrix();
}

void drawRangeLabels() {
  int cx = width / 2 - 100;
  int cy = height - 60;
  int maxR = 560;

  textAlign(LEFT);
  for (int i = 1; i <= 4; i++) {
    float r = maxR * i / 4.0;
    float lx = cx + r + 6;
    float ly = cy - 4;

    if (i == 1) fill(RED);
    else if (i == 2) fill(AMBER);
    else fill(GREEN);

    textSize(11);
    text((i * 25) + " cm", lx, ly);
  }

  // Angle labels
  fill(DIM_GREEN);
  textSize(11);
  for (int i = 0; i <= 180; i += 30) {
    float r = maxR + 20;
    float lx = cx - r * cos(radians(i));
    float ly = cy - r * sin(radians(i));
    textAlign(CENTER, CENTER);
    text(i + "°", lx, ly);
  }
}

void drawSidePanel() {
  int px = width - 220;
  int py = 60;
  int pw = 200;
  int ph = height - 100;

  // Panel bg
  noStroke();
  fill(0, 20, 0);
  rect(px, py, pw, ph, 4);
  stroke(DIM_GREEN);
  strokeWeight(1);
  noFill();
  rect(px, py, pw, ph, 4);

  // Title
  fill(GREEN);
  textSize(12);
  textAlign(CENTER);
  text("─── TELEMETRY ───", px + pw / 2, py + 24);

  // Angle readout
  fill(DIM_GREEN);
  textSize(11);
  textAlign(LEFT);
  text("BEARING", px + 16, py + 60);
  fill(GREEN);
  textSize(28);
  textAlign(RIGHT);
  text(nf(iAngle, 3, 1) + "°", px + pw - 16, py + 90);

  // Distance readout
  stroke(DIM_GREEN);
  strokeWeight(1);
  line(px + 16, py + 100, px + pw - 16, py + 100);
  noStroke();

  fill(DIM_GREEN);
  textSize(11);
  textAlign(LEFT);
  text("RANGE", px + 16, py + 120);
  fill(iDistance < 25 ? RED : iDistance < 50 ? AMBER : GREEN);
  textSize(28);
  textAlign(RIGHT);
  if (iDistance >= 100 || iDistance <= 0)
    text("---", px + pw - 16, py + 150);
  else
    text(nf(iDistance, 3, 1), px + pw - 16, py + 150);
  fill(DIM_GREEN);
  textSize(11);
  text("cm", px + pw - 16, py + 165);

  // Status
  stroke(DIM_GREEN);
  line(px + 16, py + 178, px + pw - 16, py + 178);
  noStroke();

  fill(DIM_GREEN);
  textSize(11);
  textAlign(LEFT);
  text("STATUS", px + 16, py + 200);

  if (pulseTimer > 0) {
    fill(RED);
    textSize(13);
    textAlign(CENTER);
    text("▲ CONTACT", px + pw / 2, py + 225);
  } else {
    fill(0, 180, 80);
    textSize(13);
    textAlign(CENTER);
    text("● SCANNING", px + pw / 2, py + 225);
  }

  // Bar graph for distance
  stroke(DIM_GREEN);
  line(px + 16, py + 238, px + pw - 16, py + 238);
  noStroke();
  fill(DIM_GREEN);
  textSize(11);
  textAlign(LEFT);
  text("PROXIMITY", px + 16, py + 258);

  int barW = pw - 32;
  float fillW = iDistance < 100 && iDistance > 0 ? map(iDistance, 0, 100, barW, 0) : 0;
  noStroke();
  fill(30, 50, 30);
  rect(px + 16, py + 265, barW, 12, 2);
  color barCol = iDistance < 25 ? RED : iDistance < 50 ? AMBER : GREEN;
  fill(barCol);
  rect(px + 16, py + 265, fillW, 12, 2);

  // Object count
  stroke(DIM_GREEN);
  line(px + 16, py + 295, px + pw - 16, py + 295);
  noStroke();
  fill(DIM_GREEN);
  textSize(11);
  textAlign(LEFT);
  text("CONTACTS", px + 16, py + 315);
  fill(GREEN);
  textSize(22);
  textAlign(RIGHT);
  text(objCount, px + pw - 16, py + 340);

  // Compass rose (mini)
  stroke(DIM_GREEN);
  line(px + 16, py + 355, px + pw - 16, py + 355);
  noStroke();
  drawMiniCompass(px + pw / 2, py + 420, 45);
}

void drawMiniCompass(float cx, float cy, float r) {
  stroke(DIM_GREEN);
  strokeWeight(1);
  noFill();
  ellipse(cx, cy, r * 2, r * 2);

  fill(DIM_GREEN);
  textSize(10);
  textAlign(CENTER, CENTER);
  text("N", cx, cy - r - 10);
  text("S", cx, cy + r + 10);
  text("E", cx + r + 10, cy);
  text("W", cx - r - 10, cy);

  // Sweep needle
  stroke(GREEN);
  strokeWeight(2);
  float nx = cx + r * 0.8 * cos(radians(iAngle) - HALF_PI);
  float ny = cy + r * 0.8 * sin(radians(iAngle) - HALF_PI);
  line(cx, cy, nx, ny);

  noStroke();
  fill(GREEN);
  ellipse(cx, cy, 6, 6);
}

void drawPulse() {
  if (pulseTimer <= 0) return;
  float alpha = map(pulseTimer, 0, 20, 0, 80);
  noStroke();
  fill(255, 0, 0, alpha);
  rect(0, 0, width, height);
}

void serialEvent(Serial myPort) {
  data = myPort.readStringUntil('.');
  if (data != null) {
    data = data.substring(0, data.length() - 1);
    int index = data.indexOf(",");
    if (index > 0) {
      angle = data.substring(0, index);
      distance = data.substring(index + 1);
      iAngle = float(angle);
      iDistance = float(distance);
    }
  }
}
