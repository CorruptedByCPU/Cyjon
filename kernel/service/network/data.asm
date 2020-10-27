;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

service_network_pid					dq	STATIC_EMPTY

service_network_rx_count				dq	STATIC_EMPTY
service_network_tx_count				dq	STATIC_EMPTY

service_network_port_semaphore				db	STATIC_FALSE
service_network_port_table				dq	STATIC_EMPTY

service_network_stack_address				dq	STATIC_EMPTY

service_network_ipc_message:
	times	KERNEL_IPC_STRUCTURE.SIZE		db	STATIC_EMPTY
