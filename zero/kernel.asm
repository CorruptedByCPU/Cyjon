;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

;===============================================================================
zero_kernel:
	; wyłącz przerwania sprzętowe na kontrolerze PIC
	call	zero_pic_disable

	; wyłącz obsługę wyjątków procesora i przerwań sprzętowych
	cli

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
