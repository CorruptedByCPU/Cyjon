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

	; wyświetl informację o aktualnej czynności
	mov	si,	zero_string_header
	call	zero_print_string
	mov	si,	zero_string_loading
	call	zero_print_string

	; plik jądra systemu
	mov	cl,	(((zero_end - zero) + 0x200) / 0x200) + 0x01	; pozycja pliku jądra systemu za programem rozruchowym
	mov	di,	KERNEL_FILE_SIZE_bytes / 0x0200	; rozmiar w sektorach
	call	zero_floppy
	jnc	.end	; wczytano popwanie

	; wyświetl komunikat o błędzie
	mov	si,	zero_string_error_kernel
	call	zero_print_string

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

	;-----------------------------------------------------------------------
	; procedura wczytująca plik jądra systemu z nośnika
	;-----------------------------------------------------------------------
	%include	"zero/floppy.asm"

zero_storage.end:
	; przywróć oryginalny segment ekstra
	pop	es
