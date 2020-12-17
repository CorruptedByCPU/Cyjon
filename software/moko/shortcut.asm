;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	ax - kod klawisza
moko_shortcut:
	; naciśnięto klawisz "x"?
	cmp	ax,	"x"
	jne	.no_key	; nie

	; przytrzymano klawisz CTRL?
	cmp	byte [moko_key_ctrl_semaphore],	STATIC_FALSE
	je	.no_key	; nie

	; koniec działania programu
	jmp	moko.end

.no_key:
	; nie rozpoznano skrótu klawiszowego
	stc

	; powrót z procedury
	ret
