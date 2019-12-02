;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

service_http:
	; zarejestruj port 80
	mov	cx,	80
	call	kernel_network_tcp_port_assign

	; zatrzymaj dalsze wykonywanie kodu
	jmp	$
