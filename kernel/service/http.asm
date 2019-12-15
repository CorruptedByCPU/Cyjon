;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

%define	SERVICE_HTTP_version	"0"
%define	SERVICE_HTTP_revision	"8"

%MACRO	service_http_macro_foot	0
	db	"<hr />", STATIC_ASCII_NEW_LINE
	db	"Cyjon v", KERNEL_version, ".", KERNEL_revision, " (HTTP Service v", SERVICE_HTTP_version, ".", SERVICE_HTTP_revision, ")"
%ENDMACRO

service_http:
	; zarejestruj port 80
	mov	cx,	80
	call	kernel_network_tcp_port_assign

.loop:
	; otrzymaliśmy zapytanie?
	call	kernel_network_tcp_port_receive
	jc	.loop	; nie, sprawdź raz jeszcze

	xchg	bx,bx

	; zapytanie o rdzeń usługi?
	mov	ecx,	service_http_get_root_end - service_http_get_root
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
	call	kernel_network_tcp_port_send

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$

service_http_get_root		db	"GET / "
service_http_get_root_end:

service_http_200_default	db	"HTTP/1.0 200 OK", STATIC_ASCII_NEW_LINE
				db	"Content-Type: text/html", STATIC_ASCII_NEW_LINE
				db	STATIC_ASCII_NEW_LINE
				db	"<style>* { font: 12px/150% 'Courier New', 'DejaVu Sans Mono', Monospace, Verdana; }</style>", STATIC_ASCII_NEW_LINE
				db	"Hello, World!", STATIC_ASCII_NEW_LINE
				service_http_macro_foot
service_http_200_default_end:

service_http_404		db	"HTTP/1.0 404 Not Found", STATIC_ASCII_NEW_LINE
				db	"Content-Type: text/html", STATIC_ASCII_NEW_LINE
				db	STATIC_ASCII_NEW_LINE
				db	"404 Content not found.", STATIC_ASCII_NEW_LINE
				service_http_macro_foot
service_http_404_end:
