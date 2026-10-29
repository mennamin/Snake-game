/*
 * Snake Game for 2.4" SPFD5408 TFT Display (240x320)
 * Arduino UNO – BREADBOARD WIRING + JOYSTICK
 */

#include <Adafruit_GFX.h>
#include <Adafruit_TFTLCD.h>

/* ================= TFT WIRING (YOUR SETUP) ================= */
#define LCD_CS   A3
#define LCD_RS   A2
#define LCD_WR   A1
#define LCD_RD   A0
#define LCD_RESET 10    // IMPORTANT: RESET is on pin 10

/* ================= JOYSTICK ================= */
#define JOY_X A4
#define JOY_Y A5

/* ================= COLORS ================= */
#define BLACK   0x0000
#define GREEN   0x07E0
#define RED     0xF800
#define WHITE   0xFFFF
#define YELLOW  0xFFE0

Adafruit_TFTLCD tft(LCD_CS, LCD_RS, LCD_WR, LCD_RD, LCD_RESET);

/* ================= GAME SETTINGS ================= */
#define BLOCK_SIZE 10
#define GRID_WIDTH  (320 / BLOCK_SIZE)
#define GRID_HEIGHT (240 / BLOCK_SIZE)
#define MAX_SNAKE_LENGTH 200

int snakeX[MAX_SNAKE_LENGTH];
int snakeY[MAX_SNAKE_LENGTH];
int snakeLength = 3;

// 0=Right, 1=Down, 2=Left, 3=Up
int direction = 0;

int foodX, foodY;
bool gameOver = false;
int score = 0;

/* ============================================================ */

void setup() {
  Serial.begin(9600);

  pinMode(JOY_X, INPUT);
  pinMode(JOY_Y, INPUT);

  /* === HARD RESET LCD (CRITICAL FIX) === */
  pinMode(LCD_RESET, OUTPUT);
  digitalWrite(LCD_RESET, LOW);
  delay(20);
  digitalWrite(LCD_RESET, HIGH);
  delay(150);

  tft.reset();

  uint16_t id = tft.readID();
  if (id == 0xD3D3 || id == 0x5408) id = 0x5408;
  if (id == 0x0000 || id == 0xFFFF) id = 0x9341;

  tft.begin(id);
  tft.setRotation(1);
  tft.fillScreen(BLACK);

  initGame();
  tft.drawRect(0, 0, 320, 240, WHITE);
}

void loop() {
  if (gameOver) {
    displayGameOver();
    delay(3000);
    initGame();
    tft.fillScreen(BLACK);
    tft.drawRect(0, 0, 320, 240, WHITE);
    return;
  }

  readJoystick();
  moveSnake();
  checkCollision();

  if (!gameOver) {
    checkFood();
    drawGame();
  }

  delay(150);
}

/* ================= GAME LOGIC ================= */

void initGame() {
  snakeLength = 3;
  direction = 0;
  gameOver = false;
  score = 0;

  for (int i = 0; i < snakeLength; i++) {
    snakeX[i] = GRID_WIDTH / 2 - i;
    snakeY[i] = GRID_HEIGHT / 2;
  }

  spawnFood();
}

void readJoystick() {
  int x = analogRead(JOY_X);
  int y = analogRead(JOY_Y);

  if (x < 300 && direction != 0) direction = 2;
  else if (x > 700 && direction != 2) direction = 0;
  else if (y < 300 && direction != 1) direction = 3;
  else if (y > 700 && direction != 3) direction = 1;
}

void moveSnake() {
  for (int i = snakeLength - 1; i > 0; i--) {
    snakeX[i] = snakeX[i - 1];
    snakeY[i] = snakeY[i - 1];
  }

  if (direction == 0) snakeX[0]++;
  else if (direction == 1) snakeY[0]++;
  else if (direction == 2) snakeX[0]--;
  else snakeY[0]--;
}

void checkCollision() {
  if (snakeX[0] <= 0 || snakeX[0] >= GRID_WIDTH - 1 ||
      snakeY[0] <= 0 || snakeY[0] >= GRID_HEIGHT - 1) {
    gameOver = true;
    return;
  }

  for (int i = 1; i < snakeLength; i++) {
    if (snakeX[0] == snakeX[i] && snakeY[0] == snakeY[i]) {
      gameOver = true;
      return;
    }
  }
}

void checkFood() {
  if (snakeX[0] == foodX && snakeY[0] == foodY) {
    if (snakeLength < MAX_SNAKE_LENGTH) {
      snakeLength++;
      score += 10;
    }
    spawnFood();
  }
}

void spawnFood() {
  bool ok = false;
  while (!ok) {
    foodX = random(1, GRID_WIDTH - 1);
    foodY = random(1, GRID_HEIGHT - 1);
    ok = true;
    for (int i = 0; i < snakeLength; i++) {
      if (foodX == snakeX[i] && foodY == snakeY[i]) {
        ok = false;
        break;
      }
    }
  }
}

void drawGame() {
  int tx = snakeX[snakeLength - 1];
  int ty = snakeY[snakeLength - 1];
  tft.fillRect(tx * BLOCK_SIZE, ty * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE, BLACK);

  tft.fillRect(snakeX[0] * BLOCK_SIZE, snakeY[0] * BLOCK_SIZE,
               BLOCK_SIZE, BLOCK_SIZE, GREEN);

  tft.fillRect(foodX * BLOCK_SIZE, foodY * BLOCK_SIZE,
               BLOCK_SIZE, BLOCK_SIZE, RED);

  tft.fillRect(120, 2, 90, 12, BLACK);
  tft.setCursor(125, 4);
  tft.setTextColor(WHITE);
  tft.setTextSize(1);
  tft.print("Score: ");
  tft.print(score);
}

void displayGameOver() {
  tft.fillScreen(BLACK);
  tft.setCursor(90, 90);
  tft.setTextColor(RED);
  tft.setTextSize(3);
  tft.println("GAME");
  tft.setCursor(90, 120);
  tft.println("OVER");

  tft.setCursor(90, 170);
  tft.setTextColor(WHITE);
  tft.setTextSize(2);
  tft.print("Score: ");
  tft.print(score);
}
