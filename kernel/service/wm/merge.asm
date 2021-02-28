;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_wm_merge:
	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge"

;===============================================================================
; wejście:
;	rax - wskaźnik do obiektu wypełniającego
;	r8w - pozycja na osi X
;	r9w - pozycja na osi Y
;	r10w - szerokość strefy
;	r11w - wysokość strefy
kernel_wm_merge_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rax

	; brak miejsca?
	cmp	qword [kernel_wm_merge_list_records],	KERNEL_WM_FRAGMENT_LIST_limit
	je	.end	; tak

	; zachowaj wskaźnik do obiektu wypełniającego
	push	rax

	; ustaw wskaźnik na koniec listy
	mov	rax,	qword [kernel_wm_merge_list_records]
	shl	rax,	STATIC_MULTIPLE_BY_16_shift
	add	rax,	qword [kernel_wm_merge_list_address]

	; dodaj do listy nową strefę
	mov	word [rax + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r8w
	mov	word [rax + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r9w
	mov	word [rax + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.width],	r10w
	mov	word [rax + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.height],	r11w

	; oraz jej obiekt zależny
	pop	qword [rax + KERNEL_WM_STRUCTURE_FRAGMENT.object]

	; zwiększono ilość elementów na liście
	inc	qword [kernel_wm_merge_list_records]

.end:
	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge_insert_by_register"

;===============================================================================
; wejście:
;	rax - wskaźnik do obiektu
kernel_wm_merge_insert_by_object:
	; zachowaj oryginalne rejestry
	push	rbx

	; brak miejsca?
	cmp	qword [kernel_wm_merge_list_records],	KERNEL_WM_FRAGMENT_LIST_limit
	je	.end	; tak

	; ustaw wskaźnik na koniec listy
	mov	rbx,	qword [kernel_wm_merge_list_records]
	shl	rbx,	STATIC_MULTIPLE_BY_16_shift
	add	rbx,	qword [kernel_wm_merge_list_address]

	; dodaj do listy nową strefę
	push	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.field]
	pop	qword [rbx + KERNEL_WM_STRUCTURE_FRAGMENT.field]

	; oraz jej obiekt zależny
	mov	qword [rbx + KERNEL_WM_STRUCTURE_FRAGMENT.object],	rax

	; zwiększono ilość elementów na liście
	inc	qword [kernel_wm_merge_list_records]

.end:
	; przywróć oryginalne rejestry
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge_insert_by_object"
