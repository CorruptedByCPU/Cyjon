;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; stałe, zmienne, globalne, struktury, obiekty, makra
	;-----------------------------------------------------------------------
	%include	"config.asm"
	;-----------------------------------------------------------------------
	%include	"kernel/config.asm"
	%include	"kernel/header/service.inc"
	%include	"kernel/header/vfs.inc"
	%include	"kernel/macro/debug.asm"
	;-----------------------------------------------------------------------
	%include	"software/moko/config.asm"
	;-----------------------------------------------------------------------

	; r8d	- szerokość przestrzeni dokumentu w znakach liczona od zera
	; r9d	- wysokość przestrzeni dokumentu w znakach liczona od zera
	; r10	- wskaźnik pozycji kursora w przestrzeni dokumentu
	; r11	- przesunięcie wew. linii
	; r12	- numer znaku (liczony od zera) od którego rozpocząć wyświetlanie linii
	; r13	- rozmiar linii w znakach
	; r14	- pozycja kursora na osi X
	; r15	- pozycja kursora na osi Y

; 64 bitowy kod programu
[bits 64]

; adresowanie względne
[default rel]

; położenie kodu programu w pamięci logicznej
[org SOFTWARE_base_address]

;===============================================================================
moko:
	; zakończ działanie programu
	xor	ax,	ax
	int	KERNEL_SERVICE

moko_end:
