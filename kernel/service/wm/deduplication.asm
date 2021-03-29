;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
; wejście:
;	rax - wskaźnik do obiektu
kernel_wm_deduplication_insert_by_object:
	; zachowaj oryginalne rejestry
	push	rbx

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	kernel_wm_zone_semaphore,	0

	; brak miejsca?
	cmp	qword [kernel_wm_deduplication_list_records],	KERNEL_WM_FRAGMENT_LIST_limit
	je	.end	; tak

	; ustaw wskaźnik na koniec listy
	mov	rbx,	qword [kernel_wm_deduplication_list_records]
	shl	rbx,	STATIC_MULTIPLE_BY_16_shift
	add	rbx,	qword [kernel_wm_deduplication_list_address]

	; dodaj do listy nową strefę
	push	qword [rax + KERNEL_WM_STRUCTURE_OBJECT.field]
	pop	qword [rbx + KERNEL_WM_STRUCTURE_FRAGMENT.field]

	; zwiększono ilość elementów na liście
	inc	qword [kernel_wm_deduplication_list_records]

.end:
	; odblokuj listę stref do modyfikacji
	mov	byte [kernel_wm_deduplication_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_deduplication_insert_by_object"

;===============================================================================
; wejście:
;	r8w - pozycja na osi X
;	r9w - pozycja na osi Y
;	r10w - szerokość strefy
;	r11w - wysokość strefy
kernel_wm_deduplication_insert_by_register:
	; zachowaj oryginalne rejestry
	push	rbx

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	kernel_wm_deduplication_semaphore,	0

	; brak miejsca?
	cmp	qword [kernel_wm_deduplication_list_records],	KERNEL_WM_FRAGMENT_LIST_limit
	je	.end	; tak

	; ustaw wskaźnik na koniec listy
	mov	rbx,	qword [kernel_wm_deduplication_list_records]
	shl	rbx,	STATIC_MULTIPLE_BY_16_shift
	add	rbx,	qword [kernel_wm_deduplication_list_address]

	; dodaj do listy nową strefę
	mov	word [rbx + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.x],	r8w
	mov	word [rbx + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.y],	r9w
	mov	word [rbx + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.width],	r10w
	mov	word [rbx + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.height],	r11w

	; zwiększono ilość elementów na liście
	inc	qword [kernel_wm_deduplication_list_records]

.end:
	; odblokuj listę stref do modyfikacji
	mov	byte [kernel_wm_deduplication_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rbx

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_deduplication_insert_by_register"

;===============================================================================
kernel_wm_deduplication:
	; zachowaj oryginalne rejestry
	push	rax

	; przywróć oryginalne rejestry
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_deduplication"
