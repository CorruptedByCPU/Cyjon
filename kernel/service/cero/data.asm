;===============================================================================
; Copyright (C) by Blackend.dev
;===============================================================================

;===============================================================================
service_cero_window_workbench		dq	0	; x
					dq	0	; y
					dq	STATIC_EMPTY	; szerokość
					dq	STATIC_EMPTY	; wysokosć
					dq	STATIC_EMPTY	; adres przestrzeni danych
.extra:					dq	STATIC_EMPTY	; rozmiar w Bajtach
					dq	SERVICE_DESU_OBJECT_FLAG_fixed_xy | SERVICE_DESU_OBJECT_FLAG_fixed_z | SERVICE_DESU_OBJECT_FLAG_visible | SERVICE_DESU_OBJECT_FLAG_flush

;===============================================================================
align	STATIC_QWORD_SIZE_byte,	db	STATIC_EMPTY
service_cero_window_menu:
					dq	STATIC_EMPTY
					dq	STATIC_EMPTY
					dq	STATIC_EMPTY
					dq	STATIC_EMPTY
					dq	STATIC_EMPTY
.extra:					dq	STATIC_EMPTY
					dq	STATIC_EMPTY
