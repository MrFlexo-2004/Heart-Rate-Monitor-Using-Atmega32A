#include <LiquidCrystal.h>

// Initialize the LCD: rs, en, d4, d5, d6, d7
LiquidCrystal lcd(8, 9, 10, 11, 12, 13); // Change these to match your wiring

// LED pins
const int redLED = 2;
const int greenLED = 4;
const int yellowLED = 3;

String input = "";
int heartRate = 0;

void setup() {
  Serial.begin(9600);

  pinMode(redLED, OUTPUT);
  pinMode(greenLED, OUTPUT);
  pinMode(yellowLED, OUTPUT);

  // Initialize LCD
  lcd.begin(16, 2);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Waiting HR...");
}

void loop() {
  while (Serial.available()) {
    char c = Serial.read();
    
    if (c == '\n') {
      heartRate = input.toInt();
      input = "";

      // Display on LCD
      lcd.clear();
      lcd.setCursor(0, 0);
      lcd.print("Heart Rate: ");
      lcd.setCursor(0, 1);
      lcd.print(heartRate);
      lcd.print(" bpm");

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
