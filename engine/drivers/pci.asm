;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 64 bitowy kod
[BITS 64]

;=======================================================================
; procedura pobierz informacje z urządzenia na magistrali PCI
; IN:
;	bl - szyna
;	cl - urządzenie
;	dl - funkcja/rejestr
; OUT:
;	eax - odpowiedź
;
; pozostałe rejestry zachowane
cyjon_pci_read:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx

	; załaduj ustaw bit 31 oraz wyłącz bity 30..24
	mov	eax,	10000000b
	shl	eax,	8
	; załaduj numer szyny do bitów 23..16
	mov	al,	bl
	shl	eax,	8
	; załaduj numer urządzenia, funkcji do bitów 15..8
	mov	al,	cl
	shl	eax,	6
	; załaduj numer rejestru do bitów 7..2
	mov	al,	dl
	shl	eax,	2	; wyłącz bity 1..0

	; poproś o informacje w danym rejestrze
	mov	dx,	VARIABLE_PCI_CONFIG_ADDRESS
	out	dx,	eax	; wyślij polecenie

	; odbierz odpowiedź
	mov	dx,	VARIABLE_PCI_CONFIG_DATA
	in	eax,	dx

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret

;=======================================================================
; procedura wysyła informacje do urządzenia na magistrali PCI
; IN:
;	eax - wartość
;	bl - szyna
;	cl - urządzenie
;	dl - funkcja/rejestr
; OUT:
;	brak
;
; wszystkie rejestry zachowane
cyjon_pci_write:
	; zachowaj oryginalne rejestry
	push	rbx
	push	rcx
	push	rdx
	push	rax

	; załaduj ustaw bit 31 oraz wyłącz bity 30..24
	mov	eax,	10000000b
	shl	eax,	8
	; załaduj numer szyny do bitów 23..16
	mov	al,	bl
	shl	eax,	8
	; załaduj numer urządzenia, funkcji do bitów 15..8
	mov	al,	cl
	shl	eax,	6
	; załaduj numer rejestru do bitów 7..2
	mov	al,	dl
	shl	eax,	2	; wyłącz bity 1..0

	; poproś o informacje w danym rejestrze
	mov	dx,	VARIABLE_PCI_CONFIG_ADDRESS
	out	dx,	eax	; wyślij polecenie

	; przywróc wartość do wysłania
	pop	rax

	; odbierz odpowiedź
	mov	dx,	VARIABLE_PCI_CONFIG_DATA
	out	dx,	eax

	; przywróć oryginalne rejestry
	pop	rdx
	pop	rcx
	pop	rbx

	; powrót z procedury
	ret
