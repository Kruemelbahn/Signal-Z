;**************************************************************
;
; subroutines.inc
;
; M.Zimmermann 23.7.2009
;
; signal-z
;
; nützliche Unterprogramme
;
; Prozessor-Takt 4 MHz
;
;**************************************************************
; Warteschleife <loops> ms für einen 4MHz-PIC-Takt 
Wait:
        	movlw   .110           	; Zeitkonstante für 1ms 
        	movwf   loops2 
Wai2:    	nop  
        	nop 
        	nop 
        	nop 
        	nop 
        	nop 
        	decfsz  loops2, F      	; 1 ms vorbei? 
        	goto    Wai2           	; nein, noch nicht 

        	decfsz  loops, F       	; Zeit vorbei? 
        	goto    Wait           	; nein, noch nicht 
        	retlw	0	       	; das Warten hat ein Ende

;**************************************************************
; liest ein Zeichen aus dem EEPROM-Bereich
; in W wird die EEPROM-Adresse (0..) übergeben,
; das gelesene Zeichen ist wieder in W
read_eeprom:
        	bank_1
	        movwf   EEADR
	        bsf     EECON1,RD
	        movf    EEDATA,w
        	bank_0
	        return
 
;**************************************************************
; schreibt ein Zeichen in den EEPROM-Bereich
; in W wird die EEPROM-Adresse (0..) übergeben.
;
; der zu schreibende Wert muss zuvor in EEDATA geschrieben worden sein
; -> call write_eeprom_data
;
write_eeprom_data:
		bank_1
		movwf	EEDATA		; Wert für EEPROM
		bank_0
		return
write_eeprom:
		bcf	PIR1,EEIF
		bank_1
		movwf	EEADR		; Adresse 
		bsf 	EECON1, WREN	; Enable write
		bcf 	INTCON, GIE 	; Disable INTs.

		; DON'T change the following 5 lines!
		movlw 	0x55 		;
		movwf 	EECON2 		; Write 55h
		movlw 	0xAA 		;
		movwf 	EECON2 		; Write AAh
		bsf 	EECON1,WR	; Set WR bit, begin write

		bank_0
write_loop:	btfss	PIR1,EEIF
		goto	write_loop	; wait until write is finished
		bank_1

		bcf 	EECON1, WREN	; Disable write
		bank_0
	        return
 
; end-of-file:subroutines.inc *********************************
