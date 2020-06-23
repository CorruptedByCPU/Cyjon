;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

;===============================================================================
zero_storage:
	; inicjalizuj dostępne nośniki
	call	driver_ide_init

	; TODO: systemy plików, więcej sektorów na raz

	; wczytaj plik jądra systemu

	; pierwszy sektor zawierający dane pliku jądra systemu
	mov	eax,	((zero_end - zero) + 0x200) / 0x200

	; nośnik Master na kontrolerze IDE0
	xor	ebx,	ebx

	; odczytujemy plik po jednym sektorze na raz
	mov	ecx,	1

	; rozmiar pliku jądra systemu w sektorach
	mov	edx,	(KERNEL_FILE_SIZE_bytes / 0x200)

	; wskaźnik docelowy w przestrzeni pamięci fizycznej/logicznej
	mov	edi,	0x00100000

.loop:
	; wczytaj sektor
	call	driver_ide_read

	; następny sektor
	inc	eax

	; przesuń wskaźnik docelowy
	add	edi,	0x0200

	; koniec sektorów należących do pliku?
	dec	edx
	jnz	.loop	; nie
