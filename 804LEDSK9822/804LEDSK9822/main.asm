;
; 804LEDSK9822.asm
;
; Created: 27/04/2022 22:24:26
; Author : Manama
; PA1 data
; PA2 clock

.def data = r19
.equ fclk = 10000000 
.def temp = r16


.macro micros					; macro for delay in us
ldi temp,@0
rcall delayTx1uS
.endm

.macro millis					; macro for delay in ms
ldi YL,low(@0)
ldi YH,high(@0)
rcall delayYx1mS
.endm



.cseg


reset:

/*
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;PROTECTED WRITE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PROT_WRITE:
		ldi r16,0Xd8
		out CPU_CCP,r16
		ldi r16,0x01						; clk prescaler of 2, 20Mhz/2 = 10Mhz
		STS CLKCTRL_MCLKCTRLB,R16
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

*/
	ldi r16,0b00000110
	out VPORTA_DIR,r16
	sbi VPORTA_OUT,1
	

main:
;	rcall start_frame

;	rcall frame3
;	rcall start_frame
;	rcall frame2
;	rcall start_frame
;	rcall LED_FRAME
	rcall start_frame
	rcall fill
;	rcall start_frame
;	rcall movframe
	millis 250
	rcall frame0
	millis 50

	rjmp main
	

SPI:
	ldi r18,8
tx:
	lsl data
	brcs hi
	cbi VPORTA_OUT,1
	nop
	sbi VPORTA_OUT,2
	nop
	cbi VPORTA_OUT,2
	dec r18
	brne tx
	sbi VPORTA_OUT,1
	ret
hi:
	sbi VPORTA_OUT,1
	nop
	sbi VPORTA_OUT,2
	nop
	cbi VPORTA_OUT,2
	dec r18
	brne tx
	sbi VPORTA_OUT,1
	ret

start_frame:
	ldi r25,4
st_tx:
	ldi data,0x00
	rcall SPI
	dec r25
	brne st_tx
	ret

LED_FRAME:
	ldi r26,30
LED_LOOP1:
	ldi data,0xe0
	ori data,0b00000011     ; full global brihtness
	rcall SPI
	ldi data,0xff			; blue 
	rcall SPI
	ldi data,0x00			; green
	rcall SPI
	ldi data,0x00			; red
	rcall SPI
	dec r26
	brne LED_LOOP1
	rcall END_FRAME
	rcall ms100
	ret
frame2:
	ldi r26,30
LED_LOOP2:
	ldi data,0xe0
	ori data,0b00000011     ; full global brihtness
	rcall SPI
	ldi data,0x00			; blue 
	rcall SPI
	ldi data,0x00			; green
	rcall SPI
	ldi data,0xff			; red
	rcall SPI
	dec r26
	brne LED_LOOP2
	rcall END_FRAME
	rcall ms100
	ret
frame3:
	ldi r26,30
LED_LOOP3:
	ldi data,0xe0
	ori data,0b00000011     ; full global brihtness,00011111
	rcall SPI
	ldi data,0x00			; blue 
	rcall SPI
	ldi data,0xff			; green
	rcall SPI
	ldi data,0x00			; red
	rcall SPI
	dec r26
	brne LED_LOOP3
	rcall END_FRAME
	rcall ms100
	ret
frame0:
	ldi r26,30
LED_LOOP0:
	ldi data,0xe0
	ori data,0b00000011     ; full global brihtness
	rcall SPI
	ldi data,0x00			; blue 
	rcall SPI
	ldi data,0x00			; green
	rcall SPI
	ldi data,0x00			; red
	rcall SPI
	dec r26
	brne LED_LOOP0
	rcall END_FRAME
	ret

END_FRAME:
	ldi data,0x00
	rcall SPI
	ldi data,0x00
	rcall SPI
	ret



; ============================== Time Delay Subroutines =====================
; Name:     delayYx1mS
; Purpose:  provide a delay of (YH:YL) x 1 mS
; Entry:    (YH:YL) = delay data
; Exit:     no parameters
; Notes:    the 16-bit register provides for a delay of up to 65.535 Seconds
;           requires delay1mS

delayYx1mS:
    rcall    delay1mS                        ; delay for 1 mS
    sbiw    YH:YL, 1                        ; update the the delay counter
    brne    delayYx1mS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret
; ---------------------------------------------------------------------------
; Name:     delayTx1mS
; Purpose:  provide a delay of (temp) x 1 mS
; Entry:    (temp) = delay data
; Exit:     no parameters
; Notes:    the 8-bit register provides for a delay of up to 255 mS
;           requires delay1mS

delayTx1mS:
    rcall    delay1mS                        ; delay for 1 mS
    dec     temp                            ; update the delay counter
    brne    delayTx1mS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret

; ---------------------------------------------------------------------------
; Name:     delay1mS
; Purpose:  provide a delay of 1 mS
; Entry:    no parameters
; Exit:     no parameters
; Notes:    chews up fclk/1000 clock cycles (including the 'call')

delay1mS:
    push    YL                              ; [2] preserve registers
    push    YH                              ; [2]
    ldi     YL, low(((fclk/1000)-18)/4)     ; [1] delay counter              (((fclk/1000)-18)/4)
    ldi     YH, high(((fclk/1000)-18)/4)    ; [1]                            (((fclk/1000)-18)/4)

delay1mS_01:
    sbiw    YH:YL, 1                        ; [2] update the the delay counter
    brne    delay1mS_01                     ; [2] delay counter is not zero

; arrive here when delay counter is zero
    pop     YH                              ; [2] restore registers
    pop     YL                              ; [2]
    ret                                     ; [4]

; ---------------------------------------------------------------------------
; Name:     delayTx1uS
; Purpose:  provide a delay of (temp) x 1 uS with a 16 MHz clock frequency
; Entry:    (temp) = delay data
; Exit:     no parameters
; Notes:    the 8-bit register provides for a delay of up to 255 uS
;           requires delay1uS

delayTx1uS:
    rcall    delay10uS                        ; delay for 1 uS
    dec     temp                            ; decrement the delay counter
    brne    delayTx1uS                      ; counter is not zero

; arrive here when delay counter is zero (total delay period is finished)
    ret

; ---------------------------------------------------------------------------
; Name:     delay10uS
; Purpose:  provide a delay of 1 uS with a 16 MHz clock frequency ;MODIFIED TO PROVIDE 10us with 1200000cs chip by Sajeev
; Entry:    no parameters
; Exit:     no parameters
; Notes:    add another push/pop for 20 MHz clock frequency

delay10uS:
    ;push    temp                            ; [2] these instructions do nothing except consume clock cycles
    ;pop     temp                            ; [2]
    ;push    temp                            ; [2]
    ;pop     temp                            ; [2]
    ;ret                                     ; [4]
     nop
     nop
     nop
     ret

; ============================== End of Time Delay Subroutines ==============
ms100:
	millis 10
	ret


movframe:
	ldi r26,30
	ldi r27,0
L1:
	cpi r27,0
	breq fframe
	rcall ms100
	rcall start_frame
	ldi r26,30
	rcall subloop0
	cpi r27,30
	brne L1
	ret
fframe:
	rcall movframe0
	ldi r28,1
	rcall subloop0
	cpi r27,30
	brne L1
movframe0:
	ldi data,0xe0
	ori data,0b00000011     ; full global brihtness
	rcall SPI
	ldi data,0xf0			; blue 
	rcall SPI
	ldi data,0xff			; green
	rcall SPI
	ldi data,0x0f			; red
	rcall SPI
	dec r26
	inc r27
	clr r28
	ret
subloop0:
	ldi data,0xe0
	ori data,0b00000011     ; full global brihtness
	rcall SPI
	ldi data,0x00			; blue 
	rcall SPI
	ldi data,0x00			; green
	rcall SPI
	ldi data,0x00			; red
	rcall SPI
	inc r28
	cp r27,r28
	breq movframe0
	dec r26
	brne subloop0
	rcall END_FRAME
	clr r28
	ret



fill:
	ldi r26,30
	ldi r27,30
L2:
	rcall ms100
	rcall start_frame
	ldi r26,30
	rcall movframe1
	rcall subloop1
	cpi r27,0
	brne L2
	ret
movframe1:
	ldi r28,30
	sub r28,r27
;	inc r28
mloop:
	ldi data,0xe0
	ori data,0b00000011     ; full global brihtness
	rcall SPI
	ldi data,0x0f			; blue 
	rcall SPI
	ldi data,0xf0			; green
	rcall SPI
	ldi data,0xff			; red
	rcall SPI
	dec r28
	brpl mloop
	dec r27
	dec r26
	ret
subloop1:
	ldi data,0xe0
	ori data,0b00000011     ; full global brihtness
	rcall SPI
	ldi data,0x00			; blue 
	rcall SPI
	ldi data,0x00			; green
	rcall SPI
	ldi data,0x00			; red
	rcall SPI
	dec r26
	brne subloop1
	rcall END_FRAME
	ret