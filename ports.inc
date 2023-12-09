;**************************************************************
;
; ports.inc
;
; M.Zimmermann 14.04.2010
;
; Signalsteuerung für Z (signal-z)
;
; Portdefinitionen / Routinen
;
; Prozessor-Takt 4 MHz
;
;**************************************************************
;*  	Pinbelegung
;*	------------------------------------------------	
;*	PORTA:	0 out Hp1
;*		1 out Sh1
;*		2 out Hp0.2
;*		3 out Hp0.1
;*		4 out Fahrstrom ein / Vr-Einschaltung
;*		5 in  (unused)
;*		6 out Hp2
;*		7 out Vr gn.2
;*               
;*	PORTB:	0 in  Hp00
;*		1 in  Hp0/Sh1
;*		2 in  Hp1
;*		3 in  Hp2
;*		4 in  (unused)
;*		5 in  Fahrstromrelais ein
;*		6 in  Gleiskontakt -|_|-
;*		7 in  Umschaltsperre
;**************************************************************

#define	LED_Hp1		PORTA,0
#define	LED_Sh1		PORTA,1
#define LED_Hp02	PORTA,2
#define	LED_Hp01	PORTA,3
#define Fahrstrom	PORTA,4
#define LED_Hp2		PORTA,6
#define LED_VR_gn2	PORTA,7

#define HP00		PORTB,0
#define Hp0_Sh1		PORTB,1
#define Hp1		PORTB,2
#define Hp2		PORTB,3
#define FS_ein		PORTB,5
#define Gleiskontakt	PORTB,6
#define Umschaltsperre	PORTB,7

;**************************************************************

INIT_PORTS	MACRO
		bank_1
		movlw	B'01000110'	; *RBPU  =0 enable pull-up for PORTB
					; INTEDG =1 interrupt on rising edge
					; T0CS   =0 TMR0 clock source:
					;                internal instr. cycle
					; T0SE   =0 don't care
					; PSA    =0 prescaler for TMR0
					; PS2:PS0=010 Prescaler rate 1:64 (TMR0)
		movwf	OPTION_REG
		movlw	B'00100000'	; TRISA[0:4] = output
					; TRISA[5]   = input
					; TRISA[6:7] = output
		movwf	TRISA
		movlw	B'11111111'	; TRISB[0:7] = input
		movwf	TRISB
		bank_0
		clrf PORTA
		clrf PORTB
		ENDM

; end-of-file:ports.inc ***************************************

