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
moko_key:
	; naciśnięto klawisz CTRL?
	cmp	ax,	STATIC_SCANCODE_CTRL_LEFT
 	jne	.no_ctrl	; nie

 	; podnieś flagę
 	mov	byte [moko_key_ctrl_semaphore],	STATIC_TRUE
 	jmp	.end	; obsłużono klawisz

 .no_ctrl:
 	; puszczono klawisz CTRL?
 	cmp	ax,	STATIC_SCANCODE_CTRL_LEFT + STATIC_SCANCODE_RELEASE_mask
 	jne	.no_ctrl_release	; nie

 	; opuść flagę
 	mov	byte [moko_key_ctrl_semaphore],	STATIC_FALSE
 	jmp	.end	; obsłużono klawisz

.no_ctrl_release:
	; naciśnięto klawisz INSERT?
	cmp	ax,	STATIC_SCANCODE_INSERT
	jne	.no_insert	; nie

	; podnieś flagę
	mov	byte [moko_key_insert_semaphore],	STATIC_TRUE
	jmp	.end	; obsłużono klawisz

.no_insert:
	; puszczono klawisz INSERT?
	cmp	ax,	STATIC_SCANCODE_INSERT + STATIC_SCANCODE_RELEASE_mask
	jne	.no_insert_release	; nie

	; opuść flagę
 	mov	byte [moko_key_insert_semaphore],	STATIC_FALSE
 	jmp	.end	; obsłużono klawisz

.no_insert_release:
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
