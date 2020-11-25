;===============================================================================
; Copyright (C) 2013+ by Andrzej Adamczyk at Wataha.net
;===============================================================================

;===============================================================================
; wejście:
;	ax - kod klawisza
moko_key:
	; naciśnięto klawisz CTRL?
	cmp	ax,	STATIC_ASCII_CTRL_LEFT
 	jne	.no_ctrl	; nie

 	; podnieś flagę
 	mov	byte [moko_key_ctrl_semaphore],	STATIC_TRUE
 	jmp	.end	; obsłużono klawisz

 .no_ctrl:
 	; puszczono klawisz CTRL?
 	cmp	ax,	STATIC_ASCII_CTRL_LEFT + STATIC_ASCII_RELEASE_mask
 	jne	.no_ctrl_release	; nie

 	; opuść flagę
 	mov	byte [moko_key_ctrl_semaphore],	STATIC_FALSE
 	jmp	.end	; obsłużono klawisz

.no_ctrl_release:
	; naciśnięto klawisz "x"?
	cmp	ax,	"x"
	jne	.no_exit	; nie

	; przytrzymano klawisz CTRL?
	cmp	byte [moko_key_ctrl_semaphore],	STATIC_FALSE
	je	.no_exit	; nie

	; koniec działania programu
	jmp	moko.end

.no_exit:
	; inny klawisz
	nop

.error:
	; brak obsługi klawisza
	stc

.end:
	; powrót z procedury
	ret
