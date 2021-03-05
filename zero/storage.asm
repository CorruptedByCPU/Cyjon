;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
zero_storage:
	; zachowaj orginalny segment ekstra
	push	es

	; adres docelowy jądra systemu
	mov	ax,	0x1000
	mov	es,	ax	; segment
	xor	bx,	bx	; przesunięcie

	; załaduj drugą część programu rozruchowego
	mov	cl,	(((zero_end - zero) + 0x200) / 0x200) + 0x01	; rozpocznij od "drugiego" sektora
	mov	di,	KERNEL_FILE_SIZE_bytes / 0x0200	; rozmiar programu rozruchowego
	call	zero_floppy
	jnc	.end	; wczytano popwanie

	jmp	$

	;-----------------------------------------------------------------------
	; procedura wczytująca plik jądra systemu z nośnika
	;-----------------------------------------------------------------------
	%include	"zero/floppy.asm"

zero_storage.end:
	; przywróć oryginalny segment ekstra
	pop	es
