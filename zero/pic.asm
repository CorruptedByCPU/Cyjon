;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

;===============================================================================
zero_pic:
	; przełącz obydwa układy w tryb inicjalizacji
	mov	al,	0x11
	out	0x20,	al
	out	0xA0,	al

	; przeindeksuj pic0 (master) na przerwania od 0x20 do 0x27
	mov	al,	0x20
	out	0x21,	al

	; przeindeksuj pic1 (slave) na przerwania od 0x28 do 0x2F
	mov	al,	0x28
	out	0xA1,	al

	; pic0 ustaw jako główny (master) i poinformuj o istnieniu pic1
	mov	al,	4
	out	0x21,	al

	; pic1 ustaw jako pomocniczy (slave)
	mov	al,	2
	out	0xA1,	al

	; obydwa kontrolery w tryb 8086
	mov	al,	1
	out	0x21,	al
	out	0xA1,	al

	; wyłącz tymczasowo wszystkie przerwania sprzętowe
	; nie powinny były być włączone, dmuchamy na zimne
	mov	al,	11111111b	; irq15, irq14, irq13, irq12, irq11, irq10, irq9, irq8
	out	0xA1,	al	; pic1 (slave)

	mov	al,	11011110b	; irq7, irq6, sound, irq4, irq3, irq2, keyboard, sheduler/clock
	out	0x21,	al	; pic0 (master)

	; kontynuuj
	jmp	zero_pic_end

;===============================================================================
zero_pic_disable:
	; wyłącz przerwania na kontrolerze PIC
	mov	al,	0xFF
	out	0x00A1,	al	; Slave
	out	0x0021,	al	; Master

	; powrót z procedury
	ret

;===============================================================================
zero_pic_end:
