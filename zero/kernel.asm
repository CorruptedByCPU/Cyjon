;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
zero_kernel:
	; wyłącz przerwania sprzętowe na kontrolerze PIC
	call	zero_pic_disable

	; wyłącz obsługę wyjątków procesora i przerwań sprzętowych
	cli

	; kopiuj kod jądra systemu w miejsce docelowe
	mov	ecx,	KERNEL_FILE_SIZE_bytes
	mov	esi,	0x00010000
	mov	edi,	0x00100000
	rep	movsb

	; zwróć informację o adresie i rozmiarze mapy pamięci
	mov	ebx,	dword [zero_memory_map_address]

	; zwróć informację o adresie tablicy ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK
	mov	edx,	dword [zero_graphics_mode_info_block_address]

	; odszukaj nagłówek "Z E R O " w całym pliku jądra systemu
	mov	rax,	"Z E R O "
	mov	esi,	0x00100000
	mov	ecx,	KERNEL_FILE_SIZE_bytes / 0x08

.search:
	; przetworzono cały plik jądra systemu?
	sub	ecx,	0x08
	js	.error	; tak

	; przesuń wskaźnik na następną pozycję
	add	rsi,	0x08

	; powównaj pierwsze 8 komórek pamięci
	cmp	qword [rsi - 0x08],	rax

	; znaleziono nagłówek?
	jne	.search	; nie

	; zwróć informacje o rozmiarze pliku jądra systemu w Bajtach
	mov	ecx,	KERNEL_FILE_SIZE_bytes

	; pobierz wskaźnik głównej funkcji jądra systemu
	mov	rax,	qword [rsi]

	; wyczyść rejestry nie biorące udziału z procesie
	xor	esi,	esi
	xor	edi,	edi
	xor	ebp,	ebp

	; wykonaj kod
	jmp	rax

.error:
	; zatrzymaj dalsze wykonywanie kodu
	hlt
	jmp	.error
