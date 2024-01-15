;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; trzymaj wszystkie newralgiczne tablice, wyrównane do pełnego adresu
align	0x08

variable_gdt_structure:
	.limit							dw	VARIABLE_MEMORY_PAGE_SIZE	; rozmiar tablicy GDT
	.address						dq	VARIABLE_EMPTY

; utworzone zostaną tylko 4 deskryptory dla segmentów
; z czego pierwszy (0x0000) jest deskryptorem NULL, TSS będzie 5-tym
variable_tss_descriptor						dw	0x0028	; 5 * 0x08

; trzymaj wszystkie newralgiczne tablice, wyrównane do pełnego adresu
align	0x08

variable_tss_structure:
								dd	VARIABLE_EMPTY			; zastrzeżone
								; wbudowany debugger w oprogramowanie Bochs, posiada jakiś wewnętrzny problem z samym sobą
								; dlatego, jeśli nie korzystasz z tego debuggera możesz usunąć wartość 0x08,
								; sprawia ona tylko to, że na stosie kontekstu procesów podczas pierwszego uruchomienia programu
								; znajduje się 8-mio Bajtowa wartość 0x0000000000000000, nic więcej, nic mniej
								dq	VARIABLE_MEMORY_HIGH_VIRTUAL_ADDRESS - 0x08	; RSP0
						times	2	dq	VARIABLE_EMPTY	; RSP1..2
								dd	VARIABLE_EMPTY	; zastrzeżone
								dd	VARIABLE_EMPTY	; zastrzeżone
						times	7	dq	VARIABLE_EMPTY	; IST1..7
								dd	VARIABLE_EMPTY	; zastrzeżone
								dd	VARIABLE_EMPTY	; zastrzeżone
								dw	VARIABLE_EMPTY	; zastrzeżone
								dw	VARIABLE_EMPTY	; I/O Map Base Address

; 64 Bitowy kod programu
[BITS 64]

;===============================================================================
; tworzy globalną tablicę deskryptorów, nie korzystamy z przygotowanej przez bootloader (zawsze własna i pewny adres)
; IN:
;	brak
; OUT:
;	brak
;
; wszystkie rejestry zachowane
global_descriptor_table:
	; zachowaj oryginalne rejestry
	push	rax
	push	rdi

	; zarezerwuj jedną stronę dla Globalnej Tablicy Deskryptorów
	call	cyjon_page_allocate
	cmp	rdi,	VARIABLE_EMPTY
	ja	.ok

	; wyświetl informację o błędzie alokacji przestrzeni pamięci pod tablicę GDT
	mov	rsi,	text_kernel_panic_gdt
	call	cyjon_screen_kernel_panic

.ok:
	; wyczyść stronę
	call	cyjon_page_clear

	; zapisz adres Globalnej Tablicy Deskryptorów
	mov	qword [variable_gdt_structure.address],	rdi

	; Globalna Tablica Deskryptorów to bardzo ciężki kawałek chleba dla wszystkich
	; osób, które pierwszy raz się z nią spotykają. Gdy czas pozwoli, opiszę dokładnie
	; na stronie http://wataha.net/, teraz musisz się zadowolić formą skompresowaną.

	; utwórz deskryptor NULL
	xor	rax,	rax	; 0x0000000000000000
	stosq	; zapisz

	; utwórz deskryptor kodu (CS)
	mov	rax,	0000000000100000100110000000000000000000000000000000000000000000b
	stosq	; zapisz

	; utwórz deskryptor danych/stosu (DS/SS)
	mov	rax,	0000000000100000100100100000000000000000000000000000000000000000b
	stosq	; zapisz

	; utwórz deskryptor kodu ring3 (CS)
	mov	rax,	0000000000100000111110000000000000000000000000000000000000000000b
	stosq	; zapisz

	; utwórz deskryptor danych/stosu ring3 (DS/SS)
	mov	rax,	0000000000100000111100100000000100000000000000000000000000000000b
	stosq	; zapisz

	; załadowanie skompresowanej wersji deskryptora Task State Segment
	; już nie jest proste, nie wiemy gdzie będzie
	; znajdować się tablica Task State Segment po kompilacji
	;
	; trzeba wykonać obliczenia

	; utwórz deskryptor Task State Segment
	mov	ax,	0x0068	; rozmiar tablicy Task State Segment w Bajtach (104 Bajty)
	stosw	; zapisz

	; pobierz adres fizyczny tablicy Task State Segment
	mov	rax,	variable_tss_structure
	stosw	; zapisz (bity 15..0)
	shr	rax,	16	; przesuń starszą część rejestru EAX do AX
	stosb	; zapisz (bity 23..16)

	; zachowaj pozostałą część adresu tablicy Task State Segment
	push	rax

	; uzupełnij deskryptor Task State Segment o flagi
	mov	al,	10001001b	; P, DPL, 0, Type
	stosb	; zapisz
	xor	al,	al		; G, 0, 0, AVL, Limit (starsza część rozmiaru tablicy Task State Segment)
	stosb	; zapisz

	; przywróć pozostałą część adresu tablicy Task State Segment
	pop	rax

	; przenieś bity 31..24 do rejestru AL
	shr	rax,	8
	stosb	; zapisz (bity 31..24)

	; przenieś bity 63..32 do rejestru EAX
	shr	rax,	8
	stosd	; zapisz (bity 63..32)

	; 32 Bajty deskrytptora - zastrzeżone
	xor	rax,	rax
	stosd	; zapisz

	; przeładuj Globalną Tablicę Deskryptorów
	lgdt	[variable_gdt_structure]

	; załaduj deskryptor Task State Segment
	ltr	word [variable_tss_descriptor]

	; przywróć oryginalne rejestry
	pop	rdi
	pop	rax

	; powrót z procedury
	ret
