;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"
	%include	"kernel/config.asm"
	;-----------------------------------------------------------------------

; 64 bitowy kod programu
[BITS 64]

; adresowanie względne
[DEFAULT REL]

; położenie kodu programu w pamięci logicznej
[ORG SOFTWARE_base_address]

;===============================================================================
free:
	; wyświetl nagłówek i pierwszą nazwę wiersza tabeli
	mov	ax,	KERNEL_SERVICE_VIDEO_string
	mov	ecx,	free_string_table_end - free_string_table
	mov	rsi,	free_string_table
	int	KERNEL_SERVICE

	; pobierz informacje o pamięci systemu
	mov	ax,	KERNEL_SERVICE_SYSTEM_memory
	int	KERNEL_SERVICE

	; pobierz pozycję kursora na ekranie
	mov	ax,	KERNEL_SERVICE_VIDEO_cursor
	int	KERNEL_SERVICE

	; zapamiętaj
	mov	r15,	rbx

	; TOTAL ----------------------------------------------------------------
	; wyświetl rozmiar całkowity pamięci
	mov	ax,	KERNEL_SERVICE_VIDEO_number
	mov	bl,	STATIC_NUMBER_SYSTEM_decimal
	xor	ecx,	ecx
	shl	r8,	STATIC_MULTIPLE_BY_4_shift	; strony zamień na KiB
	int	KERNEL_SERVICE

	; wyświetl typ rozmiaru i ustaw kursor na następną kolumnę
	call	free_column_fill

	; USED -----------------------------------------------------------------
	; wyświetl rozmiar wykorzystanej pamięci
	shl	r9,	STATIC_MULTIPLE_BY_4_shift	; strony zamień na KiB
	sub	r8,	r9
	int	KERNEL_SERVICE

	; wyświetl typ rozmiaru i ustaw kursor na następną kolumnę
	call	free_column_fill

	; FREE -----------------------------------------------------------------
	; wyświetl rozmiar wolnej pamięci
	mov	r8,	r9
	int	KERNEL_SERVICE

	; wyświetl typ rozmiaru i ustaw kursor na następną kolumnę
	call	free_column_fill

	; PAGED ---------------------------------------------------------------
	; wyswietl rozmiar pamięci stronicowanej
	mov	r8,	r10
	shl	r8,	STATIC_MULTIPLE_BY_4_shift	; strony zamień na KiB
	int	KERNEL_SERVICE

	; wyświetl typ rozmiaru i ustaw kursor na następną kolumnę
	call	free_column_fill

	; koniec programu
	xor	ax,	ax
	int	KERNEL_SERVICE

;===============================================================================
free_column_fill:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rbx

	; wyświetl typ rozmiaru
	mov	ax,	KERNEL_SERVICE_VIDEO_string
	mov	ecx,	free_string_kib_end - free_string_kib
	mov	rsi,	free_string_kib
	int	KERNEL_SERVICE

	; przesuń kursor na następną kolumnę
	add	r15,	14

	; wyświetl kursor na nowej pozycji
	mov	ax,	KERNEL_SERVICE_VIDEO_cursor_set
	mov	rbx,	r15
	int	KERNEL_SERVICE

	; przywróć oryginalne rejestry
	pop	rbx
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	;-----------------------------------------------------------------------
	%include	"software/free/data.asm"
	;-----------------------------------------------------------------------
