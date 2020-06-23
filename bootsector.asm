;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

;===============================================================================
; 16 bitowy kod programu rozruchowego ==========================================
;===============================================================================
[BITS 16]

; pozycja kodu/danych w przestrzeni pamięci fizycznej
[ORG 0x7C00]

;===============================================================================
bootsector:
	; wyłącz przerwania (modyfikujemy rejestry segmentowe)
	cli

	; ustaw adres segmentu kodu (CS) na początek pamięci fizycznej
	jmp	0x0000:.repair_cs

.repair_cs:
	; ustaw adresy segmentów danych (DS), ekstra (ES) i stosu (SS) na początek pamięci fizycznej
	xor	ax,	ax
	mov	ds,	ax	; segment danych
	mov	ss,	ax	; segment stosu

	; ustaw wskaźnik szczytu stosu na gwarantowaną wolną przestrzeń pamięci
	mov	sp,	bootsector

	; włącz przerwania
	sti

	;-----------------------------------------------------------------------
	; wczytaj główny kod programu rozruchowego
	;-----------------------------------------------------------------------
	mov	ah,	0x42
	mov	si,	bootsector_table_disk_address_packet
	int	0x13

	; jeśli wczytano poprawnie główny kod programu rozruchowego, wykonaj
	jnc	0x1000

	; zatrzymaj dalsze wykonywanie kodu programu rozruchowego
	jmp	$

;-------------------------------------------------------------------------------
; format danych w postaci tablicy, wykorzystywany przez funkcję AH=0x42, przerwanie 0x13
; http://www.ctyme.com/intr/rb-0708.htm
;-------------------------------------------------------------------------------
; wszystkie tablice trzymamy pod pełnym adresem
align 0x04
bootsector_table_disk_address_packet:
	db	0x10	; rozmiar tablicy
	db	0x00	; wartość zastrzeżona
	dw	ZERO_FILE_SIZE_bytes / 0x0200	; oblicz rozmiar pliku dołączonego do sektora rozruchowego
	dw	0x1000	; przesunięcie
	dw	0x0000	; segment
	dq	0x0000000000000001	; adres LBA pierwszego sektora dołączonego pliku

;-------------------------------------------------------------------------------
; znacznik sektora rozruchowego
times	510 - ($ - $$)	db	0x00
			dw	0xAA55	; czysta magija ;>
