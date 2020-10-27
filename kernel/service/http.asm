;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

%define	SERVICE_HTTP_version	"0"
%define	SERVICE_HTTP_revision	"8"

%macro	service_http_macro_foot	0
	db	"<hr />", STATIC_ASCII_NEW_LINE
	db	"Cyjon v", KERNEL_version, ".", KERNEL_revision, " (HTTP Service v", SERVICE_HTTP_version, ".", SERVICE_HTTP_revision, ")"
	db	"<style>* { font: 12px/150% 'Courier New', 'DejaVu Sans Mono', Monospace, Verdana; color: #F5F5F5; } body { background-color: #282922; }</style>", STATIC_ASCII_NEW_LINE
%endmacro

service_http_ipc_message:
	times	KERNEL_IPC_STRUCTURE.SIZE	db	STATIC_EMPTY

service_http:
	; zarejestruj port 80
	mov	cx,	80
	call	service_network_tcp_port_assign
	jc	service_http	; spróbuj raz jeszcze

.loop:
	; odbierz komunikat dla nas
	mov	rdi,	service_http_ipc_message
	call	kernel_ipc_receive
	jc	.loop	; brak, sprawdź raz jeszcze

	; pobierz identyfikator połączenia
	mov	rbx,	qword [rdi + KERNEL_IPC_STRUCTURE.other]

	; zapytanie o rdzeń usługi?
	mov	ecx,	service_http_get_root_end - service_http_get_root
	mov	rsi,	qword [rdi + KERNEL_IPC_STRUCTURE.pointer]
	mov	rdi,	service_http_get_root
	call	library_string_compare
	jc	.no	; nie

	; ustaw odpowiedź
	mov	ecx,	service_http_200_default_end - service_http_200_default
	mov	rsi,	service_http_200_default

	; wyślij
	jmp	.answer

.no:
	; odpowiedź nie istnieje
	mov	ecx,	service_http_404_end - service_http_404
	mov	rsi,	service_http_404

.answer:
	; wyślij odpowiedź
	call	service_network_tcp_port_send

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

service_http_get_root		db	"GET / "
service_http_get_root_end:

service_http_200_default	db	"HTTP/1.0 200 OK", STATIC_ASCII_NEW_LINE
				db	"Content-Type: text/html", STATIC_ASCII_NEW_LINE
				db	STATIC_ASCII_NEW_LINE
				db	'<span style="color: #F62670;">Hello,</span> <span style="color: #A9DE40;">World!</span>', STATIC_ASCII_NEW_LINE
				service_http_macro_foot
service_http_200_default_end:

service_http_404		db	"HTTP/1.0 404 Not Found", STATIC_ASCII_NEW_LINE
				db	"Content-Type: text/html", STATIC_ASCII_NEW_LINE
				db	STATIC_ASCII_NEW_LINE
				db	"404 Content not found.", STATIC_ASCII_NEW_LINE
				service_http_macro_foot
service_http_404_end:
