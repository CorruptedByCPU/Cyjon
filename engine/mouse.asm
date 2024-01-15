;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; http://forum.osdev.org/viewtopic.php?t=24277

; 64 bitowy kod programu
[BITS 64]

mouse:
	; powrót z procedury
	ret

mouse_wait:
	; zachowaj oryginalny rejestr
	push	rcx

	; ilość prób
	mov	rcx,	1000

.loop:
	; pobierz status
	in	al,	0x64

	; status w porządku?
	and	al,	bl
	jnz	.end

	; czekaj
	dec	rcx
	jnz	.loop	; nie, czekaj dalej

.end:
	; przywtóć oryginalny rejestr
	pop	rcx

	; powrót z procedury
	ret

mouse_write:
	; zachowaj oryginalny rejestr
	push	rbx
	push	rax

	; czekaj na wolny zapis
	mov	bl,	2
	call	mouse_wait

	; wyślij polecenie
	mov	al,	0xD4
	out	0x64,	al
	; czekaj na przetworzenie
	call	mouse_wait

	; przywróć polecenie
	pop	rax

	; wyślij polecenie
	out	0x60,	al

	; przywróć oryginalny rejestr
	pop	rbx

mouse_read:
	; zachowaj oryginalny rejestr
	push	rbx

	; czekaj na wolny odczyt
	mov	bl,	1
	call	mouse_wait

	; odbierz status
	in	al,	0x60

	; przywróć oryginalny rejestr
	pop	rbx

	; powrót z procedury
	ret
