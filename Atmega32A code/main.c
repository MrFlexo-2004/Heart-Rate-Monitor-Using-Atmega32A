#define F_CPU 8000000UL
#include <avr/io.h>
#include <util/delay.h>
#include <stdlib.h>

// LCD control pins
#define LCD_RS PA0
#define LCD_RW PA1
#define LCD_EN PA2

// LCD data pins
#define LCD_D4 PA3
#define LCD_D5 PA4
#define LCD_D6 PA5
#define LCD_D7 PA6

#define MAX_HR_LEN 4

char hr_buffer[MAX_HR_LEN];
uint8_t idx = 0;

// ---------- LCD Functions ----------
void LCD_pulseEnable() {
	PORTA |= (1 << LCD_EN);
	_delay_us(1);
	PORTA &= ~(1 << LCD_EN);
	_delay_us(100);
}

void LCD_nibble(unsigned char nibble) {
	PORTA &= 0x87; // Clear D4-D7 (PA3–PA6)
	if (nibble & 0x01) PORTA |= (1 << LCD_D4);
	if (nibble & 0x02) PORTA |= (1 << LCD_D5);
	if (nibble & 0x04) PORTA |= (1 << LCD_D6);
	if (nibble & 0x08) PORTA |= (1 << LCD_D7);
	LCD_pulseEnable();
}

void LCD_cmd(unsigned char cmd) {
	PORTA &= ~(1 << LCD_RS); // RS = 0
	PORTA &= ~(1 << LCD_RW); // RW = 0
	LCD_nibble(cmd >> 4);
	LCD_nibble(cmd & 0x0F);
	_delay_ms(2);
}

void LCD_data(unsigned char data) {
	PORTA |= (1 << LCD_RS);  // RS = 1
	PORTA &= ~(1 << LCD_RW); // RW = 0
	LCD_nibble(data >> 4);
	LCD_nibble(data & 0x0F);
	_delay_ms(2);
}

void LCD_init() {
	_delay_ms(20);
	LCD_cmd(0x02); // 4-bit mode
	LCD_cmd(0x28); // 2-line, 5x7 font
	LCD_cmd(0x0C); // Display ON, cursor OFF
	LCD_cmd(0x06); // Entry mode
	LCD_cmd(0x01); // Clear display
	_delay_ms(2);
}

void LCD_clear() {
	LCD_cmd(0x01);
}

void LCD_setCursor(uint8_t row, uint8_t col) {
	uint8_t pos[] = {0x80, 0xC0};
	LCD_cmd(pos[row] + col);
}

void LCD_print(char *str) {
	while (*str) {
		LCD_data(*str++);
	}
}

// ---------- USART Functions ----------
void USART_init(unsigned int ubrr) {
	UCSRB = (1 << RXEN);     // Enable receiver
	UCSRC = (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0); // 8-bit
	UBRRL = ubrr;
	UBRRH = (ubrr >> 8);
}

unsigned char USART_receive_char() {
	while (!(UCSRA & (1 << RXC)));
	return UDR;
}

void USART_receive_string(char* buffer, uint8_t max_len) {
	char ch;
	uint8_t i = 0;

	while (1) {
		ch = USART_receive_char();
		if (ch == '\r' || ch == '\n') {
			buffer[i] = '\0';
			break;
		}
		if (i < max_len - 1) {
			buffer[i++] = ch;
		}
	}
}

// ---------- LED Function ----------
void LED_display(uint8_t hr) {
	PORTC = 0x00;
	if (hr < 65 || hr > 120) {
		PORTC |= (1 << PC0); // RED
		} else if (hr > 90 && hr <= 120) {
		PORTC |= (1 << PC1); // YELLOW
		} else if (hr >= 65 && hr <= 90) {
		PORTC |= (1 << PC2); // GREEN
	}
}

// ---------- Main ----------
int main(void) {
	DDRA = 0xFF; // LCD (output)
	DDRC = 0xFF; // LEDs (output)
	PORTC = 0x00;

	LCD_init();
	USART_init(51); // 9600 baud at 8 MHz

	LCD_setCursor(0, 0);
	LCD_print("Waiting HR");

	while (1) {
		USART_receive_string(hr_buffer, MAX_HR_LEN);
		uint8_t hr = atoi(hr_buffer);

		LCD_clear();
		LCD_setCursor(0, 0);
		LCD_print("Heart Rate");
		LCD_setCursor(1, 0);
		LCD_print(hr_buffer);
		LCD_print(" BPM");

		LED_display(hr);
	}
}
