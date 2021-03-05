;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

	;-----------------------------------------------------------------------
	; pierwsza część programu rozruchowego
	;-----------------------------------------------------------------------
	incbin	"build/bootsector"

	;-----------------------------------------------------------------------
	; główny plik programu rozruchowego
	;-----------------------------------------------------------------------
	incbin	"build/zero"

	;-----------------------------------------------------------------------
	; plik jądra systemu
	;-----------------------------------------------------------------------
	incbin	"build/kernel"

	; VirtualBox wymaga obrazu o rozmiarze min. 1 MiB

; wyrównaj rozmiar obrazu dysku do pełnego 1,44 MiB
times	1474560 - ($ - $$)	db	0x00
