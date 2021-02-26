;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	r14w oraz r15w - delty dla kursora
kernel_wm_cursor:
	; zachowaj oryginalne rejestry
	push	rsi

	;-----------------------------------------------------------------------
	; wyświetlić nową zawartość macierzy kursora?
	;-----------------------------------------------------------------------
	test	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	KERNEL_WM_OBJECT_FLAG_flush
	jz	.no	; nie

	; ; aktualizuj specyfikacje obiektu kursora
	; add	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r14w
	; add	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r15w

	; zarejestruj strefę kursora
	mov	rsi,	kernel_wm_object_cursor
	call	kernel_wm_fill_insert_by_object
	call	kernel_wm_fill

	; obiekt kursora został wyświetlony
	and	word [kernel_wm_object_cursor + KERNEL_WM_STRUCTURE_OBJECT.SIZE + KERNEL_WM_STRUCTURE_OBJECT_EXTRA.flags],	~KERNEL_WM_OBJECT_FLAG_flush

.no:
	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_cursor"
