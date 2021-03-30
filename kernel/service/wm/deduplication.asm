;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

;===============================================================================
kernel_wm_deduplication:
	; zachowaj oryginalne rejestry
	push	rax
	push	rcx
	push	rsi
	push	rdi
	push	r8
	push	r9
	push	r10
	push	r11
	push	r12
	push	r13
	push	r14
	push	r15

	; brak stref do deduplikacji na liście?
	cmp	qword [kernel_wm_deduplication_list_records],	STATIC_EMPTY
	je	.end	; tak

	; ustaw wskaźniki początku przestrzeni listy stref do deduplikacji
	mov	rsi,	qword [kernel_wm_deduplication_list_address]

	; rozpocznij przetwarzanie
	jmp	.entry

.remove:
	; usuń strefę z listy deduplikacji
	call	kernel_wm_deduplication_remove

.entry:
	; zdeduplikowano wszystkie strefy?
	cmp	qword [rsi],	STATIC_EMPTY
	je	.ready	; tak

	; właściwości strefy źródłowej
	mov	r8w,	word [rsi + KERNEL_WM_STRUCTURE_FIELD.x]	; lewa krawędź na osi X
	mov	r9w,	word [rsi + KERNEL_WM_STRUCTURE_FIELD.y]	; górna krawędź na osi Y
	mov	r10w,	word [rsi + KERNEL_WM_STRUCTURE_FIELD.width]	; prawa krawędź na osi X
	add	r10w,	r8w
	mov	r11w,	word [rsi + KERNEL_WM_STRUCTURE_FIELD.height]	; dolna krawędź na osi Y
	add	r11w,	r9w

	; opisana strefa znajduje się poza przestrzenią "ekranu"?

	cmp	r8w,	word [kernel_video_width_pixel]	; poza prawą krawędzią ekranu?
	jge	.remove	; tak
	cmp	r9w,	word [kernel_video_height_pixel]	; poza dolną krawędzią ekranu?
	jge	.remove	; tak
	cmp	r10w,	STATIC_EMPTY	; poza lewą krawędzią ekranu?
	jle	.remove	; tak
	cmp	r11w,	STATIC_EMPTY	; poza górną krawędzią ekranu?
	jle	.remove	; tak

	; wskaźnik pośredni na koniec listy obiektów
	mov	rdi,	qword [kernel_wm_deduplication_list_records]
	shl	rdi,	KERNEL_WM_OBJECT_LIST_ENTRY_SIZE_shift	; pozycja za ostatnim elementem listy deduplikacji
	add	rdi,	qword [kernel_wm_deduplication_list_address]	; początek przestrzeni listy deduplikacji

.zone:
	; ustaw wskaźnik na rozpatrywaną strefę
	sub	rdi,	KERNEL_WM_STRUCTURE_FIELD.SIZE

	; wystąpiła interferencja z przetwarzaną strefą? (samą sobą)
	cmp	rdi,	rsi
	jne	.next	; nie

	; sprawdź następną strefę źródłową
	add	rsi,	KERNEL_WM_STRUCTURE_FIELD.SIZE

	; kontynuuj
	jmp	.entry

.next:
	; właściwości strefy porównywanej
	mov	r12w,	word [rdi + KERNEL_WM_STRUCTURE_FIELD.x]	; lewa krawędź na oxi X
	mov	r13w,	word [rdi + KERNEL_WM_STRUCTURE_FIELD.y]	; górna krawędź na osi Y
	mov	r14w,	word [rdi + KERNEL_WM_STRUCTURE_FIELD.width]	; prawa krawędź na osi X
	add	r14w,	r12w
	mov	r15w,	word [rdi + KERNEL_WM_STRUCTURE_FIELD.height]	; dolna krawędź na osi Y
	add	r15w,	r13w

	;--------------------------------
	;      r9	       r13	X
	;    -------	     -------
	; r8 | S1  | r10 r12 | S2  | r14
	;    -------	     -------
	;      r11	       r15
	; Y

	; strefa znajduje się poza przetwarzaną strefą?
	cmp	r12w,	r10w	; lewa krawędź strefy za prawą krawędzią strefy?
	jge	.zone	; tak
	cmp	r13w,	r11w	; górna krawędź strefy za dolną krawędzią strefy?
	jge	.zone	; tak
	cmp	r14w,	r8w	; prawa krawędź strefy przed lewą krawędzią strefy?
	jle	.zone	; tak
	cmp	r15w,	r9w	; dolna krawędź strefy przed górną krawędzią strefy?
	jle	.zone	; tak

	;-----------------------------------------------------------------------
	; przycinanie
	;-----------------------------------------------------------------------

.left:
	; lewa krawędź strefy źródłowej przed lewą krawędzią strefy porównywanej?
	cmp	r8w,	r12w
	jge	.up	; nie

	; wytnij wystający fragment strefy źródłowej

	; zachowaj oryginalną pozycję prawej krawędzi strefy
	push	r10

	; szerokość odcinanej strefy
	mov	r10w,	r12w
	sub	r10w,	r8w

	; wysokość odcinanej strefy
	sub	r11w,	r9w

	; odłóż na listę stref do deduplikacji
	call	kernel_wm_deduplication_insert_by_register

	; przywróć oryginalną pozycję prawej krawędzi strefy
	pop	r10

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r11w,	r9w

	; nowa pozycja lewej krawędzi strefy
	mov	r8w,	r12w

.up:
	; górna krawędź strefy źródłowej przed górną krawędzią strefy powrównywanej?
	cmp	r9w,	r13w
	jge	.right	; nie

	; wytnij wystający fragment strefy

	; szerokość odcinanej strefy
	sub	r10w,	r8w

	; zachowaj oryginalną pozycję dolnej krawędzi strefy
	push	r11

	; wysokość odcinanej strefy
	mov	r11w,	r13w
	sub	r11w,	r9w

	; odłóż na listę stref do deduplikacji
	call	kernel_wm_deduplication_insert_by_register

	; przywróć oryginalną pozycję prawej krawędzi strefy
	pop	r11

	; przywróć oryginalną pozycję dolnej krawędzi strefy
	add	r10w,	r8w

	; nowa pozycja górnej krawędzi strefy
	mov	r9w,	r13w

.right:
	; prawa krawędź strefy źródłowej za prawą krawędzią strefy powrównywanej?
	cmp	r10w,	r14w
	jle	.down	; nie

	; wytnij wystający fragment strefy

	; szerokość odcinanej strefy
	push	r10
	sub	r10w,	r14w

	; wysokość odcinanej strefy
	sub	r11w,	r9w

	; zachowaj oryginalną pozycję lewej krawędzi strefy
	push	r8

	; pozycja lewej krawędzi odcinanej strefy
	mov	r8w,	r14w

	; odłóż na listę stref do deduplikacji
	call	kernel_wm_deduplication_insert_by_register

	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r8

	; nowa pozycja prawej krawędzi strefy
	sub	word [rsp],	r10w
	pop	r10
	; mov	r10,	r14

	; przywróć pozycję dolnej krawędzi
	add	r11w,	r9w

.down:
	; dolna krawędź strefy źródłowej za dolną krawędzią strefy powrównywanej?
	cmp	r11w,	r15w
	jle	.remove	; nie

	; wytnij wystający fragment strefy

	; wysokość odcinanej strefy
	sub	r11w,	r15w

	; zachowaj oryginalną pozycję górnej krawędzi strefy
	push	r9

	; pozycja górnej krawędzi odcinanej strefy
	mov	r9w,	r15w

	; odłóż na listę stref do deduplikacji
	call	kernel_wm_deduplication_insert_by_register

	; przywróć oryginalną pozycję lewej krawędzi strefy
	pop	r9

	; nowa pozycja dolnej krawędzi strefy
	sub	word [rsp],	r11w
	mov	r11w,	r15w

	; porzuć duplikującą się strefę
	jmp	.remove

.ready:
	; zdeduplikowano strefy

	; dla wszystkich obiektów podstawowym wypełnieniem jest pierwszy obiekt na liście
	mov	rax,	qword [kernel_wm_object_list_address]
	mov	rax,	qword [rax + KERNEL_WM_STRUCTURE_OBJECT_LIST_ENTRY.object_address]

	; ustaw wskaźnik na początek przestrzeni listy stref zdeduplikowanych
	mov	rsi,	qword [kernel_wm_deduplication_list_address]

.forward:
	; pobierz informacje o fragmencie
	mov	r8w,	word [rsi + KERNEL_WM_STRUCTURE_FIELD.x]
	mov	r9w,	word [rsi + KERNEL_WM_STRUCTURE_FIELD.y]
	mov	r10w,	word [rsi + KERNEL_WM_STRUCTURE_FIELD.width]
	mov	r11w,	word [rsi + KERNEL_WM_STRUCTURE_FIELD.height]

	; zarejestruj na liście fragmentów
	call	kernel_wm_zone_insert_by_register

	; zarejestruj na liście scaleń
	call	kernel_wm_merge_insert_by_register

	; usuń element z listy
	call	kernel_wm_deduplication_remove

	; koniec listy elementów do przetransferowania?
	cmp	qword [rsi],	STATIC_EMPTY
	jne	.forward	; nie

.end:
	; przywróć oryginalne rejestry
	pop	r15
	pop	r14
	pop	r13
	pop	r12
	pop	r11
	pop	r10
	pop	r9
	pop	r8
	pop	rdi
	pop	rsi
	pop	rcx
	pop	rax

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_deduplication"

;===============================================================================
; wejście:
;	rsi - wskaźnik do strefy
kernel_wm_deduplication_remove:
	; zachowaj oryginalne rejestry
	push	rsi

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	kernel_wm_deduplication_semaphore,	0

.move:
	; przesuń następny element listy na aktualną pozycję
	push	qword [rsi + KERNEL_WM_STRUCTURE_FIELD.SIZE]
	pop	qword [rsi]

	; przesuń wskaźnik na następny element
	add	rsi,	KERNEL_WM_STRUCTURE_FIELD.SIZE

	; koniec elementów na liście?
	cmp	qword [rsi],	STATIC_EMPTY
	jne	.move	; nie

	; zmniejszono ilość elementów na liście
	dec	qword [kernel_wm_deduplication_list_records]

.end:
	; odblokuj listę stref do modyfikacji
	mov	byte [kernel_wm_deduplication_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rsi

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_deduplication_remove"

;===============================================================================
; wejście:
;	rax - wskaźnik do obiektu
kernel_wm_deduplication_insert_by_object:
	; zachowaj oryginalne rejestry
	push	rdi

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	kernel_wm_deduplication_semaphore,	0

	; brak miejsca?
	cmp	qword [kernel_wm_deduplication_list_records],	KERNEL_WM_FRAGMENT_LIST_limit
	je	.end	; tak

	; ustaw wskaźnik na koniec listy
	mov	rdi,	qword [kernel_wm_deduplication_list_records]
	shl	rdi,	STATIC_MULTIPLE_BY_8_shift
	add	rdi,	qword [kernel_wm_deduplication_list_address]

	; dodaj do listy nową strefę
	push	qword [rax]
	pop	qword [rdi]

	; zwiększono ilość elementów na liście
	inc	qword [kernel_wm_deduplication_list_records]

.end:
	; odblokuj listę stref do modyfikacji
	mov	byte [kernel_wm_deduplication_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi

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
	push	rdi

	; zablokuj dostęp do modyfikacji listy stref
	macro_lock	kernel_wm_deduplication_semaphore,	0

	; brak miejsca?
	cmp	qword [kernel_wm_deduplication_list_records],	KERNEL_WM_FRAGMENT_LIST_limit
	je	.end	; tak

	; ustaw wskaźnik na koniec listy
	mov	rdi,	qword [kernel_wm_deduplication_list_records]
	shl	rdi,	STATIC_MULTIPLE_BY_8_shift
	add	rdi,	qword [kernel_wm_deduplication_list_address]

	; dodaj do listy nową strefę
	mov	word [rdi + KERNEL_WM_STRUCTURE_FIELD.x],	r8w
	mov	word [rdi + KERNEL_WM_STRUCTURE_FIELD.y],	r9w
	mov	word [rdi + KERNEL_WM_STRUCTURE_FIELD.width],	r10w
	mov	word [rdi + KERNEL_WM_STRUCTURE_FIELD.height],	r11w

	; zwiększono ilość elementów na liście
	inc	qword [kernel_wm_deduplication_list_records]

.end:
	; odblokuj listę stref do modyfikacji
	mov	byte [kernel_wm_deduplication_semaphore],	STATIC_FALSE

	; przywróć oryginalne rejestry
	pop	rdi

	; powrót z procedury
	ret

	macro_debug	"kernel_wm_deduplication_insert_by_register"
