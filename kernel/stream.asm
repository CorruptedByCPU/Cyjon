;===============================================================================
; Copyright (C) by vLock.dev
;===============================================================================

struc	KERNEL_STREAM_STRUCTURE_ENTRY
	.start		resb	2
	.end		resb	2
	.address	resb	8
	.SIZE:
endstruc

kernel_stream_address	dq	STATIC_EMPTY

;===============================================================================
; wyjście:
;	rbx - identyfikator potoku
kernel_stream_new:
	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rbx - identyfikator potoku
;	rcx - rozmiar bufora docelowego
;	rdi - wskaźnik docelowy danych
; wyjście:
;	rcx - ilość danych przesłanych
kernel_stream_in:
	; powrót z procedury
	ret

;===============================================================================
; wejście:
;	rbx - identyfikator potoku
;	rcx - ilość danych do przesłania
;	rsi - wskaźnik źródłowy danych
kernel_stream_out:
	; powrót z procedury
	ret
