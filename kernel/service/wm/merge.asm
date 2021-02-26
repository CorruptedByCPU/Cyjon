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

;===============================================================================
kernel_wm_merge:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	r8
	push	r9
	push	r10
	push	r11

	; maksymalna ilość miejsc na liście
	mov	ecx,	KERNEL_WM_FRAGMENT_LIST_limit

	; ustaw wskaźnik na listę wypełnień
	mov	rsi,	qword [kernel_wm_merge_list_address]

.loop:
	; pusta pozycja?
	cmp	qword [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	STATIC_EMPTY
	je	.next 	; tak

	; wstaw fragment do wypełniania
	mov	rax,	qword [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.object]
	mov	r8w,	word [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.x]
	mov	r9w,	word [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.y]
	mov	r10w,	word [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.width]
	mov	r11w,	word [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.field + KERNEL_WM_STRUCTURE_FIELD.height]
	call	kernel_wm_fill_insert_by_register

	; usuń wpis
	mov	qword [rsi + KERNEL_WM_STRUCTURE_FRAGMENT.object],	STATIC_EMPTY

	; zmniejszono ilość elementów na liście
	dec	qword [kernel_wm_merge_list_records]

.next:
	; przesuń wskaźnik na następne wypełnienie
	add	rsi,	KERNEL_WM_STRUCTURE_FRAGMENT.SIZE

	; następny wpis na liście?
	dec	cx
	jnz	.loop	; tak

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_merge"
