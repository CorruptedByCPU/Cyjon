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
	; naciśnięto klawisz Enter?
	cmp	ax,	STATIC_SCANCODE_RETURN
	je	.key_enter	; tak

	; naciśnięto klawisz HOME?
	cmp	ax,	STATIC_SCANCODE_HOME
	je	.key_home	; tak

	; naciśnięto klawisz END?
	cmp	ax,	STATIC_SCANCODE_END
	je	.key_end	; tak

	; naciśnięto klawisz strzałki w lewo?
	cmp	ax,	STATIC_SCANCODE_LEFT
	je	.key_arrow_left	; tak

	; naciśnięto klawisz strzałki w prawo?
	cmp	ax,	STATIC_SCANCODE_RIGHT
	je	.key_arrow_right	; tak
	;
	; ; naciśnięto klawisz strzałki w górę?
	; cmp	ax,	STATIC_SCANCODE_ARROW_UP
	; je	.key_arrow_up	; tak
	;
	; ; naciśnięto klawisz strzałki w dół?
	; cmp	ax,	STATIC_SCANCODE_ARROW_DOWN
	; je	.key_arrow_down	; tak
	;
	; ; naciśnięto klawisz PageUp?
	; cmp	ax,	STATIC_SCANCODE_PAGE_UP
	; je	.key_page_up	; tak
	;
	; ; naciśnięto klawisz PageDown?
	; cmp	ax,	STATIC_SCANCODE_PAGE_DOWN
	; je	.key_page_down	; tak
	;
	; ; naciśnięto klawisz Backspace?
	; cmp	ax,	STATIC_SCANCODE_BACKSPACE
	; je	.key_backspace	; tak
	;
	; ; naciśnięto klawisz Delete?
	; cmp	ax,	STATIC_SCANCODE_DELETE
	; je	.key_delete	; tak

	; naciśnięto klawisz INSERT?
	cmp	ax,	STATIC_SCANCODE_INSERT
	je	.insert	; tak

	; naciśnięto klawisz CTRL?
	cmp	ax,	STATIC_SCANCODE_CTRL_LEFT
 	je	.ctrl	; tak

 	; puszczono klawisz CTRL?
 	cmp	ax,	STATIC_SCANCODE_CTRL_LEFT + STATIC_SCANCODE_RELEASE_mask
 	je	.ctrl_release	; tak

.no_key:
	; brak obsługi klawisza
	stc

	; koniec procedury
	ret

.changed:
	; zachowaj ostatni znany wskaźnik pozycji wew. linii
	mov	qword [moko_document_line_index_last],	r11

	; zachowaj ostatnio znany początek wyświetlonej linii
	mov	qword [moko_document_line_begin_last],	r12

	; wyświemtl ponownie zawartość linii
	call	moko_line

.done:
	; klawisz funkcyjny, obsłużony
	clc

.end:
	; powrót z procedury
	ret

;-------------------------------------------------------------------------------
.key_arrow_left:
	; wskaźnik pozycji kursora wew. dokumentu znajduje się na początku ów dokumentu?
	cmp	r10,	qword [moko_document_start_address]
	je	.done	; tak, zignoruj

	; kursor znajduje się w pierwszej kolumnie?
	test	r14,	r14
	jnz	.key_arrow_left_other_column	; nie

	; linia wyświetlona od początku?
	test	r12,	r12
	jnz	.key_arrow_left_start_of_line	; nie

	; kursor znajduje się w pierwszym wierszu?
	test	r15,	r15
	jnz	.key_arrow_left_other_row	; nie

	; przesuń wszystkie wiersze dokumentu w dół
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_down_end - moko_string_scroll_down
	mov	rsi,	moko_string_scroll_down
	mov	word [moko_string_scroll_down.y],	STATIC_EMPTY	; zacznij od wiersza 1-go
	mov	word [moko_string_scroll_down.c],	r9w	; razem z wszystkimi pozostałymi
	sub	word [moko_string_scroll_down.c],	MOKO_MENU_HEIGHT_char	; oprócz przestrzeni menu
	dec	word [moko_string_scroll_down.c]	; bez ostatniej linii dokumntu
	int	KERNEL_SERVICE

	; wyświetl dokument od poprzedniej linii
	dec	qword [moko_document_show_from_line]

	; kontynuuj, jakbyś przechodził wiersz wyżej na ekranie
	jmp	.key_arrow_left_other_row_omit_cursor

.key_arrow_left_other_row:
	; przesuń kursor o wiersz w górę
	dec	r15

.key_arrow_left_other_row_omit_cursor:
	; pobierz informacje o poprzedniej linii
	call	moko_line_previous

	; aktualizuj właściwości aktualnej linii i kursora

	; wskaźnik pozycji kursora w przestrzeni dokumentu
	dec	r10

	; przesunięcie wew. linii
	mov	r11,	rcx

	; wyświetl linię od pierwszego znaku
	xor	r12,	r12

	; rozmiar linii w znakach
	mov	r13,	rcx

	; kursor ustaw za ostatnim znakiem w linii
	mov	r14,	rcx

	; rozmiar linii jest większy od szerokości przestrzeni dokumentu na ekranie?
	cmp	rcx,	r8
	jbe	.changed	; nie

	; wyświetl ostatnie N znaków linii
	mov	r12,	rcx
	sub	r12,	r8

	; kursor ustaw w ostatniej kolumnie
	mov	r14,	r8

	; obsłużono klawisz
	jmp	.changed

.key_arrow_left_other_column:
	; wskaźnik pozycji kursora w przestrzeni dokumentu o pozycję w lewo
	dec	r10

	; przesunięcie wew. linii o pozycje w lewo
	dec	r11

	; cofnij pozycje kursora w lewo
	dec	r14

	; obsłużono klawisz
	jmp	.changed

.key_arrow_left_start_of_line:
	; wskaźnik pozycji kursora w przestrzeni dokumentu o pozycję w lewo
	dec	r10

	; przesunięcie wew. linii o pozycje w lewo
	dec	r11

	; wyświetl linię od poprzedniego znaku
	dec	r12

	; obsłużono klawisz
	jmp	.changed

;-------------------------------------------------------------------------------
.key_arrow_right:
	; wskaźnik pozycji kursora wew. dokumentu znajduje się na końcu ów dokumentu?
	cmp	r10,	qword [moko_document_end_address]
	je	.done	; tak, zignoruj

	; przesunięcie wew. linii znaduje się na końcu linii?
	cmp	r11,	r13
	je	.key_arrow_right_last_char	; tak

	; wzkaśnik pozycji kursora w przestrzeni dokumentu przesuń na następny znak
	inc	r10

	; przesunięcie wew. linii o pozycje w prawo
	inc	r11

	; kursor znajduje się w ostatniej kolumnie?
	cmp	r14,	r8
	je	.key_arrow_right_last_column	; tak

	; przesuń kursor do następnej kolumny
	inc	r14

	; obsłużono klawisz
	jmp	.changed

.key_arrow_right_last_column:
	; wyświetl linię od następnego znaku
	inc	r12

	; obsłużono klawisz
	jmp	.changed

.key_arrow_right_last_char:
	; cała aktualna linia jest widoczna?
	test	r12,	r12
	jz	.key_arrow_right_line_visible	; tak

	; wyświetl linię od pocżątku
	xor	r12,	r12
	call	moko_line

.key_arrow_right_line_visible:
	; kursor znajduje się w ostatnim wierszu?
	cmp	r15,	r9
	jb	.key_arrow_right_not_last_row	; nie

	; przesuń wiersze 1..N o linię w górę
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_up_end - moko_string_scroll_up
	mov	rsi,	moko_string_scroll_up
	mov	word [moko_string_scroll_up.y],	1	; zacznij od wiersza 1-go
	mov	word [moko_string_scroll_up.c],	r9w	; razem z wszystkimi pozostałymi
	sub	word [moko_string_scroll_up.c],	MOKO_MENU_HEIGHT_char	; oprócz przestrzeni menu
	int	KERNEL_SERVICE

	; wyświetl dokument od następnej linii
	inc	qword [moko_document_show_from_line]

	; pozostaw kursor w aktualnym wierszu
	jmp	.key_arrow_right_last_row

.key_arrow_right_not_last_row:
	; przesuń kursor do następnego wiersza
	inc	r15

.key_arrow_right_last_row:
	; pobierz właściwości następnej linii dokumentu
	call	moko_line_next

	; wskaźnik pozycji kursora w przestrzeni dokumentu
	mov	r10,	rsi

	; przesunięcie wew. linii
	xor	r11,	r11

	; wyświetl zawartość linii od pierwszego znaku
	xor	r12,	r12

	; rozmiar nowej linii
	mov	r13,	rcx

	; kursor ustaw w pierwszej kolumnie
	xor	r14,	r14

	; obsłużono klawisz
	jmp	.changed

;-------------------------------------------------------------------------------
.key_home:
	; ustaw wskaźnik pozycji kursora w przestrzeni dokumentu na początek aktualnej linii
	sub	r10,	r11

	; ustaw przesunięcie wew. linii na początek linii
	xor	r11,	r11

	; wyświetl linię od początku
	xor	r12,	r12

	; ustaw kursor na osi X w pierwszej kolumnie
	xor	r14,	r14

	; obsłużono klawisz
	jmp	.changed

;-------------------------------------------------------------------------------
.key_end:
	; ustaw wskaźnik pozycji kursora w przestrzeni dokumentu na koniec aktualnej linii
	sub	r10,	r11	; cofnij o przesunięcie wew. linii
	add	r10,	r13	; przesuń do przodu o rozmiar linii w znakach

	; ustaw przesunięcie wew. linii o rozmiar linii w znakach
	mov	r11,	r13

	; ustaw kursor w kolumnie odpowiadającej końcu linii
	mov	r14,	r13

	; wyświetlony koniec linii znajdzie się poza ekranem?
	cmp	r14,	r8
	jbe	.changed	; nie

	; rozpocznij wyświetlanie linii od ostatnich r8 znaków
	mov	r12,	r13	; od rozmiaru linii
	sub	r12,	r8	; odejmij szerokość ekranu w znakach
	inc	r12

	; kursor ustaw na ostatniej kolumnie aktualnej linii
	mov	r14,	r8
	dec	r14

	; obsłużono klawisz
	jmp	.changed

;-------------------------------------------------------------------------------
.key_enter:
	; wstaw znak nowej linii do dokumentu w aktualnej pozycji wskaźnika
	mov	ax,	STATIC_SCANCODE_NEW_LINE
	mov	bl,	STATIC_FALSE	; nie modyfikuj właściwości aktualnej linii
	call	moko_document_insert

	; ilość linii w dokumencie zwiększa się
	inc	qword [moko_document_line_count]

	; zachowaj informacje o pozostałym rozmiarze linii, jeśli została ucięta
	mov	rdx,	r13
	sub	rdx,	r11

	; wyświetl ponownie aktualną linię od pierwszego znaku
	xor	r12,	r12	; od pierwszego znaku
	sub	r13,	rdx	; do pierwszego znaku nowej linii
	call	moko_line

	; czy kursor znajduje się w ostatnim wierszu przestrzeni ekranu?
	cmp	r15,	r9
	jb	.key_enter_not_last	; nie

	; przesuń wiersze 1..N o linię w górę
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_up_end - moko_string_scroll_up
	mov	rsi,	moko_string_scroll_up
	mov	word [moko_string_scroll_up.y],	1	; zacznij od wiersza 2-go
	mov	word [moko_string_scroll_up.c],	r9w	; razem z wszystkimi pozostałymi
	int	KERNEL_SERVICE

	; wyświetl dokument od następnej linii
	inc	qword [moko_document_show_from_line]

	; kontynuuj
	jmp	.key_enter_continue

.key_enter_not_last:
	; ustaw kursor w nowym wierszu
	inc	r15

	; przesuń wirtualny kursor do następnej linii
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_cursor_to_row_next_end - moko_string_cursor_to_row_next
	mov	rsi,	moko_string_cursor_to_row_next
	int	KERNEL_SERVICE

	; wirtualny kursor znajduje się w ostatniej linii dokumentu na ekranie?
	cmp	r9,	r15
	je	.key_enter_continue	; tak

	; przesuń pozostałe wiersze dokumentu w dół
	mov	ax,	KERNEL_SERVICE_PROCESS_stream_out
	mov	ecx,	moko_string_scroll_down_end - moko_string_scroll_down
	mov	rsi,	moko_string_scroll_down
	mov	word [moko_string_scroll_down.y],	r15w	; zacznij od wiersza 2-go
	mov	word [moko_string_scroll_down.c],	r9w	; razem z wszystkimi pozostałymi
	sub	word [moko_string_scroll_down.c],	r15w
	int	KERNEL_SERVICE

.key_enter_continue:
	; aktualizuj informacje o nowej linii dokumentu

	; przesuń wskaźnik wew. dokumentu za wstawiony znak nowej linii
	inc	r10

	; przesunięcie wew. linii ustaw na początek
	xor	r11,	r11

	; wyświetl nową linię od początku
	xor	r12,	r12

	; nowy rozmiar linii
	mov	r13,	rdx

	; ustaw kursor na początek wiersza
	xor	r14,	r14

	; obsłużono klawisz Enter
	jmp	.changed


;-------------------------------------------------------------------------------
.ctrl:
	; podnieś flagę
	mov	byte [moko_key_ctrl_semaphore],	STATIC_TRUE
	jmp	.end	; obsłużono klawisz

;-------------------------------------------------------------------------------
.ctrl_release:
	; opuść flagę
	mov	byte [moko_key_ctrl_semaphore],	STATIC_FALSE
	jmp	.end	; obsłużono klawisz

;-------------------------------------------------------------------------------
.insert:
	; podnieś flagę
	mov	byte [moko_key_insert_semaphore],	STATIC_TRUE
	jmp	.end	; obsłużono klawisz

;-------------------------------------------------------------------------------
.insert_release:
	; opuść flagę
	mov	byte [moko_key_insert_semaphore],	STATIC_FALSE
	jmp	.end	; obsłużono klawisz
