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

	; ; naciśnięto klawisz strzałki w lewo?
	; cmp	ax,	STATIC_SCANCODE_ARROW_LEFT
	; je	.key_arrow_left	; tak
	;
	; ; naciśnięto klawisz strzałki w prawo?
	; cmp	ax,	STATIC_SCANCODE_ARROW_RIGHT
	; je	.key_arrow_right	; tak
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

	; klawisz funkcyjny, obsłużony
	clc

.end:
	; powrót z procedury
	ret

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
