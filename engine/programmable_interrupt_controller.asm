;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

variable_pic_mask						dw	1111111111111111b	; irq15, irq14, irq13, irq12, irq11, irq10, irq9, irq8, irq7, irq6, irq5, irq4, irq3, irq2, irq1, irq0

; 64 Bitowy kod programu
[BITS 64]

;===============================================================================
; procedura przemapowuje numery przerwań sprzetowych pod 0x20..0x2F
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
programmable_interrupt_controller:
	; zachowaj oryginalne rejestry
	push	rax

	; przełącz obydwa układy w tryb inicjalizacji
	mov	al,	0x11
	out	VARIABLE_PIC_COMMAND_PORT0,	al
	out	VARIABLE_PIC_COMMAND_PORT1,	al

	; przeindeksuj pic0 (master) na przerwania od 0x20 do 0x27
	mov	al,	0x20
	out	VARIABLE_PIC_DATA_PORT0,	al

	; przeindeksuj pic1 (slave) na przerwania od 0x28 do 0x2F
	mov	al,	0x28
	out	VARIABLE_PIC_DATA_PORT1,	al

	; pic0 ustaw jako główny (master) i poinformuj o istnieniu pic1
	mov	al,	4
	out	VARIABLE_PIC_DATA_PORT0,	al

	; pic1 ustaw jako pomocniczy (slave)
	mov	al,	2
	out	VARIABLE_PIC_DATA_PORT1,	al

	; obydwa kontrolery w tryb 8086
	mov	al,	1
	out	VARIABLE_PIC_DATA_PORT0,	al
	out	VARIABLE_PIC_DATA_PORT1,	al

	; wyłącz tymczasowo wszystkie przerwania sprzętowe
	; nie powinny były być włączone, dmuchamy na zimne
	mov	al,	byte [variable_pic_mask + VARIABLE_BYTE_SIZE]
	out	VARIABLE_PIC_DATA_PORT1,	al	; pic1 (slave)

	mov	al,	byte [variable_pic_mask]
	out	VARIABLE_PIC_DATA_PORT0,	al	; pic0 (master)

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura włącza przerwanie na kontrolerze PIC
; IN:
;	cx - numer przerwania IRQ
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_programmable_interrupt_controller_enable_irq:
	; zachowaj oryginalne rejestry
	push	rax

	;ustaw maskę kontrolera
	btr	word [variable_pic_mask],	cx

	; jeśli numer przerwania sprzętowego > 7
	cmp	cx,	8
	jb	.ok

	; włącz obsługę przerwań kaskadowych (obsługa kontrolera PIC1 i innych)
	btr	word [variable_pic_mask],	2

.ok:
	; przełąduj ustawienia kontrolera
	mov	al,	byte [variable_pic_mask + VARIABLE_BYTE_SIZE]
	out	VARIABLE_PIC_DATA_PORT1,	al	; pic1 (slave)
	mov	al,	byte [variable_pic_mask]
	out	VARIABLE_PIC_DATA_PORT0,	al	; pic0 (master)

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

;===============================================================================
; procedura wyłącza przerwanie na kontrolerze PIC
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_programmable_interrupt_controller_disable_irq:
	; zachowaj oryginalne rejestry
	push	rax

	;ustaw maskę kontrolera
	bts	word [variable_pic_mask],	cx

	; jeśli numer przerwania sprzętowego > 7
	cmp	cx,	8
	jb	.ok

	; włącz obsługę przerwań kaskadowych (obsługa kontrolera PIC1 i innych)
	btr	word [variable_pic_mask],	2

.ok:
	; przełąduj ustawienia kontrolera
	mov	al,	byte [variable_pic_mask + VARIABLE_BYTE_SIZE]
	out	VARIABLE_PIC_DATA_PORT1,	al	; pic1 (slave)
	mov	al,	byte [variable_pic_mask]
	out	VARIABLE_PIC_DATA_PORT0,	al	; pic0 (master)

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret
