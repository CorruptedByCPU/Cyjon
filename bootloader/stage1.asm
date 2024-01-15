;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

%include	"config.asm"

; 16 bitowy kod programu
[BITS 16]

; położenie kodu programu w pamięci fizycznej 0x0000:0x7C00
[ORG 0x7C00]

start:
	; wyłącz przerwania
	cli

	; niektóre BIOSy mogą ustawiać niepoprawny segment kodu tj. 0x07C0:0x0000
	; wykonaj daleki skok, by naprawić tą przypadłość
	jmp	0x0000:.repair_cs

.repair_cs:
	; wyczyść AX
	xor	ax,	ax

	; ustaw segmenty danych, ekstra i stosu na pierwsze 64 KiB pamięci fizycznej
	mov	ds,	ax	; segment danych
	mov	es,	ax	; segment ekstra
	mov	ss,	ax	; segment stosu

	; ustaw wskaźnik stosu na "koniec" segmentu danych/stosu
	xor	sp,	sp

	; włącz przerwania
	sti

	; wyczyść DirectionFlag
	cld

	; skorzystamy z przerwania 0x13, procedury 0x42
	; istnieją jednostki lub inne złomy, których BIOS nie udostępnia danej procedury, gdy o nią wpierw nie zapytamy
	mov	ah,	0x41	; procedura - sprawdź dostępne rozszerzenia
	mov	bx,	0x55AA	; wartość wymagana przez procedurę
	int	0x13

	; jeśli flaga CF została ustawiona to pewnym jest, że procedura 0x42 nie jest dostępna w danym BIOSie
	jc	.bios_not_supported

	; sprawdź czy BH i BL zostało zamienione miejscami
	; jeśli nie, brak dostępnej procedury
	cmp	bx,	0x55AA
	je	.bios_not_supported

	; ostatnie co potrzebujemy sprawdzić to bit 0 w rejestrze CL
	bt	cx,	0	; skopiuj bit 0 do flagi CF
	jnc	.bios_not_supported	; jeśli flaga nie jest ustawiona, brak procedury

	; rozpoczynamy wczytanie programu rozruchowego do pamięci
	mov	ah,	0x42	; procedura - rozszerzony odczyt danych
	mov	si,	variable_table_disk_address_packet	; o rozmiarze i miejscu docelowym opisanym za pomocą pakietu danych
	int	0x13	; wykonaj funkcje - rozszerzony odczyt z nośnika

	; sprawdź czy operacja wczytania danych przebiegła pomyślnie
	jc	.read_error	; jeśli nie, wyświetl stosowną informację

	; posprzątaj po sobie
	xor	eax,	eax
	xor	ebx,	ebx
	xor	ecx,	ecx
	xor	edx,	edx
	xor	ebp,	ebp
	xor	esi,	esi
	xor	edi,	edi

	; skocz do załadowanego programu rozruchowego
	jmp	0x0000:0x1000

.bios_not_supported:
	; wyświetl informacje o braku możliwości załadowania drugiej części programu rozruchowego
	mov	si,	text_error_bios_unsupported
	call	stage2_print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

.read_error:
	; wystąpił błąd podczas wczytywania pliku Stage2
	mov	si,	text_error_read
	call	stage2_print_16bit

	; przesuń kod błędu do AL
	movzx	eax,	ah
	call	stage2_print_number_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$	

%include	"bootloader/stage2/print_16bit.asm"
%include	"bootloader/stage2/print_number_16bit.asm"

variable_table_disk_address_packet:
	db	0x10	; rozmiar struktury
	db	0x00	; zarezerwowane
	dw	0x0030	; ilość sektorów do odczytania (24 KiB)
	; gdzie zapisać odczytane dane
	dw	0x1000	; przesunięcie
	dw	0x0000	; segment
	; bezwzględny (LBA, liczony od zera) numer sektora do odczytu
	dq	0x0000000000000001	; drugi sektor, w pierwszym jest MBR

text_error_bios_unsupported	db	"Unsupported BIOS version!", VARIABLE_ASCII_CODE_ENTER, VARIABLE_ASCII_CODE_NEWLINE, VARIABLE_ASCII_CODE_TERMINATOR
text_error_read			db	"Read error, code 0x",	VARIABLE_ASCII_CODE_TERMINATOR

; uzupełniamy niewykorzystaną przestrzeń po samą tablicę partycji
times	436 - ( $ - $$ )	db	VARIABLE_EMPTY

%include	"bootloader/stage2/partition_table.asm"

; uzupełniamy niewykorzystaną przestrzeń
times	510 - ( $ - $$ )	db	VARIABLE_EMPTY

; znacznik sektora rozruchowego
dw	0xAA55	; czysta magija

; dołącz program rozruchowy
incbin	"build/stage2.bin"

; na systemach z rodziny MS/Windows, oprogramowanie Bochs wymaga obrazu dysku o rozmiarze >= 1MiB i wyrównanego do pełnego sektora (512 Bajtów)
times	512 * 2048 - ( $ - $$ )	db	0x00

; dołącz wirtualną partycję FAT16
incbin	"build/partition_fat16.raw"
