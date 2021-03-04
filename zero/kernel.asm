;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
zero_kernel:
	xchg	bx,bx

	; wyłącz przerwania sprzętowe na kontrolerze PIC
	call	zero_pic_disable

	; wyłącz obsługę wyjątków procesora i przerwań sprzętowych
	cli

	; kopiuj kod jądra systemu w miejsce docelowe
	mov	ecx,	KERNEL_FILE_SIZE_bytes / 0x08
	mov	esi,	0x00010000
	mov	edi,	0x00100000
	rep	movsq

	; zwróć informację o adresie i rozmiarze mapy pamięci
	mov	ebx,	dword [zero_memory_map_address]

	; zwróć informację o adresie tablicy ZERO_STRUCTURE_GRAPHICS_MODE_INFO_BLOCK
	mov	edx,	dword [zero_graphics_mode_info_block_address]

	; wyczyść pozostałę rejestry
	xor	eax,	eax
	xor	ecx,	ecx
	xor	esi,	esi
	xor	edi,	edi

	; wykonaj kod jądra systemu
	jmp	0x0000000000100000
