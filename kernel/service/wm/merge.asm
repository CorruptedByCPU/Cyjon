;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - wskaźnik do obiektu wypełniającego
;	r8w - pozycja na osi X
;	r9w - pozycja na osi Y
;	r10w - szerokość strefy
;	r11w - wysokość strefy
kernel_wm_merge_insert_by_register:
	; zachowaj oryginalne rejestry
	; przywróć oryginalne rejestry

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge_insert_by_register"

;===============================================================================
; wejście:
;	rsi - wskaźnik do obiektu
kernel_wm_merge_insert_by_object:
	; zachowaj oryginalne rejestry
	; przywróć oryginalne rejestry

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge_insert_by_object"

;===============================================================================
kernel_wm_merge:
	; zachowaj oryginalne rejestry
	; przywróć oryginalne rejestry

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge"
