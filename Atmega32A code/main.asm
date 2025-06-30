;
.INCLUDE "m32def.inc"

.DSEG
hr_buffer: .BYTE 4    ; Max 3 digits + null

; PB0 = RS
; PB1 = RW
; PB2 = EN
; PA4 = D4
; PA5 = D5
; PA6 = D6
; PA7 = D7
; PC0 = RED LED
; PC1 = YELLOW LED
; PC2 = GREEN LED

.CSEG
.ORG 0x00
RJMP RESET

; ===================== RESET VECTOR =====================
RESET:
    ; Setup Stack
    LDI R16, HIGH(RAMEND)
    OUT SPH, R16
    LDI R16, LOW(RAMEND)
    OUT SPL, R16

    ; Setup PORTC for LEDs (PC0-PC2)
    LDI R17, 0b00000111
    OUT DDRC, R17
    CLR R17
    OUT PORTC, R17
	
	; SETUP PORTB FOR LCD CONTROL
	LDI R17,0b00000111
	OUT DDRB,R17

	; SETUP PORTA FOR LCD DATA
	LDI R17,0b11110000
	OUT DDRA,R17

	RCALL LCD_init
	RCALL LCD_message_Waiting_HR
	CLR R25    ; R25 = 0 ? no HR input yet

    ; USART Init
    LDI R16, (1 << RXEN)
    OUT UCSRB, R16
    LDI R16, (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0)
    OUT UCSRC, R16
    LDI R16, 51         ; 9600 baud @ 8 MHz
    OUT UBRRL, R16
    CLR R16
    OUT UBRRH, R16

Main_Loop:
    ; Point X to hr_buffer
    LDI R26, LOW(hr_buffer)
    LDI R27, HIGH(hr_buffer)

    RCALL USART_receive_string   ; fills buffer

    ; Check if first HR input
    CPI R25, 0
    BRNE Skip_HR_Message

    RCALL LCD_clear
    RCALL LCD_message_Heart_Rate
    LDI R25, 1   ; Set flag: first input handled

Skip_HR_Message:
    RCALL atoi                   ; result in R16
    RCALL LED_check              ; checks and lights LED
    RCALL LCD_display_HR_on_line2
    RJMP Main_Loop

; ===================== USART RECEIVE CHAR =====================
USART_receive_char:
WaitChar:
    SBIS UCSRA, RXC
    RJMP WaitChar
    IN R16, UDR
    RET

; ===================== RECEIVE STRING INTO BUFFER =====================
; Expects R26:R27 = X = start of hr_buffer
USART_receive_string:
    CLR R18      ; i = 0
NextChar:
    RCALL USART_receive_char     ; result in R16
    CPI R16, 0x0D                ; check for '\r'
    BREQ End_String
    CPI R16, 0x0A                ; check for '\n'
    BREQ End_String

    CPI R18, 3                   ; if i >= 3, ignore extra
    BRSH NextChar

    ST X+, R16                   ; buffer[i++] = R16
    INC R18
    RJMP NextChar

End_String:
    LDI R16, 0
    ST X, R16                    ; Null terminate
    RET

; ===================== ATOI: Converts hr_buffer ASCII to R16 number =====================
; Uses: R16 (result), R17, R18, R19, R20
atoi:
    CLR R17        ; result
    LDI R18, 10     ; multiplier
    LDI R26, LOW(hr_buffer)
    LDI R27, HIGH(hr_buffer)

NextDigit:
    LD R20, X+
    CPI R20, 0
    BREQ Done_atoi
    SUBI R20, '0'
    MOV R19, R17
    MUL R19, R18
    MOV R17, R0
    CLR R1
    ADD R17, R20
    RJMP NextDigit

Done_atoi:
    MOV R16, R17    ; return result in R16
    RET
;================= LCD Functions =================
 
LCD_init:
	LDI R23,0x33		; initialise 8 bit mode
	RCALL LCD_cmd
	RCALL Delay_2ms

	LDI R23,0x32		; change to 4 bit mode
	RCALL LCD_cmd
	RCALL Delay_2ms

	LDI R23,0x28		; 5x7 font size , 2 line mode
	RCALL LCD_cmd
	RCALL Delay_2ms

	LDI R23,0x0C		; Display On , Cursor Off , Blink Off
	RCALL LCD_cmd
	RCALL Delay_2ms		
	
	LDI R23,0x01		; Clear Display
	RCALL LCD_cmd
	RCALL Delay_2ms

	LDI R23,0x06		; Increment cursor mode (not display update)
	RCALL LCD_cmd
	RCALL Delay_2ms
	RET

LCD_clear:
	LDI R23,0x01
	RCALL LCD_cmd
	RCALL Delay_2ms
	RET

LCD_pulse:
	SBI PORTB,2
	RCALL Delay_1us
	CBI PORTB,2
	RCALL Delay_100us
	RET

LCD_cursor_line_1:
	LDI R23,0x80
	RCALL LCD_cmd
	RCALL Delay_2ms
	RET

LCD_cursor_line_2:
	LDI R23,0xC0
	RCALL LCD_cmd
	RCALL Delay_2ms
	RET

LCD_cmd:
    MOV R24, R23
    ANDI R24, 0xF0         ; High nibble

    IN R25, PORTA
    ANDI R25, 0x0F
    OR R25, R24
    CBI PORTB,0            ; RS = 0 (command)
    CBI PORTB,1            ; RW = 0
    OUT PORTA, R25
    RCALL LCD_pulse

    MOV R24, R23
    SWAP R24
    ANDI R24, 0xF0

    IN R25, PORTA
    ANDI R25, 0x0F
    OR R25, R24
    OUT PORTA, R25
    RCALL LCD_pulse
    RET

LCD_data:
    MOV R24, R23           ; R23 = full byte to display
    ANDI R24, 0xF0         ; High nibble (already aligned)
    
    IN R25, PORTA          ; Read current PORTA state
    ANDI R25, 0x0F         ; Clear upper nibble (keep PA0–PA3)
    OR R25, R24            ; Merge high nibble into PA4–PA7
    SBI PORTB,0            ; RS = 1 (data)
    CBI PORTB,1            ; RW = 0 (write)
    OUT PORTA, R25
    RCALL LCD_pulse

    MOV R24, R23
    SWAP R24               ; Swap to get lower nibble in high 4 bits
    ANDI R24, 0xF0

    IN R25, PORTA
    ANDI R25, 0x0F
    OR R25, R24
    OUT PORTA, R25
    RCALL LCD_pulse
    RET

LCD_message_Waiting_HR:
	RCALL LCD_cursor_line_1
	LDI R23,'W'
	RCALL LCD_data
	
	LDI R23,'a'
	RCALL LCD_data
	
	LDI R23,'i'
	RCALL LCD_data
	
	LDI R23,'t'
	RCALL LCD_data
	
	LDI R23,'i'
	RCALL LCD_data
	
	LDI R23,'n'
	RCALL LCD_data
	
	LDI R23,'g'
	RCALL LCD_data
	
	LDI R23,' '
	RCALL LCD_data
	
	LDI R23,'H'
	RCALL LCD_data
	
	LDI R23,'R'
	RCALL LCD_data
	RET

LCD_message_Heart_Rate:
	RCALL LCD_cursor_line_1
	LDI R23,'H'
	RCALL LCD_data
	
	LDI R23,'e'
	RCALL LCD_data
	
	LDI R23,'a'
	RCALL LCD_data
	
	LDI R23,'r'
	RCALL LCD_data
	
	LDI R23,'t'
	RCALL LCD_data
	
	LDI R23,' '
	RCALL LCD_data
	
	LDI R23,'R'
	RCALL LCD_data
	
	LDI R23,'a'
	RCALL LCD_data
	
	LDI R23,'t'
	RCALL LCD_data
	
	LDI R23,'e'
	RCALL LCD_data
	
	LDI R23,':'
	RCALL LCD_data
	RET
; ===================== LED CHECK =====================
; RED: HR < 65 or HR > 120 ? PC0
; YELLOW: 90 < HR ? 120 ? PC1
; GREEN: 65 ? HR ? 90 ? PC2

LED_check:
	LDI R17,0b00000111
	OUT DDRC,R17
	LDI R17,0
	OUT PORTC,R17
	LDI R17,65
	LDI R18,120
	LDI R19,90
	
	RED:
	CP R16,R17		; HR LOWER THAN 65 THEN RED ON
	BRLO LED_RED
	CP R18,R16		; HR GREATER THAN 120 THEN RED ON
	BRLO LED_RED    ; USING 120<HR (TO CHECK IF HR>120 OR NOT)
	
	AND_BUFFER:
	CP R19,R16		; CHECK IF HR IS GREATER THAN 90 OR NOT FOR AND CONDITION)
	BRLO LED_BUFFER_YELLOW		; USING 90<HR (TO CHECK IF HR>90 OR NOT)
	RJMP LED_BUFFER_GREEN		; USING 90>=HR (TO CHECK IF HR<=90 OR OT)
	
	LED_BUFFER_YELLOW:
	CP R18,R16
	BRSH LED_YELLOW

	LED_BUFFER_GREEN:
	CP R16,R17
	BRSH LED_GREEN

	LED_RED:
	SBI PORTC,0
	NOP
	RET
	
	LED_YELLOW:
	SBI PORTC,1
	NOP
	RET
		
	LED_GREEN:
	SBI PORTC,2
	NOP
	RET

; ===================== DISPLAY HR ON LINE 2 =====================
; R16 = Heart rate value (0–255), prints as ASCII
LCD_display_HR_on_line2:
    RCALL LCD_cursor_line_2

    MOV R20, R16    ; R20 = HR copy
    CLR R21         ; Hundreds
    CLR R22         ; Tens
    CLR R23         ; Units

; Divide by 100
Loop_100:
    CPI R20, 100
    BRLO Done_100
    SUBI R20, 100
    INC R21
    RJMP Loop_100
Done_100:

; Divide by 10
Loop_10:
    CPI R20, 10
    BRLO Done_10
    SUBI R20, 10
    INC R22
    RJMP Loop_10
Done_10:

    MOV R23, R20    ; Units

    ; Now print digits
    ; Use R24 as scratch for ASCII conversion
    ; Print hundreds
    LDI R24, '0'
    ADD R24, R21
    MOV R23, R24
    RCALL LCD_data

    ; Print tens
    LDI R24, '0'
    ADD R24, R22
    MOV R23, R24
    RCALL LCD_data

    ; Print units
    LDI R24, '0'
    ADD R24, R20        ; ? use R20 instead of overwritten R23
    MOV R23, R24
    RCALL LCD_data

    ; Print " BPM"
    LDI R23, ' '
    RCALL LCD_data
    LDI R23, 'B'
    RCALL LCD_data
    LDI R23, 'P'
    RCALL LCD_data
    LDI R23, 'M'
    RCALL LCD_data

    RET


Delay_1us:
	NOP
	NOP
	NOP
	NOP
	RET

Delay_100us:
	LDI R21,99
	loop_100us:
		NOP
		NOP
		NOP
		NOP
		NOP
		DEC R21
		BRNE loop_100us
	NOP
	NOP
	NOP
	NOP
	RET

Delay_2ms:
	LDI R21, 20        ; Outer loop = 20 × 800 cycles = 16,000
	loop_2ms:
    ; Inner 100us = 800 cycles
    LDI R22, 100
		loop1_100us:
			NOP               ; 1
			NOP               ; 1
			NOP               ; 1
			NOP               ; 1
			NOP               ; 1
			DEC R22	          ; 1
			BRNE loop1_100us   ; 2 (taken)
		DEC R21           ; 1
		BRNE loop_2ms     ; 2 (taken)
	RET
;