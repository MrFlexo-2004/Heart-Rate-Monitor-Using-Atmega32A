# Heart Rate Monitor with ATmega32A – AVR C & AVR Assembly

This project demonstrates a heart rate monitoring system implemented using both **AVR C** and **AVR Assembly**, designed for the ATmega32A microcontroller. The system reads heart rate values from a Python script via the **CP2102 serial interface** and displays them on a **16x2 LCD**, with LED indicators for health status.

> ✅ This repository showcases two complete implementations of the same project – one in high-level AVR C and the other in low-level AVR Assembly.

---

## 🛠 Features

- Displays real-time heart rate (BPM) on a 16x2 LCD in 4-bit mode
- Receives serial data using USART from Python via CP2102
- LED color indicators:
  - 🔴 Red: HR < 65 or HR > 120
  - 🟡 Yellow: 90 < HR ≤ 120
  - 🟢 Green: 65 ≤ HR ≤ 90
- Two implementation styles:
  - AVR C (single-port LCD wiring)
  - AVR Assembly (split control/data ports for simplicity)

---
## 🔌 Pin Connections

#### ⚙️ AVR C Version (All LCD pins on `PORTA`)

| LCD Pin | ATmega32A Pin | Description     |
| ------- | ------------- | --------------- |
| RS      | PA0           | Register Select |
| RW      | PA1           | Read/Write      |
| EN      | PA2           | Enable          |
| D4      | PA3           | Data Line 4     |
| D5      | PA4           | Data Line 5     |
| D6      | PA5           | Data Line 6     |
| D7      | PA6           | Data Line 7     |

> All LCD control and data lines are on `PORTA`. This version uses nibble shifting to operate the LCD in 4-bit mode.

---

#### ⚙️ AVR Assembly Version (LCD control on `PORTB`, data on `PORTA`)

| LCD Pin | ATmega32A Pin | Description     |
| ------- | ------------- | --------------- |
| RS      | PB0           | Register Select |
| RW      | PB1           | Read/Write      |
| EN      | PB2           | Enable          |
| D4      | PA4           | Data Line 4     |
| D5      | PA5           | Data Line 5     |
| D6      | PA6           | Data Line 6     |
| D7      | PA7           | Data Line 7     |

> Control and data pins are separated for simplicity in Assembly. This configuration is easier to manage manually when debugging or writing low-level logic.

---
### 📥 Serial Communication (CP2102 to ATmega32A)

| LED         | ATmega32A Pin | Description                    |
| ----------- | ------------- | ------------------------------ |
| RED         | PC0           | Control RED                    |
| YELLOW      | PC1           | Control YELLOW                 |
| GREEN       | PC2           | Control GREEN                  |

---

### 📥 Serial Communication (CP2102 to ATmega32A)

| CP2102 Pin | ATmega32A Pin | Description                    |
| ---------- | ------------- | ------------------------------ |
| TX         | RXD (PD0)     | Serial data to microcontroller |
| GND        | GND           | Common ground                  |

---

## 🧪 Implementation Notes

- **LCD Wiring:**
  - AVR C version uses only `PORTA` for both control and data (with nibble shifting).
  - AVR Assembly version uses `PORTA` for data (PA4–PA7) and `PORTB` for control (PB0–PB2) for clarity and simplicity.

- **Display Behavior:**
  - AVR C: Displays only the significant digits (e.g., `87 BPM`)
  - AVR Assembly: Displays 3 digits with leading zero if needed (e.g., `087 BPM`)

- **Fuse Settings Caution:**
  - In the prototype phase, an incorrect fuse configuration damaged a microcontroller. Be cautious with oscillator settings (internal vs. external) during fuse programming.

---

## 🔗 Real-world Demo (Arduino Version)

As the ATmega32A was damaged during testing, a working **Arduino + LCD** prototype was demonstrated and recorded:

🎥 **[Watch Demo Video](https://drive.google.com/file/d/1U2ADGtkiBTtQ4Idgcnshs2hNRUzYHpso/view?usp=drive_link)**
🎥 **[Simulation Video](https://drive.google.com/file/d/1HIZsekGuvAcTSAcb2SeT70SbPDkjaX5E/view?usp=drive_link)**
---

## ✅ Tools & Environment

- Microcontroller: ATmega32A
- Language: AVR C and AVR Assembly
- Programmer: USBasp
- Simulation: Proteus
- Display: 16x2 LCD (HD44780-compatible)
- Serial Interface: CP2102 USB to TTL
- Python: Serial read and transmit via PySerial
- IDEs used:
  - Atmel Studio (Assembly)(AVR C)
  - VS Code (Python Script)
  - Proteus for simulation

---

## 📷 Screenshots

- ✅ Circuit diagrams for both versions included in `/Simulation Files`
- ✅ Pin mapping described in Assembly code comments
- ✅ Component images available under `/Components`

---

## 📦 How to Run

1. Flash either the AVR C or Assembly `.hex` file to ATmega32A
2. Connect CP2102 to USART RX pin
3. Run the appropriate Python script:
4. Watch the LCD display and LED indicators respond to HR changes

---

## 🧠 Learning Outcomes

- In-depth experience with both low-level Assembly and high-level embedded C
- Mastery of serial communication, LCD interfacing, and embedded logic
- Debugging real-world hardware issues including fuse misconfiguration

---

## 📄 License

This project is open for educational and academic use. Contributions and feedback are welcome!

---


