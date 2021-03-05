;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; 16 bitowy kod programu rozruchowego ==========================================
;===============================================================================
[bits 16]

; pozycja kodu/danych w przestrzeni pamięci fizycznej
[org 0x7C00]

;===============================================================================
bootsector:
	; wyłącz przerwania (modyfikujemy rejestry segmentowe)
	cli

	; ustaw adres segmentu kodu (CS) na początek pamięci fizycznej
	jmp	0x0000:.repair_cs

.header:
; nagłówek sektora rozruchowego wyrównaj do pełnego adresu
align 0x04
	db	"ZERO"

.repair_cs:
	; ustaw adresy segmentów danych (DS), ekstra (ES) i stosu (SS) na początek pamięci fizycznej
	xor	ax,	ax
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

	; ustaw wskaźnik szczytu stosu na gwarantowaną wolną przestrzeń pamięci
	mov	sp,	bootsector

	; włącz przerwania
	sti

	; załaduj drugą część programu rozruchowego
	mov	bx,	0x1000	; adres docelowy pogramu rozruchowego
	mov	cl,	2	; rozpocznij od "drugiego" sektora
	mov	di,	ZERO_FILE_SIZE_bytes / 0x0200	; rozmiar programu rozruchowego
	call	zero_floppy

	; jeśli wczytano poprawnie główny kod programu rozruchowego, wykonaj
	jnc	0x1000

	; zatrzymaj dalsze wykonywanie kodu programu rozruchowego
	jmp	$

	;-----------------------------------------------------------------------
	%include	"zero/floppy.asm"
	;-----------------------------------------------------------------------

;-------------------------------------------------------------------------------
; znacznik sektora rozruchowego
times	510 - ($ - $$)	db	0x00
			dw	0xAA55	; czysta magija ;>
