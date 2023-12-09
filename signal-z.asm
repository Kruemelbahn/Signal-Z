	list p=16F628, w=0, r=DEC

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
;
; Hauptdatei = SIGNAL-Z.ASM
;
; M.Zimmermann 17.04.2010
;
; Prozessor 16F628 
;
; Prozessor-Takt ~4 MHz (internal Oszillator)
;
; Signalsteuerung für Z (signal-z)
;
; zu diesem Project gehört auch die Datei:
;    ports.inc, subroutines.inc
;
; das HEX-File kann erstellt werden durch: build.bat
;
;
;**************************************************************
; *  Copyright (c) 2018 Michael Zimmermann <http://www.kruemelsoft.privat.t-online.de>
; *  All rights reserved.
; *
; *  LICENSE
; *  -------
; *  This program is free software: you can redistribute it and/or modify
; *  it under the terms of the GNU General Public License as published by
; *  the Free Software Foundation, either version 3 of the License, or
; *  (at your option) any later version.
; *  
; *  This program is distributed in the hope that it will be useful,
; *  but WITHOUT ANY WARRANTY; without even the implied warranty of
; *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; *  GNU General Public License for more details.
; *  
; *  You should have received a copy of the GNU General Public License
; *  along with this program. If not, see <http://www.gnu.org/licenses/>.
; *
;**************************************************************
; Includedatei für den 16F628 einbinden

		#include <P16F628.INC>

		ERRORLEVEL      -302	;SUPPRESS BANK SELECTION MESSAGES


; Configuration festlegen:
; Power on Timer, kein Watchdog, kein Brown out, kein LV-programming,
; int.Osz RA6 & RA7 = I/O, MCLR disable
		__CONFIG 	_PWRTE_ON & _WDT_OFF & _BODEN_OFF & _LVP_OFF & _MCLRE_OFF & _INTRC_OSC_NOCLKOUT

;**************************************************************

bank_0		MACRO
		bcf	STATUS,RP0
		ENDM

bank_1		MACRO
		bsf	STATUS,RP0
		ENDM

;**************************************************************
; Variablen
;**************************************************************
; EEPROM
#define eeprom_start	2100h

		org	eeprom_start
sw_kennung:	de	"MZ", .8
version:	de	2
port_a:		de	1

;**************************************************************
	CBLOCK		H'20'
flags		: 1

a_status	: 1

loops		: 1
loops2		: 1

PWM_Startzustand: 1	; Bitmuster, von dem abgeblendet wird
PWM_Zielzustand	: 1	; Bitmuster, zu dem aufgeblendet wird
PWM_an		: 1	; PWM-Pausenzähler für Zustand ein
			; wird dekrementiert
PWM_aus		: 1	; PWM-Pausenzähler für Zustand aus
			; wird inkrementiert
ZAEHL		: 1
ZAEHL1		: 1
	ENDC

#define	a_input_changed		flags,0
#define a_FS_ein		flags,1
#define a_FS_Merker		flags,2

;**************************************************************
; including modules
;**************************************************************
		include "ports.inc"

; Programmstart
		org	0
		movlw	B'00000111'
		movwf	CMCON		; switch off comparators
		clrf	flags
		goto 	init

;**************************************************************
; Interruptserviceroutine (ISR)

		org	4
		retfie

;**************************************************************
; Das Programm beginnt mit der Initialisierung

init:		INIT_PORTS

	        movlw   port_a-eeprom_start
        	call 	read_eeprom

mainA:		movwf	PORTA

main:		btfss	FS_ein		; Fahrspannung zusätzlich ein?
		bsf	a_FS_ein	; -> merken

		call	checkInputs	
		; neues Ausgangsmuster für PORTA ist jetzt in W

		; Bei Ta Hp00 bzw. Gleiskontakt wird a_FS_ein zurückgesetzt
		btfss	HP00
		bcf	a_FS_ein
		btfss	Gleiskontakt
		bcf	a_FS_ein

		btfsc	a_FS_ein	; Fahrspannung zusätzlich ein?
		iorlw	B'00010000'	; ja...

		btfss	a_input_changed	
		goto	mainA		; keine Änderung an einem Eingang

		movwf	a_status
		bcf	a_input_changed
		bcf	a_FS_ein	; Fahrspannungsmerker aus
					; bei jedem Tastendruck

		; Statusänderung: im EEPROM merken
		; für's nächste Power-On!
		call	write_eeprom_data

	        movlw   port_a-eeprom_start
        	call 	write_eeprom

		; hat sich das Signalbild geädert?
		movfw	PORTA		; alter Zustand
		andlw	B'11001111'
		movwf	PWM_Startzustand

		movfw	a_status	; neuer Zustand	
		andlw	B'11001111'
		movwf	PWM_Zielzustand

		subwf	PWM_Startzustand, W
		bz	status_a

		; Fahrspannung halten, wenn bereits vorhanden:
		bcf	a_FS_Merker
		btfss	PORTA,4		; alter Zustand
		goto	do_PWM
		btfsc	a_status,4	; neuer Zustand
		bsf	a_FS_Merker

		; jetzt mit PWM das Signalbild ändern:
		; a.) abblenden
do_PWM:		movfw	PORTA		; alter Zustand
		andlw	B'11001111'
		movwf	PWM_Startzustand
		clrf	PWM_Zielzustand
		btfsc	a_FS_Merker
		bsf	PWM_Startzustand,4
		btfsc	a_FS_Merker
		bsf	PWM_Zielzustand,4
		call	PWM
		; b.) Pause zwischen den Signalbildern
		movlw	.250		; 250ms
		movwf	loops
		call	Wait
		; c.) aufblenden
		clrf	PWM_Startzustand
		movfw	a_status
		andlw	B'11001111'
		movwf	PWM_Zielzustand
		btfsc	a_FS_Merker
		bsf	PWM_Startzustand,4
		btfsc	a_FS_Merker
		bsf	PWM_Zielzustand,4
		call	PWM

status_a:	movfw	a_status
		goto	mainA

;.............................................................
; Rückgabewert wird nach PORTA geschrieben
;
;			  +--------------VR gn.2
;			  |+-------------Hp2
;		  	  ||+------------(input, set always 0)
;			  |||+-----------Fahrstrom ein
;			  ||||+----------Hp0.1
;			  |||||+---------Hp0.2
;			  ||||||+--------Sh1
;			  |||||||+-------Hp1
;			  ||||||||
;			  xx0xxxxx
;
checkInputs:	bsf	a_input_changed

		btfss	HP00
		retlw	B'00001100'

		btfss	Gleiskontakt
		retlw	B'00001100'

		btfss	Umschaltsperre
		goto	no_change

		btfss	Hp0_Sh1
		retlw	B'00010110'

		btfss	Hp2
		retlw	B'01010001'

		btfss	Hp1
		retlw	B'10010001'

no_change:	bcf	a_input_changed
		movfw	PORTA
		return


; PWM-Routine
;
; PORTA,4 ist das Fahrspannungsrelais. Damit dies nicht gepulst wird,
; ist Bit 4 in PWM_Startzustand und PWM_Zielzustand vorher auf 0 zu setzen!
;
PWM:		movlw	.255
		movwf	PWM_an
		movlw	.1
		movwf	PWM_aus		; PWM_aus darf nicht mit 0 starten!

pwm_loop:	movfw	PWM_Startzustand
		movwf	PORTA
		movfw	PWM_an
		movwf	ZAEHL
		call	pause

		movfw	PWM_Zielzustand
		movwf	PORTA
		movfw	PWM_aus
		movwf	ZAEHL
		call	pause

		incf	PWM_aus,F
		decfsz	PWM_an,F
		goto	pwm_loop	; nächster PWM-Durchlauf
		return			; Zielzustand erreicht

; Pause für Dimmen *********************************************
; Dauer = (2*ZAEHL)+4 Taktzyklen (7..514 Taktzyklen[µs bei 4MHz])
pause		movlw	.1
		movwf	ZAEHL1
pause1		decfsz	ZAEHL1,F	; Zahl der nops hängt vom 
					; Systemtakt ab, 
		goto	pause1		; bei 4 MHz wären es 6
	
		decfsz	ZAEHL,F
		goto	pause
		return

;**************************************************************
; including more modules
;**************************************************************
		include "subroutines.inc"

		end		

; end-of-file:signal-z.asm *************************************
