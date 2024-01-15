;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

; 16 Bitowy kod programu
[BITS 16]

stage2_unlock_a20:
	; spradź czy brama a20 jest odblokowana (nie wyważaj otwartych drzwi)
	call	.check_a20
	jc	.by_bios	; jeśli nie, spróbuj za pomocą BIOSu

	; brama a20 odblokowana

	; powrót z procedury
	ret

.by_bios:
	; odblokuj brama a20 za pomocą funkcji BIOSu
	mov	ax,	0x2401
	int	0x15	; wykonaj

	; spradź czy brama a20 jest odblokowana
	call	.check_a20
	jc	.by_keyboard	; jeśli nie, odblokuj za pomocą kontrolera klawiatury

	; brama a20 odblokowana

	; powrót z procedury
	ret

.by_keyboard:
	; wyłącz przerwania
	cli

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    .wait_for_keyboard_in

	; wyłącz klawiaturę
	mov	al,	0xAD
	out	0x64,	al	; wyślij

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    .wait_for_keyboard_in

	; poproś o możliwość odczytania danych z portu klawiatury
	mov     al,	0xD0
	out     0x64,	al	; wyślij

	; poczekaj, aż klawiatura będzie gotowa dać odpowiedź
	call    .wait_for_keyboard_out

	; pobierz z portu klawiatury informacje
	in      al,	0x60

	; zapamiętaj wiadomość
	push    ax

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    .wait_for_keyboard_in

	; poproś o możliwość zapisania danych do portu klawiatury
	mov     al,	0xD1
	out     0x64,	al	; wyślij

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    .wait_for_keyboard_in

	; przywróć poprzednią wiadomość
	pop     ax

	; ustaw drugi bit rejestru AL
	or      al,	2
	out     0x60,	al	; wyślij do konrolera klawiatury

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call	.wait_for_keyboard_in

	; włącz klawiaturę
	mov     al,	0xAE
	out     0x64,	al	; wyślij

	; poczekaj, aż klawiatura będzie gotowa przyjąć polecenie
	call    .wait_for_keyboard_in

	; włącz przerwania
	sti

	; spradź czy brama a20 jest odblokowana
	call	.check_a20
	jc	.by_fastgate	; jeśli nie, spróbuj za pomocą FatGate

	; brama a20 odblokowana

	; powrót z procedury
	ret

.by_fastgate:
	; pobierz status z rejestru System Control Port A
	in	al,	0x92
	test	al,	2	; sprawdź czy drugi bit jest równy zero
	jnz	.end_fastgate	; jeśli nie, koniec

	; włącz 2 bit
	or	al,	2
	and	al,	0xFE
	out	0x92,	al	; wyślij

.end_fastgate:
	; spradź czy brama a20 jest odblokowana
	call	.check_a20
	jc	.error	; no i pies pogrzebany

	; brama a20 odblokowana

	; powrót z procedury
	ret

.error:
	; wyświetl informacje o zablokowanej linii A20
	mov	si,	text_no_a20
	call	stage2_print_16bit

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

.check_a20:
	; zapamiętaj adres segmentu danych
	push	ds

	; ustaw semgent danych na koniec pamięci
	mov	ax,	0xFFFF
	mov	ds,	ax

	; zapisz wartość 0xFF pod adres fizyczny 0xFFFF0 + 0x0510 = 0x100500
	mov	byte [ds:0x0510],	0xFF

	; przywróć adres segmentu danych
	pop	ds

	; sprawdź czy wartość spod adresu fizycznego 0x0000:0x0500 jest równa z poprzednio zapisaną
	mov	al,	byte [ds:0x0500]
	cmp	byte [ds:0x0500],	0xFF
	jne	.end_check_a20	; jeśli różne, linia a20 odblokowana

	; brama a20 zablokowana
	sti	; włącz flagę CF (CarryFlag)

	; powrót z procedury
	ret

.end_check_a20:
	; wyłącz flagę CF (CarryFlag)
	clc

	; powrót z procedury
	ret

.wait_for_keyboard_in:
	; pobierz status bufora klawiatury do al
	in	al,	0x64
	test	al,	2	; sprawdź czy drugi bit jest równy zero

	; jeśli nie, powtórz operacje
	jnz	.wait_for_keyboard_in

	ret

.wait_for_keyboard_out:
	; pobierz status bufora klawiatury do al
	in	al,	0x64
	test	al,	1	; sprawdź czy pierwszy bit jest równy zero

	; jeśli nie, powtórz operacje
	jz	.wait_for_keyboard_out

	ret

text_no_a20	db	'Unable to open gate A20!', VARIABLE_ASCII_CODE_TERMINATOR
