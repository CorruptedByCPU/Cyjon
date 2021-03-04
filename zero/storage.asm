;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
zero_storage:
	; rozmiar pliku jądra systemu w sektorach (512 Bajtów)
	mov	ecx,	KERNEL_FILE_SIZE_bytes / 0x0200

.loop:
	; wczytano cały plik jądra systemu?
	dec	ecx
	js	.end	; tak

	;-----------------------------------------------------------------------
	; wczytaj pierwszą część pliku jądra systemu
	;-----------------------------------------------------------------------
	mov	ah,	0x42
	mov	si,	zero_table_disk_address_packet
	int	0x13

	; następny sektor
	inc	dword [zero_table_disk_address_packet.sector]

	; przesuń offset na następną pozycję
	add	word [zero_table_disk_address_packet.offset],	0x0200	; 512 Bajtów
	jns	.loop	; wczytaj następną część

	; zmień segment danych
	add	word [zero_table_disk_address_packet.segment],	0x1000

	; kontynuuj
	jmp	.loop

.end:
