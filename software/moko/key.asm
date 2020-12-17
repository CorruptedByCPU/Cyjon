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

	; naciśnięto klawisz CTRL?
	cmp	ax,	STATIC_SCANCODE_CTRL_LEFT
 	je	.ctrl	; tak

 	; puszczono klawisz CTRL?
 	cmp	ax,	STATIC_SCANCODE_CTRL_LEFT + STATIC_SCANCODE_RELEASE_mask
 	je	.ctrl_release	; tak

	; naciśnięto klawisz INSERT?
	cmp	ax,	STATIC_SCANCODE_INSERT
	je	.insert	; tak

	; puszczono klawisz INSERT?
	cmp	ax,	STATIC_SCANCODE_INSERT + STATIC_SCANCODE_RELEASE_mask
	je	.insert_release	; tak

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

	; ; przesuń wiersze 1..N o linię w górę
	; mov	ax,	KERNEL_SERVICE_VIDEO_scroll_up
	; mov	ebx,	1	; zacznij od wiersza 2-go
	; mov	rcx,	r9	; razem z wszystkimi pozostałymi
	; int	KERNEL_SERVICE

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

	; wirtualny kursor znajduje się w przedostatniej linii dokumentu na ekranie?
	cmp	r9,	r15
	je	.key_enter_continue	; tak

	; ; przesuń pozostałe wiersze dokumentu w dół
	; mov	ax,	KERNEL_SERVICE_VIDEO_scroll_down
	; mov	rbx,	r15	; zaczynając od nowej pozycji kursora
	; mov	rcx,	r9
	; sub	rcx,	r15
	; int	KERNEL_SERVICE

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
