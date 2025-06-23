#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_ADDR 0x3C  // Confirm this with I2C scanner if needed

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// LED pins
const int redLED = 2;
const int greenLED = 3;
const int yellowLED = 4;

String input = "";
int heartRate = 0;

void setup() {
  Serial.begin(9600);

  pinMode(redLED, OUTPUT);
  pinMode(greenLED, OUTPUT);
  pinMode(yellowLED, OUTPUT);

  // Initialize OLED
  if (!display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR)) {
    Serial.println(F("OLED init failed"));
    while (true); // Halt
  }

  display.clearDisplay();
  display.setTextSize(2);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Waiting HR...");
  display.display();
}

void loop() {
  while (Serial.available()) {
    char c = Serial.read();
    
    if (c == '\n') {
      heartRate = input.toInt();
      input = "";

      // Display on OLED
      display.clearDisplay();
      display.setCursor(0, 0);
      display.print("HR: ");
      display.print(heartRate);
      display.println(" bpm");
      display.display();

      // LED Logic
      digitalWrite(redLED, LOW);
      digitalWrite(greenLED, LOW);
      digitalWrite(yellowLED, LOW);

      if (heartRate < 65 || heartRate > 120) {
        digitalWrite(redLED, HIGH);
      } else if (heartRate >= 65 && heartRate < 90) {
        digitalWrite(greenLED, HIGH);
      } else if (heartRate >= 90 && heartRate <= 120) {
        digitalWrite(yellowLED, HIGH);
      }

    } else if (isDigit(c)) {
      input += c;
    }
  }
}
