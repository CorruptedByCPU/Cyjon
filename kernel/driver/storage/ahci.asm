;===============================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
; GPL-3.0 License
;
; Main developer:
;	Andrzej Adamczyk
;===============================================================================

DRIVER_AHCI_PCI					equ	0x0106

DRIVER_AHCI_HBA_MEMORY_REGISTER_CAP		equ	0x00	; Host Capabilities
DRIVER_AHCI_HBA_MEMORY_REGISTER_GHC		equ	0x04	; Global Host Control
DRIVER_AHCI_HBA_MEMORY_REGISTER_IS		equ	0x08	; Interrupt Status
DRIVER_AHCI_HBA_MEMORY_REGISTER_PI		equ	0x0C	; Ports Implemented
DRIVER_AHCI_HBA_MEMORY_REGISTER_VS		equ	0x10	; Version
DRIVER_AHCI_HBA_MEMORY_REGISTER_CCC_CTL		equ	0x14	; Command Completion Coalescing Control
DRIVER_AHCI_HBA_MEMORY_REGISTER_CCC_PORTS	equ	0x18	; Command Completion Coalescing Ports
DRIVER_AHCI_HBA_MEMORY_REGISTER_EM_LOC		equ	0x1C	; Enclosure Management Location
DRIVER_AHCI_HBA_MEMORY_REGISTER_EM_CTL		equ	0x20	; Enclosure Management Control
DRIVER_AHCI_HBA_MEMORY_REGISTER_CAP2		equ	0x24	; Host Capabilities Extended
DRIVER_AHCI_HBA_MEMORY_REGISTER_BOHC		equ	0x28	; BIOS/OS Handoff Control and Status

DRIVER_AHCI_PORT_REGISTER_BASE_ADDRESS		equ	0x0100
DRIVER_AHCI_PORT_REGISTER_CLBA			equ	0x0000	; Command List Base Address
DRIVER_AHCI_PORT_REGISTER_FB			equ	0x0008	; FIS Base Address
DRIVER_AHCI_PORT_REGISTER_IS			equ	0x0010	; Interrupt Status
DRIVER_AHCI_PORT_REGISTER_IE			equ	0x0014	; Interrupt Enable
DRIVER_AHCI_PORT_REGISTER_CMD			equ	0x0018	; Command and Status
DRIVER_AHCI_PORT_REGISTER_TFD			equ	0x0020	; Task File Data
DRIVER_AHCI_PORT_REGISTER_SIG			equ	0x0024	; Signature
DRIVER_AHCI_PORT_REGISTER_SSTS			equ	0x0028	; Serial ATA Status
DRIVER_AHCI_PORT_REGISTER_SCTL			equ	0x002C	; Serial ATA Control
DRIVER_AHCI_PORT_REGISTER_SERR			equ	0x0030	; Serial ATA Error
DRIVER_AHCI_PORT_REGISTER_SACT			equ	0x0034	; Serial ATA Active
DRIVER_AHCI_PORT_REGISTER_CI			equ	0x0038	; Command Issue
DRIVER_AHCI_PORT_REGISTER_SNTF			equ	0x003C	; Serial ATA Notification
DRIVER_AHCI_PORT_REGISTER_FBS			equ	0x0040	; FIS-based Switching Control
DRIVER_AHCI_PORT_REGISTER_DEVSLP		equ	0x0044	; Device Sleep
DRIVER_AHCI_PORT_REGISTER_VS			equ	0x0070	; Vendor Specific

DRIVER_AHCI_COMMAND_HEADER_CFL			equ	0x00000005	; Command FIS Length 4 DW (default)
DRIVER_AHCI_COMMAND_HEADER_A			equ	0x00000020	; ATAPI
DRIVER_AHCI_COMMAND_HEADER_W			equ	0x00000040	; Write
DRIVER_AHCI_COMMAND_HEADER_P			equ	0x00000080	; Prefetchable
DRIVER_AHCI_COMMAND_HEADER_R			equ	0x00000100	; Reset
DRIVER_AHCI_COMMAND_HEADER_B			equ	0x00000200	; BIST
DRIVER_AHCI_COMMAND_HEADER_C			equ	0x00000400	; Clear Busy upon R_OK
DRIVER_AHCI_COMMAND_HEADER_PRDTL		equ	0x00010000	; Physical Region Descriptor Table Length (default)

DRIVER_AHCI_COMMAND_TABLE_CFIS			equ	0x00	; Command FIS (up to 64 bytes)
DRIVER_AHCI_COMMAND_TABLE_ACMD			equ	0x40	; ATAPI Command (12 or 16 bytes)
DRIVER_AHCI_COMMAND_TABLE_PRDT			equ	0x80	; Physical Region Descriptor Table
DRIVER_AHCI_COMMAND_TABLE_PRDT_DBA		equ	0x80	; Data Base Address
DRIVER_AHCI_COMMAND_TABLE_PRDT_DBC		equ	0x8C	; Data Byte Count

driver_ahci_semaphore				db	STATIC_EMPTY
driver_ahci_base_address			dq	STATIC_EMPTY
driver_ahci_port				dq	STATIC_EMPTY
driver_ahci_cmd_list				dq	STATIC_EMPTY
driver_ahci_cmd_table				dq	STATIC_EMPTY
driver_ahci_fis					dq	STATIC_EMPTY

;===============================================================================
driver_ahci_init:
	; zachowaj oryginalne rejestry
	push	rax
	push	rbx
	push	rcx
	push	rsi
	push	r11

	; pobierz, adres przestrzeni konfiguracji kontrolera AHCI
	mov	eax,	DRIVER_PCI_REGISTER_bar5
	call	driver_pci_read

	; zapamiętaj
	mov	dword [driver_ahci_base_address],	eax

	; wyświetl informacje o przestrzeni adresowej
	mov	rsi,	kernel_init_string_ahci_address
	call	driver_serial_send
	mov	ecx,	STATIC_NUMBER_SYSTEM_hexadecimal
	call	driver_serial_send_value

	; mapuj przestrzeń pamięci rejestrów kontrolera AHCI do jądra systemu
	mov	ebx,	KERNEL_PAGE_FLAG_write | KERNEL_PAGE_FLAG_available
	mov	ecx,	STATIC_PAGE_SIZE_page
	mov	r11,	cr3	; tablica PML4 przestrzeni jądra systemu
	call	kernel_page_map_physical

	; pobierz specyfikacje portów (dostępnych)
	mov	eax,	dword [rsi + DRIVER_AHCI_HBA_MEMORY_REGISTER_PI]

	; debug
	mov	ecx,	STATIC_NUMBER_SYSTEM_binary
	call	driver_serial_send_value

.end:
	; przywróć oryginalne rejestry
	pop	r11
	pop	rsi
	pop	rcx
	pop	rbx
	pop	rax

	; powrót z procedury
	ret
