
.equ cursor_position=0x0100	;pozycja kursora na ekranie
.equ screen=0x0101	;numer ekranu
.equ old_key=0x0102	;poprzedni oczyt klawiatury
.equ key=0x0103		;odzcyt klawiatury dla programu obslugi
.equ anty_key=0x0104	;zapami,etanie ze dany klawisz juz wcisnieto
.equ key_flip_flop=0x0105 ;przerzutnik adc 0 ,1,2,3
.equ key_mem=0x0106	;bufor wcÅ›niÄ™tego klawisza
.equ light_measure=0x0107	;wynik pomiaru oÅ›wietlenia
.equ temperature=0x0108		;wynik pomiaru temperatury
.equ measure_end=0x0109	;znacznik koÅ„ca pomiaru

.equ temp_hex=0x010a ;temperatura w hex
.equ temp_on1_hex=0x010b	;temperaura wÅ‚aczania w hex
.equ temp_on2_hex=0x010c ; temperatura wyÅ‚Ä…czania w hex
.equ temp_bcd_low=0x010d	;temeratura BCD
.equ temp_bcd_high=0x010e 
.equ temp_on1_bcd_low= 0x010f; temperatura wÅ‚Ä…czania1 ogrzewania w bcd
.equ temp_on1_bcd_high=0x0110
.equ temp_on2_bcd_low=0x0111	;temeratura wyÅ‚Ä…czania2 wentylatora w bcd
.equ temp_on2_bcd_high=0x0112

.equ light_hex=0x0113
.equ light_hex_set=0x0114

.equ light_bcd_set1=0x0115
.equ light_bcd_set2=0x0116
.equ light=0x0117
.equ delay_hex=0x0118
.equ delay_hex_set=0x0119
.equ delay_bcd_set_low=0x011a
.equ delay_bcd_set_high=0x011b
.equ min1=0x011c
.equ licznik=0x001d
.equ on_off_status=0x011e
.equ delay_on=0x011f
    jmp start
	.org 0x0002
	jmp przerwanie
	.org 0x0016
	jmp timer_int
	.org 0x002a	;obsÅ‚uga przerwania od ADC
	jmp adc_int

	start: 
		ldi r16,0b00000000
		out ddrc,r16
		ldi r16,0b00010000
		out portc,r16

	ldi r16,0x00	;ustawienie stosu
	out spl,r16
	ldi r16,0x03
	out sph,r16

	ldi r16,0b00000000
	sts adcsrb,r16

	ldi r16,0b01100000
	sts admux,r16
	
	ldi r16,0x00
	sts licznik,r16
	sts min1,r16
	ldi r16,0x01
	sts delay_on,r16
	ldi r16,0x00
	sts key,r16
	sts anty_key,r16
	sts old_key,r16
	sts screen,r16
	sts cursor_position,r16
	sts key_flip_flop,r16
	sts key_mem,r16
	sts measure_end,r16

	ldi r16,0x23
	sts temp_hex,r16
	ldi r16,26
	sts temp_on1_hex,r16
	sts temp_on2_hex,r16
	ldi r16,0x00
	sts temp_bcd_low,r16
	sts temp_bcd_high,R16 
	sts temp_on1_bcd_low,r16
	sts temp_on1_bcd_high,r16
	sts temp_on2_bcd_low,r16
	sts temp_on2_bcd_high,r16

	ldi r16,0x32
sts light_hex,r16
	ldi r16,0x45
sts light_hex_set,r16
ldi r16,0x00

sts light_bcd_set1,r16
sts light_bcd_set2,r16


ldi r16,0x00
sts delay_hex,r16
ldi r16,0x24
sts delay_hex_set,r16
ldi r16,0x00
sts delay_bcd_set_low,r16
sts delay_bcd_set_high,r16

	ldi r16,0xff
	out ddrb,r16
	ldi r16,0b00001011
	out ddrd,r16
	ldi r16,0x0f
	out portd,r16
	call delay_2
	
	ldi r16,0x00
	sts tccr1a,r16
	ldi r16,0b00001101
	sts tccr1b,r16
	ldi r16,0x3d
	sts ocr1ah,r16
	ldi r16,0x09
	sts ocr1al,r16
	
	ldi r16,0b00000010
	sts timsk1,r16

	cbi portb,4	;RS=0
	cbi portb,5	;E=0

	call delay_2

	ldi r16,0x02
	call sent_instruction
	call delay_1				;magistrala 4 bitowa


		ldi r16,0x02
	call sent_instruction

				;magistrala 4 bitowa


	ldi r16,0x08				;lcd 2*16 znakÃ³w
	call sent_instruction
	call delay_1

	ldi r16,0x00				; clr dispaly
	call sent_instruction


	ldi r16,0x01
	call sent_instruction
	call delay_2

	ldi r16,0x00				;dispaly on
	call sent_instruction


	ldi r16,0x0f
	call sent_instruction
	call delay_2

		ldi r16,0x00		;kierunek przesuwania kursora
	call sent_instruction


	ldi r16,0x06
	call sent_instruction
	call delay_1

	call displ_screen0

	ldi r16,0b01100000
	sts admux,r16
	ldi r16,0b11001110
	sts adcsra,r16

	;odmaskowanie int0
	ldi r16,0b00000010
	sts eicra,r16
	ldi r16,0b00000001
	out eimsk,r16
		sei
	
czekaj:


	lds r16,min1
	cpi r16,0x01
	breq dalej
	jmp czekaj1
dalej:	ldi r16,0x00
	sts min1,r16
;wyswietlenie  nowej temp i oswitlenia
;temp
	lds r16,screen
	cpi r16,0x00
	breq lab300
	jmp lab301
lab300:
	ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x05
	call sent_instruction
	call delay_1
	lds r16,temp_hex
	lsr r16
	subi r16,0x02
	sts temperature,r16
	call hex_bcd
	ldi r16,0x30
	add r16,r18
	call sent_char
	ldi r16,0x30
	add r16,r17
	call sent_char

	;oÅ›wietlenie
	ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x0d
	call sent_instruction
	call delay_1
	lds r16,light_hex
	com r16
	subi r16,0x9c
	sts light,r16
	call hex_bcd
	ldi r16,0x30
	add r16,r18
	call sent_char
	ldi r16,0x30
	add r16,r17
	call sent_char
		ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x00
	call sent_instruction
	call delay_1
	
	lds r16,delay_on
	cpi r16,0x01
	breq lab302
	jmp czekaj1

lab302:
	lds r16,delay_hex
	inc r16
	sts delay_hex,r16


	ldi r16,0x0c		;adres ramu
	call sent_instruction
	ldi r16,0x0b
	call sent_instruction
	call delay_1
	lds r16,delay_hex
	call hex_bcd
	ldi r16,0x30
	add r16,r18
	call sent_char
	ldi r16,0x30
	add r16,r17
	call sent_char
	ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x00
	call sent_instruction
	call delay_1

lab301:
	lds r16,delay_on
	cpi r16,0x00
	breq lab200

	lds r16,temperature
	lds r17,temp_on1_hex
	ldi r18,0x01
	add r17,r18
	cp r16,r17
	brge lab201
	lds r16,temperature
	lds r17,temp_on1_hex
	ldi r18,0x01
	add r16,r18
	cp r16,r17
	brge lab202
;lacz ogzewanie
	cbi portd,1
	jmp lab202
lab201: ;wylacz ogrzewanie
	sbi portd,1

lab202:
	lds r16,temperature
	lds r17,temp_on2_hex
	ldi r18,0x01
	add r17,r18
	cp r16,r17
	brlo lab203
	lds r16,temperature
	lds r17,temp_on2_hex
	ldi r18,0x01
	add r16,r18
	cp r16,r17
	brlo lab200
;wlacz ochlodzenie
	cbi portd,3
	jmp lab200
lab203: ;wylacz chlodzenie
	sbi portd,3
	;oswietlenie
lab200:
		lds r16,light
	lds r17,light_hex_set
	ldi r18,0x01
	sub r17,r18
	cp r16,r17
	brge lab204
	lds r16,light
	lds r17,light_hex_set
	ldi r18,0x01
	sub r16,r18
	cp r16,r17
	brge lab205
;lacz swiatlo
	cbi portd,0
	jmp lab205
lab204: ;wylacz swiatlo
	sbi portd,0
lab205:
	lds r16,delay_hex
	lds r17,delay_hex_set
	cp r16,r17
	brne czekaj1

;wyÅ‚Ä…cz wszystko
	ldi r16,0x00
	sts delay_on,r16
	ldi r16,0b00001011
	out portd,r16

czekaj1:
	lds r16,key		;czekanie na wciÅ›niÄ™cie klawisza
	cpi r16,0x00
	breq czekaja
	;coÅ› wciÅ›niÄ™to
	ldi r17,0x00	;zerowanie bufora key
	sts key,r17
	lds r17,screen ;odczytaj numer ekranu
	cpi r17,0x00
	brne lab3a ;skocz jesli nie ekran zero
	cpi r16,0x01
	brne lab4	;skocz jesli nie w prawo
	lds r17,cursor_position
	cpi r17,0x00
	brne lab5 ;skocz jesli nie pozycja 0
	ldi r16,0x08		;adres ramu na 10
	call sent_instruction
	ldi r16,0x09
	call sent_instruction
	call delay_1
	ldi r17,0x01
	sts cursor_position,r17
	czekaja: jmp czekaj
	lab3a: jmp lab3
lab5: cpi r17,0x01
	brne lab6; skocz jesli nie pozycja 1
	ldi r16,0x0c		;adres ramu na 10
	call sent_instruction
	ldi r16,0x00
	call sent_instruction
	call delay_1
	ldi r17,0x02
	sts cursor_position,r17
	jmp czekaj
lab6: jmp czekaj
lab4: cpi r16,0x02	
	brne lab11 ;skocz jesli nie w lewo
	lds r17,cursor_position
	cpi r17,0x02
	brne lab7 ;skocz jeÅ›li nie pozycja 2
	ldi r16,0x08		;adres ramu na 10
	call sent_instruction
	ldi r16,0x09
	call sent_instruction
	call delay_1
	ldi r17,0x01
	sts cursor_position,r17
	jmp czekaj
lab7: cpi r17,0x01
	brne lab8
	ldi r16,0x08		;adres ramu na 10
	call sent_instruction
	ldi r16,0x00
	call sent_instruction
	call delay_1
	ldi r17,0x00
	sts cursor_position,r17
	jmp czekaj
lab8: jmp czekaj
lab11: cpi r16,0x05
breq lab9
	jmp czekaj
	;obsÅ‚uga wejÅ›cia do podekranÃ³w
lab9: lds r17,cursor_position
		cpi r17,0x00 
		brne lab10		;skoz jesli nie pozycja 0
		call displ_screen1	;wyswietl ekran1
		ldi r16,0x01
		sts screen,r16
		ldi r16,0x00
		sts cursor_position,r16
	jmp czekaj
lab10:	cpi r17,0x01
	brne lab12	;skocz jesli nie pozycja 1
		call displ_screen2	;wyswietl ekran1
		ldi r16,0x02
		sts screen,r16
		ldi r16,0x00
		sts cursor_position,r16
		jmp czekaj
lab12: cpi r17,0x02
	  breq lab13
	  jmp czekaj
lab13: 	call displ_screen3	;wyswietl ekran3
		ldi r16,0x03
		sts screen,r16
		ldi r16,0x00
		sts cursor_position,r16
		jmp czekaj
lab3: cpi r17,0x01	;sprawdznie czy ekran 1
		brne lab14a
;-------------------------------
	;obsÅ‚uga ekranu 1
		cpi r16,0x05
		brne lab15	;skocz jesli nie wyjscie
		call displ_screen0
			ldi r16,0x00
		sts screen,r16
		ldi r16,0x00
		sts cursor_position,r16
		jmp czekaj
lab14a:	jmp lab14
lab15: 
		cpi r16,0x01 ;prawo
		brne lab19a
		lds r17,cursor_position
		cpi r17,0x00	;czy pozycja 0
		brne lab20
		ldi r17,0x01	;pozycja 1
		sts cursor_position,r17
		call cursor_right
		jmp czekaj
lab19a: jmp lab19
lab20: cpi r17,0x01 ;czy pozycja 1
	brne lab21
		ldi r17,0x02 ;pozycja 2
		sts cursor_position,r17
				ldi r16,0x0c		;adres ramu
	call sent_instruction
	call delay_1
	ldi r16,0x0c
	call sent_instruction
	call delay_1
	jmp czekaj
lab21:
		cpi r17,0x02 ;czy pozycja 2
		brne lab22
		ldi r17,0x03	;pozycja 3
		sts cursor_position,r17
		call cursor_right
lab22:	jmp czekaj
;  w lewo
lab19:
		cpi r16,0x02	;czy w lewo
		brne lab23
		lds r17,cursor_position
		cpi r17,0x03
		brne lab24
		ldi r17,0x02
		sts cursor_position,r17
		call cursor_left
		jmp czekaj
lab24: cpi r17,0x02
	brne lab25
	ldi r17,0x01
	sts cursor_position,r17
	ldi r16,0x08		;adres ramu
	call sent_instruction
	call delay_1
	ldi r16,0x0d
	call sent_instruction
	call delay_1
	jmp czekaj
lab25: cpi r17,0x01
	brne lab26
	ldi r17,0x00
	sts cursor_position,r17
	call cursor_left
lab26: jmp czekaj
;zwiÄ™ksz
lab23:
	cpi r16,0x04
	brne lab27a
	lds r17,cursor_position
	cpi r17,0x00	;pozycja zero
	brne lab28
	lds r16,temp_on1_bcd_high
	cpi r16,0x09
	brne lab29
	jmp czekaj
lab27a: jmp lab27
lab29:inc r16
	sts temp_on1_bcd_high,r16
lab32:	ldi r17,0x30
	add r16,r17
	call sent_char
	call cursor_left
	lds r17,temp_on1_bcd_low
	lds r18,temp_on1_bcd_high
	ldi r19,0x00
	call bcd_hex
	sts temp_on1_hex,r16
	jmp czekaj
lab28:
	cpi r17,0x01	;pozycja 1
	brne lab30
	lds r16,temp_on1_bcd_low
	cpi r16,0x09
	brne lab31
	jmp czekaj
lab31:
	inc r16
	sts temp_on1_bcd_low,r16
	jmp lab32
lab30:
	cpi r17,0x02	;pozycja 2
	brne lab33
		lds r16,temp_on2_bcd_high
	cpi r16,0x09
	brne lab29b
	jmp czekaj
lab29b:inc r16
	sts temp_on2_bcd_high,r16
lab32b:	ldi r17,0x30
	add r16,r17
	call sent_char
	call cursor_left
	lds r17,temp_on2_bcd_low
	lds r18,temp_on2_bcd_high
	ldi r19,0x00
	call bcd_hex
	sts temp_on2_hex,r16
	jmp czekaj
lab33:
;pozycja 3
	lds r16,temp_on2_bcd_low
	cpi r16,0x09
	brne lab31b
	jmp czekaj
lab31b:
	inc r16
	sts temp_on2_bcd_low,r16
	jmp lab32b
lab27: ;zmniejsz

	lds r17,cursor_position
	cpi r17,0x00	;pozycja zero
	brne lab28c
	lds r16,temp_on1_bcd_high
	cpi r16,0x00
	brne lab29c
	jmp czekaj
lab29c:dec r16
	sts temp_on1_bcd_high,r16
lab32c:	ldi r17,0x30
	add r16,r17
	call sent_char
	call cursor_left
	lds r17,temp_on1_bcd_low
	lds r18,temp_on1_bcd_high
	ldi r19,0x00
	call bcd_hex
	sts temp_on1_hex,r16
	jmp czekaj
lab28c:
	cpi r17,0x01	;pozycja 1
	brne lab30c
	lds r16,temp_on1_bcd_low
	cpi r16,0x00
	brne lab31c
	jmp czekaj
lab31c:
	dec r16
	sts temp_on1_bcd_low,r16
	jmp lab32
lab30c:
	cpi r17,0x02	;pozycja 2
	brne lab33c
		lds r16,temp_on2_bcd_high
	cpi r16,0x00
	brne lab29bc
	jmp czekaj
lab29bc:dec r16
	sts temp_on2_bcd_high,r16
lab32bc:	ldi r17,0x30
	add r16,r17
	call sent_char
	call cursor_left
	lds r17,temp_on2_bcd_low
	lds r18,temp_on2_bcd_high
	ldi r19,0x00
	call bcd_hex
	sts temp_on2_hex,r16
	jmp czekaj
lab33c:
;pozycja 3
	lds r16,temp_on2_bcd_low
	cpi r16,0x00
	brne lab31bc
	jmp czekaj
lab31bc:
	dec r16
	sts temp_on2_bcd_low,r16
	jmp lab32bc
		jmp czekaj
		
lab14: cpi r17,0x02 ;sprawdzenie czy ekran 2
		brne lab16a	;skocz jesli nie 2
;----------------------------------------------------------
;obsÅ‚uga ekranu 2
		cpi r16,0x05 ;czy klawisz enter
		brne lab17
		call displ_screen0
			ldi r16,0x00
		sts screen,r16
		ldi r16,0x00
		sts cursor_position,r16
		jmp czekaj
lab17: cpi r16,0x01
		brne lab35	;skocz jesli niw w prawo
		lds r17,cursor_position
		cpi r17,0x00
		brne lab36
		ldi r17,0x01
		sts cursor_position,r17
		call cursor_right
		jmp czekaj
lab36: jmp czekaj
lab16a: jmp lab16
lab35:	cpi r16,0x02	;skocz jesli nie w lewo
		brne lab40
		lds r17,cursor_position
		cpi r17,0x01
		brne lab37
		ldi r17,0x00
		sts cursor_position,r17
		call cursor_left
lab37:
		jmp czekaj
lab40: cpi r16,0x04
		brne lab41	;skocz jesli nie zwieksz
;zwiÄ™ksz
	lds r17,cursor_position
	cpi r17,0x00	;pozycja zero
	brne lab28d
	lds r16,light_bcd_set2
	cpi r16,0x09
	brne lab29d
	jmp czekaj
lab29d:inc r16
	sts light_bcd_set2,r16
lab32d:	ldi r17,0x30
	add r16,r17
	call sent_char
	call cursor_left
	lds r17,light_bcd_set1
	lds r18,light_bcd_set2
	ldi r19,0x00
	call bcd_hex
	sts light_hex_set,r16
	jmp czekaj
lab28d:
	cpi r17,0x01
	breq lab43
	jmp czekaj
lab43:
	lds r16,light_bcd_set1
	cpi r16,0x09
	brne lab31d
	jmp czekaj
lab31d:
	inc r16
	sts light_bcd_set1,r16
	jmp lab32d

lab41: cpi r16,0x03
	breq lab42
	jmp czekaj
lab42:
;zmniejsz
	lds r17,cursor_position
	cpi r17,0x00	;pozycja zero
	brne lab28e
	lds r16,light_bcd_set2
	cpi r16,0x00
	brne lab29e
	jmp czekaj
lab29e:dec r16
	sts light_bcd_set2,r16
lab32e:	ldi r17,0x30
	add r16,r17
	call sent_char
	call cursor_left
	lds r17,light_bcd_set1
	lds r18,light_bcd_set2
	ldi r19,0x00
	call bcd_hex
	sts light_hex_set,r16
	jmp czekaj
lab28e:
	
	lds r16,light_bcd_set1
	cpi r16,0x00
	brne lab31e
	jmp czekaj
lab31e:
	dec r16
	sts light_bcd_set1,r16
	jmp lab32e
jmp czekaj
		
;--------------------------------------
;obsluga ekranu 3
lab16: cpi r17,0x03
	breq lab51
	jmp czekaj
lab51:
		cpi r16,0x05
		brne lab18
		call displ_screen0
			ldi r16,0x00
		sts screen,r16
		ldi r16,0x00
		sts cursor_position,r16
		jmp czekaj
lab18:	cpi r16,0x01
		brne lab38
		lds r17,cursor_position
		cpi r17,0x00
		brne lab36a
		inc r17
		sts cursor_position,r17
		call cursor_right
		jmp czekaj
lab38: cpi r16,0x02
		brne lab39
	lds r17,cursor_position
	cpi r17,0x01
	brne lab36a
	dec r17
	sts cursor_position,r17
	call cursor_left
	jmp czekaj
lab36a:jmp lab36
lab39:
	 cpi r16,0x04
		brne lab41f	;skocz jesli nie zwieksz
;zwiÄ™ksz
	lds r17,cursor_position
	cpi r17,0x00	;pozycja zero
	brne lab28f
	lds r16,delay_bcd_set_high
	cpi r16,0x09
	brne lab29f
	jmp czekaj
lab29f:inc r16
	sts delay_bcd_set_high,r16
lab32f:	ldi r17,0x30
	add r16,r17
	call sent_char
	call cursor_left
	lds r17,delay_bcd_set_low
	lds r18,delay_bcd_set_high
	ldi r19,0x00
	call bcd_hex
	sts delay_hex_set,r16
	jmp czekaj
lab28f:
	cpi r17,0x01
	breq lab43f
	jmp czekaj
lab43f:
	lds r16,delay_bcd_set_low
	cpi r16,0x09
	brne lab31f
	jmp czekaj
lab31f:
	inc r16
	sts delay_bcd_set_low,r16
	jmp lab32f

lab41f: cpi r16,0x03
	breq lab42f
	jmp czekaj
lab42f:
;zmniejsz
	lds r17,cursor_position
	cpi r17,0x00	;pozycja zero
	brne lab28g
	lds r16,delay_bcd_set_high
	cpi r16,0x00
	brne lab29g
	jmp czekaj
lab29g:dec r16
	sts delay_bcd_set_high,r16
lab32g:	ldi r17,0x30
	add r16,r17
	call sent_char
	call cursor_left
	lds r17,delay_bcd_set_low
	lds r18,delay_bcd_set_high
	ldi r19,0x00
	call bcd_hex
	sts delay_hex_set,r16
	jmp czekaj
lab28g:
	
	lds r16,delay_bcd_set_low
	cpi r16,0x00
	brne lab31g
	jmp czekaj
lab31g:
	dec r16
	sts delay_bcd_set_low,r16
	jmp lab32g

		koniec: rjmp koniec	
;--------------------------------------------------------------
;przerwanie od int0
przerwanie:
	push r16
	ldi r16,0x01
	sts delay_on,r16
	ldi r16,0x00
	sts delay_hex,r16
	pop r16
	reti

;-------------------------------przesun kursor w lewo
cursor_left:
		ldi r16,0x01		;adres ramu
	call sent_instruction
	call delay_1
	ldi r16,0x00
	call sent_instruction
	call delay_1
	ret
;-----------------------przesun kursor w prawo
cursor_right:
		ldi r16,0x01		;adres ramu
	call sent_instruction
	call delay_1
	ldi r16,0x04
	call sent_instruction
	call delay_1
	ret
;----------------------------------------------------------
timer_int:
push r16
in r16,sreg
push r16
lds r16,licznik
inc r16
sts licznik,r16
cpi r16,60	;xxxx
brne lab_timer_int
ldi r16,0x00
sts licznik,r16
ldi r16,0x01
sts min1,r16
lab_timer_int:
pop r16
out sreg,r16
pop r16

reti
;------------------------------------------------------------
	adc_int:	;obsluga przerwania od adc

	push r16
	push r17
	push r18
	push r19
	push r20
	in r16,sreg
	push r16

		lds r16,key_flip_flop
		cpi r16,0x00
		brne lab_key1

		lds r17,adcl
		lds r18,adch


		cpi r18,0x40
		brlo klawisz_lewo
		cpi r18,0xc0
		brlo klaw_end1a
		ldi r17,0x01	;klawisz prawo
		sts key_mem,r17
		jmp klaw_end1
	klawisz_lewo: ldi r17,0x02 ;klawisz lewo
		sts key_mem,r17
		jmp klaw_end1
klaw_end1a:
	ldi r17,0x00
	sts key_mem,r17
klaw_end1:
		ldi r16,0x01
		sts key_flip_flop,r16

		ldi r16,0b01100001	;pomiar w kanale 1
		sts admux,r16
		jmp klawi_end

lab_key1: cpi r16,0x01
		brne lab_key3
lab_key2:	
		lds r16,key_mem
		cpi r16,0x00
		brne klaw_end2
		
		lds r17,adcl
		lds r18,adch

		cpi r18,0x40
		brlo klawisz_gora
		cpi r18,0xc0
		brlo klawisz_koniec
		ldi r17,0x03	;klawisz prawo
		sts key_mem,r17
		jmp klaw_end2
	klawisz_gora: ldi r17,0x04 ;klawisz lewo
		sts key_mem,r17
		jmp klaw_end2
klawisz_koniec: ldi r17,0x00
					sts key_mem,r17
						
klaw_end2:
		sbic pinc,4
		jmp key_dalej
		ldi r17,0x05
		sts key_mem,r17
key_dalej:
		ldi r16,0x02
		sts key_flip_flop,r16

		ldi r16,0b01100010	;pomiar w kanale 2
		sts admux,r16
		jmp klaw_end
lab_key3:	
		cpi r16,0x02
		brne lab_key4
		lds r17,adcl
		lds r18,adch
		sts light_hex,r18
		ldi r16,0x03
		sts key_flip_flop,r16

		ldi r16,0b01100011	;pomiar w kanale 3
		sts admux,r16
		jmp klawi_end
lab_key4:	
		lds r17,adcl
		lds r18,adch
		sts temp_hex,r18
		ldi r16,0x00
		sts key_flip_flop,r16

		ldi r16,0b01100000
		sts admux,r16		;pomiar w kanale 0
		ldi r16,0x01
		sts measure_end,r16
		jmp klawi_end
klaw_end:
		lds r17,key_mem
		cpi r17,0x00	;porÃ³wnanie z nic nie wcisnieto
		brne klaw_cos	;skocz jesli wcisnieto
		sts old_key,r17
		sts anty_key,r17
		jmp klawi_end
	klaw_cos: lds r18,old_key
		cp r17,r18
		breq klaw_ok	;powtornie to samo
		sts old_key,r17
		jmp klawi_end

klaw_ok: lds r18,anty_key
		cpi r18,0x00
		brne	klawi_end
		ldi r18,0x01
		sts anty_key,r18
		sts key,r17

	klawi_end:

	ldi r16,0b11001110	;zainicjowaie kolejnego pomiaru
	sts adcsra,r16

		pop  r16
		out sreg,r16
		pop r20
		pop r19
		pop r18
		pop r17
		pop r16

		reti	;powrÃ³t z przerwania
;----------------------------wyÅ›wietl znak

	sent_char:		;wyÅ›lij ascii
	push r17
	sbi portb,4
	in r17,portb
	andi r17,0xf0
	push r16
	swap r16
	andi r16,0x0f
	or r17,r16
	out portb,R17
	sbi portb,5
	nop
	cbi portb,5
	call delay_1
	pop r16
	in r17,portb
	andi r17,0xf0
	andi r16,0x0f
	or r17,r16
	out portb,r17
	sbi portb,5
	nop
	cbi portb,5
	call delay_1
	pop r17
	ret
;----------------------------------
	sent_instruction:	;wyÅ›lij insytrukcjÄ™
	cbi portb,4
	in r17,portb
	andi r17,0xf0
	or r17,r16
	out portb,r17
	sbi portb,5
	nop
	cbi portb,5
	ret

;---------------------------------------
delay_1:			;opÃ³Åºnienie krÃ³tkie
	push r17
	push r18
	ldi r17,0x20
	lab_delay_1: ldi r18,0xff
	lab_delay_2: dec r18
				brne lab_delay_2
				dec r17
				brne lab_delay_1
				pop r18
				pop r17
				ret
;------------------------------------------------------
delay_2:			;opÃ³Åºniene dÅ‚ugie
	push r17
	push r18
	push r19
	ldi r17,0x02
	lab_delay_3: ldi r18,0xff
	lab_delay_4: ldi r19,0xff
	lab_delay_5: dec r19
				brne lab_delay_5
				dec r18
				brne lab_delay_4
				dec r17
				brne lab_delay_3
				pop r19
				pop r18
				pop r17
				ret
;----------------------------------
;zamiana bajtu hex na rozpakowanÄ… liczbÄ™ bcd
;hex w r16 wynik w r17,r18,r19-msb
hex_bcd:

	ldi r19,0x00
	ldi r18,0x00
	ldi r17,0x00
hex_bcd2:
	subi r16,0x64
	brcs hex_bcd1
	inc r19
	jmp hex_bcd2
hex_bcd1: 
	ldi r20,0x64
	add r16,r20
hex_bcd3:
	subi r16,0x0a
	brcs hex_bcd4
	inc r18
	jmp hex_bcd3
hex_bcd4: 
	ldi r20,0x0a
	add r16,r20
	mov r17,r16
	ret
	;-----------------------------------------
	bcd_hex: ;procedura pakowania zawartoÅ›ci rjstrÃ³w r17,r18,r19 MSB w kodzi bcd do liczy hex w r16
	ldi r16,0x64
	mul r16,r19
	mov r19,r0
	ldi r16,0x0a
	mul r16,r18
	mov r18,r0
	mov r16,r17
	add r16,r18
	adc r16,r19
	ret
		
	;---------------------------------------
	;procedura wyÅ›wietlaia ekranu 1
	displ_screen1:
			ldi r16,0x08		;adres ramu
	call sent_instruction
	call delay_1
	ldi r16,0x00
	call sent_instruction
	call delay_1
		ldi r17,16
	ldi zl,low(2*tekst3)
	ldi zh,high(2*tekst3)
	labs11: lpm r16,z+
	call sent_char
	dec r17
	brne labs11

	ldi r16,0x0c		;adres ramu
	call sent_instruction

	ldi r16,0x00
	call sent_instruction
	call delay_1

		ldi r17,16
	ldi zl,low(2*tekst4)
	ldi zh,high(2*tekst4)
	labs12: lpm r16,z+
	call sent_char
	dec r17
	brne labs12

		ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x0c
	call sent_instruction
	call delay_1
	lds r16,temp_on1_hex
	call hex_bcd
	sts temp_on1_bcd_low,r17
	sts temp_on1_bcd_high,r18
	ldi r16,0x30
	add r16,r18
	call sent_char
	ldi r16,0x30
	add r16,r17
	call sent_char

		ldi r16,0x0c		;adres ramu
	call sent_instruction
	ldi r16,0x0c
	call sent_instruction
	call delay_1
	lds r16,temp_on2_hex
	call hex_bcd
	sts temp_on2_bcd_low,r17
	sts temp_on2_bcd_high,r18
	ldi r16,0x30
	add r16,r18
	call sent_char
	ldi r16,0x30
	add r16,r17
	call sent_char

			ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x0c
	call sent_instruction
	call delay_1
	RET
	;--------------------------------------
		;procedura wyÅ›wietlaia ekranu 2
	displ_screen2:
			ldi r16,0x08		;adres ramu
	call sent_instruction
	call delay_1
	ldi r16,0x00
	call sent_instruction
	call delay_1
		ldi r17,16
	ldi zl,low(2*tekst5)
	ldi zh,high(2*tekst5)
	labs21: lpm r16,z+
	call sent_char
	dec r17
	brne labs21

	ldi r16,0x0c		;adres ramu
	call sent_instruction

	ldi r16,0x00
	call sent_instruction
	call delay_1

		ldi r17,16
	ldi zl,low(2*tekst6)
	ldi zh,high(2*tekst6)
	labs22: lpm r16,z+
	call sent_char
	dec r17
	brne labs22



			ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x0d
	call sent_instruction
	call delay_1



	 lds r16,light_hex_set
	 call hex_bcd
	 sts light_bcd_set1,r17
	 sts light_bcd_set2,r18
	 ldi r16,0x30
	 add r16,r18
	 call sent_char
	 ldi r16,0x30
	 add r16,r17
	 call sent_char

	 ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x0d
	call sent_instruction
	call delay_1

	RET
	;----------------------------------------
		;procedura wyÅ›wietlaia ekranu 3
	displ_screen3:
			ldi r16,0x08		;adres ramu
	call sent_instruction
	call delay_1
	ldi r16,0x00
	call sent_instruction
	call delay_1
		ldi r17,16
	ldi zl,low(2*tekst7)
	ldi zh,high(2*tekst7)
	labs31: lpm r16,z+
	call sent_char
	dec r17
	brne labs31

	ldi r16,0x0c		;adres ramu
	call sent_instruction

	ldi r16,0x00
	call sent_instruction
	call delay_1

		ldi r17,16
	ldi zl,low(2*tekst8)
	ldi zh,high(2*tekst8)
	labs32: lpm r16,z+
	call sent_char
	dec r17
	brne labs32
			ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x0b
	call sent_instruction
	call delay_1


	lds r16,delay_hex_set
	 call hex_bcd
	 sts delay_bcd_set_low,r17
	 sts delay_bcd_set_high,r18
	 ldi r16,0x30
	 add r16,r18
	 call sent_char
	 ldi r16,0x30
	 add r16,r17
	 call sent_char
			ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x0b
	call sent_instruction
	call delay_1

	RET
	;--------------------------
			;procedura wyÅ›wietlaia ekranu 0
	displ_screen0:
			ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x00
	call sent_instruction
	call delay_1


	ldi r17,16
	ldi zl,low(2*tekst1)
	ldi zh,high(2*tekst1)
	lab1: lpm r16,z+
	call sent_char
	dec r17
	brne lab1

	ldi r16,0x0c		;adres ramu
	call sent_instruction

	ldi r16,0x00
	call sent_instruction
	call delay_1

		ldi r17,16
	ldi zl,low(2*tekst2)
	ldi zh,high(2*tekst2)
	lab2: lpm r16,z+
	call sent_char
	dec r17
	brne lab2

			ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x05
	call sent_instruction
	call delay_1

	lds r16,temp_hex
	lsr r16
	subi r16,0x02

	call hex_bcd
	ldi r16,0x30
	add r16,r18
	call sent_char
	ldi r16,0x30
	add r16,r17
	call sent_char

	 ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x0c
	call sent_instruction
	call delay_1

	 lds r16,light_hex
	 call hex_bcd
	 ldi r16,0x30
	 add r16,r19
	 call sent_char
	 ldi r16,0x30
	 add r16,r18
	 call sent_char
	 ldi r16,0x30
	 add r16,r17
	 call sent_char

	  ldi r16,0x0c		;adres ramu
	call sent_instruction
	ldi r16,0x0b
	call sent_instruction
	call delay_1

	 lds r16,delay_hex
	 call hex_bcd
	 ldi r16,0x30
	 add r16,r18
	 call sent_char
	 ldi r16,0x30
	 add r16,r17
	 call sent_char

		ldi r16,0x08		;adres ramu
	call sent_instruction
	ldi r16,0x00
	call sent_instruction
	call delay_1
	ret
;-----------------------------teksty
tekst1: .DB 'T','E','M','P','=','0','0','C',' ','S','W','=','1','0','0','%'
tekst2: .DB 'O','P','O','Z','N','I','E','N','I','E','=','0','0','m','i','n'
tekst3: .DB 'T','E','M','P','.',' ','G','R','Z','A','.','=','0','0',' ','C'
tekst4: .DB 'T','E','M','P','.',' ','C','H','L','O','.','=','0','0',' ','C'
tekst5: .DB 'O','S','W','I','E','T','L','E','N','I','E','=',' ','0','0','%'
tekst6: .DB ' ',' ',' ',' ','.',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
tekst7: .DB 'O','P','O','Z','N','I','E','N','I','E','=','0','0','m','i','n'
tekst8: .DB ' ',' ',' ',' ','.',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' '
