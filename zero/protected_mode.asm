;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

;===============================================================================
zero_protected_mode:
	; wyłącz przerwania, jeśli program rozruchowy jest w trybie 16 bitowym
	; zostaną one przywrócone
	cli

	; załaduj globalną tablicę deskryptorów dla trybu 32 bitowego
	lgdt	[zero_protected_mode_header_gdt_32bit]

	; przełącz procesor w tryb chroniony
	mov	eax,	cr0
	bts	eax,	0	; włącz pierwszy bit rejestru cr0
	mov	cr0,	eax

	; skocz do 32 bitowego kodu
	jmp	long 0x0008:zero_protected_mode_entry

; wszystkie tablice trzymamy pod pełnym adresem
align 0x10
zero_protected_mode_table_gdt_32bit:
	; deskryptor zerowy
	dq	0x0000000000000000
	; deskryptor kodu
	dq	0000000011001111100110000000000000000000000000001111111111111111b
	; deskryptor danych
	dq	0000000011001111100100100000000000000000000000001111111111111111b
zero_protected_mode_table_gdt_32bit_end:

zero_protected_mode_header_gdt_32bit:
	dw	zero_protected_mode_table_gdt_32bit_end - zero_protected_mode_table_gdt_32bit - 0x01
	dd	zero_protected_mode_table_gdt_32bit

;===============================================================================
; 32 bitowy kod programu rozruchowego ==========================================
;===============================================================================
[BITS 32]

zero_protected_mode_entry:
	; ustaw deskryptory danych, ekstra i stosu na przestrzeń danych
	mov	ax,	0x10
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu
