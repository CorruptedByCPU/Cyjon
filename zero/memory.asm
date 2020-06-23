;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

;===============================================================================
zero_memory:
	; pozpocznij mapowanie od początku przestrzeni fizycznej pamięci
	xor	ebx,	ebx

	; ciąg znaków "SMAP", specjalna wartość wymagana przez procedurę
	mov	edx,	0x534D4150

	; utwórz mapę pamięci pod fizycznym adresem 0x0000:0x1000
	mov	edi,	zero_end
	call	zero_page_align_up

	; zachowaj adres dla jądra systemu
	mov	dword [zero_memory_map_address],	edi

.loop:
	; pobierz informacje o przestrzeni pamięci
	mov	eax,	0xE820	; funkcja Get System Memory Map
	mov	ecx,	0x14	; rozmiar wpisu w Bajtach, generowanej tablicy
	int	0x15

.error:
	; błąd podczas generowania?
	jc	.error	; tak

	; przesuń wskaźnik do następnego wpisu
	add	edi,	0x14

	; zakończyć generowanie tablicy?
	test	ebx,	ebx
	jnz	.loop	; nie

	; wstaw pusty wpis na koniec tablicy
	xor	al,	al
	rep	stosb
