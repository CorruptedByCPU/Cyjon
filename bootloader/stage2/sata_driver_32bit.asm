;=================================================================================
; Copyright (C) Andrzej Adamczyk (at https://blackdev.org/). All rights reserved.
;=================================================================================

;
; Main developer:
;	Andrzej (akasei) Adamczyk [e-mail: akasei from wataha.net]
;-------------------------------------------------------------------------------

; Use:
; nasm - http://www.nasm.us/

VARIABLE_AHCI_PCI					equ	0x0106

VARIABLE_AHCI_HBA_MEMORY_REGISTER_CAP			equ	0x00	; Host Capabilities
VARIABLE_AHCI_HBA_MEMORY_REGISTER_GHC			equ	0x04	; Global Host Control
VARIABLE_AHCI_HBA_MEMORY_REGISTER_IS			equ	0x08	; Interrupt Status
VARIABLE_AHCI_HBA_MEMORY_REGISTER_PI			equ	0x0C	; Ports Implemented
VARIABLE_AHCI_HBA_MEMORY_REGISTER_VS			equ	0x10	; Version
VARIABLE_AHCI_HBA_MEMORY_REGISTER_CCC_CTL		equ	0x14	; Command Completion Coalescing Control
VARIABLE_AHCI_HBA_MEMORY_REGISTER_CCC_PORTS		equ	0x18	; Command Completion Coalescing Ports
VARIABLE_AHCI_HBA_MEMORY_REGISTER_EM_LOC		equ	0x1C	; Enclosure Management Location
VARIABLE_AHCI_HBA_MEMORY_REGISTER_EM_CTL		equ	0x20	; Enclosure Management Control
VARIABLE_AHCI_HBA_MEMORY_REGISTER_CAP2			equ	0x24	; Host Capabilities Extended
VARIABLE_AHCI_HBA_MEMORY_REGISTER_BOHC			equ	0x28	; BIOS/OS Handoff Control and Status

VARIABLE_AHCI_PORT_REGISTER_BASE_ADDRESS		equ	0x0100
VARIABLE_AHCI_PORT_REGISTER_CLBA			equ	0x0000	; Command List Base Address
VARIABLE_AHCI_PORT_REGISTER_FB				equ	0x0008	; FIS Base Address
VARIABLE_AHCI_PORT_REGISTER_IS				equ	0x0010	; Interrupt Status
VARIABLE_AHCI_PORT_REGISTER_IE				equ	0x0014	; Interrupt Enable
VARIABLE_AHCI_PORT_REGISTER_CMD				equ	0x0018	; Command and Status
VARIABLE_AHCI_PORT_REGISTER_TFD				equ	0x0020	; Task File Data
VARIABLE_AHCI_PORT_REGISTER_SIG				equ	0x0024	; Signature
VARIABLE_AHCI_PORT_REGISTER_SSTS			equ	0x0028	; Serial ATA Status
VARIABLE_AHCI_PORT_REGISTER_SCTL			equ	0x002C	; Serial ATA Control
VARIABLE_AHCI_PORT_REGISTER_SERR			equ	0x0030	; Serial ATA Error
VARIABLE_AHCI_PORT_REGISTER_SACT			equ	0x0034	; Serial ATA Active
VARIABLE_AHCI_PORT_REGISTER_CI				equ	0x0038	; Command Issue
VARIABLE_AHCI_PORT_REGISTER_SNTF			equ	0x003C	; Serial ATA Notification
VARIABLE_AHCI_PORT_REGISTER_FBS				equ	0x0040	; FIS-based Switching Control
VARIABLE_AHCI_PORT_REGISTER_DEVSLP			equ	0x0044	; Device Sleep
VARIABLE_AHCI_PORT_REGISTER_VS				equ	0x0070	; Vendor Specific

VARIABLE_AHCI_COMMAND_HEADER_CFL			equ	0x00000005	; Command FIS Length 4 DW (default)
VARIABLE_AHCI_COMMAND_HEADER_A				equ	0x00000020	; ATAPI
VARIABLE_AHCI_COMMAND_HEADER_W				equ	0x00000040	; Write
VARIABLE_AHCI_COMMAND_HEADER_P				equ	0x00000080	; Prefetchable
VARIABLE_AHCI_COMMAND_HEADER_R				equ	0x00000100	; Reset
VARIABLE_AHCI_COMMAND_HEADER_B				equ	0x00000200	; BIST
VARIABLE_AHCI_COMMAND_HEADER_C				equ	0x00000400	; Clear Busy upon R_OK
VARIABLE_AHCI_COMMAND_HEADER_PRDTL			equ	0x00010000	; Physical Region Descriptor Table Length (default)

VARIABLE_AHCI_COMMAND_TABLE_CFIS			equ	0x00	; Command FIS (up to 64 bytes)
VARIABLE_AHCI_COMMAND_TABLE_ACMD			equ	0x40	; ATAPI Command (12 or 16 bytes)
VARIABLE_AHCI_COMMAND_TABLE_PRDT			equ	0x80	; Physical Region Descriptor Table
VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBA			equ	0x80	; Data Base Address
VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBC			equ	0x8C	; Data Byte Count

variable_ahci_base_address	dd	VARIABLE_EMPTY
variable_ahci_port		dd	VARIABLE_EMPTY
variable_ahci_cmd_list		dd	0x00020000
variable_ahci_cmd_table		dd	0x00030000
variable_ahci_fis		dd	0x00040000

; 32 Bitowy kod programu
[BITS 32]

stage2_sata_drive_initialize:
	; zachowaj oryginalne rejestry
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	xor	ebx,	ebx
	xor	ecx,	ecx
	mov	edx,	2	; pobierz class/subclass

.next:
	call	stage2_pci_read

	shr	eax,	16
	cmp	ax,	VARIABLE_AHCI_PCI
	je	.setup

	inc	ecx

	cmp	ecx,	256
	jb	.next

	inc	ebx
	xor	ecx,	ecx

	cmp	ebx,	256
	jb	.next

.end:
	; nie znaleziono kontrolera sieci

	; przywróć oryginalne rejestry
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

	; powrót z procedury
	jmp	stage2_protected_mode.drive_select_ide

.setup:
	; pobierz BAR5, adres przestrzeni konfiguracji AHCI
	mov	dl,	9
	call	stage2_pci_read

	; zapamiętaj
	mov	dword [variable_ahci_base_address],	eax

	mov	esi,	eax

	; pobierz specyfikacje portów (dostępnych)
	mov	eax,	dword [esi + VARIABLE_AHCI_HBA_MEMORY_REGISTER_PI]

	; sprawdź port zero
	bt	eax,	0
	jnc	.end

	; pobierz status urządzenia
	add	esi,	VARIABLE_AHCI_PORT_REGISTER_BASE_ADDRESS
	mov	eax,	dword [esi + VARIABLE_AHCI_PORT_REGISTER_SSTS]
	cmp	eax,	VARIABLE_EMPTY
	je	.end

	; poinformuj urządzenie/dysk o adresie przestrzeni poleceń
	mov	edi,	dword [variable_ahci_cmd_list]
	mov	eax,	edi
	mov	edi,	esi
	add	edi,	VARIABLE_AHCI_PORT_REGISTER_CLBA
	stosd
	xor	eax,	eax
	stosd

	; poinformuj urządzenie/dysk o adresie przestrzeni Frame Information Structure
	mov	edi,	dword [variable_ahci_fis]
	mov	eax,	edi
	mov	edi,	esi
	add	edi,	VARIABLE_AHCI_PORT_REGISTER_FB
	stosd
	xor	eax,	eax
	stosd

	; wyczyść rekordy
	stosd	; Port x Interrupt Status
	stosd
	stosd	; Port x Interrupt Enable
	stosd

	; ustaw interfejs dysku na AHCI
	mov	eax,	ahci_drive_read_sectors
	mov	dword [variable_disk_interface_read],	eax

	; przywróć oryginalne rejestry
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

	; powrót z procedury
	jmp	stage2_protected_mode.drive_selected

text_ahci_found	db	"sata", VARIABLE_ASCII_CODE_TERMINATOR

; eax - numer bezwzględny (LBA) sektora
; ecx - ilość sektorów do odczytu
; edi - gdzie załadować
ahci_drive_read_sectors:
	; zachowaj oryginalne rejestry
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	esi
	push	edi

	; zmienne lokalne
	push	ecx
	push	edi
	push	eax
	push	eax

	mov	edi,	dword [variable_ahci_cmd_list]

	; DW 0
	mov	eax,	VARIABLE_AHCI_COMMAND_HEADER_PRDTL | VARIABLE_AHCI_COMMAND_HEADER_CFL
	stosd

	; DW 1
	xor	eax,	eax
	stosd

	; DW 2
	mov	eax,	dword [variable_ahci_cmd_table]
	stosd

	; DW 3
	xor	eax,	eax
	stosd

	; DW 4, 5, 6, 7
	stosd
	stosd
	stosd
	stosd

	; VARIABLE_AHCI_COMMAND_TABLE_CFIS
	mov	edi,	dword [variable_ahci_cmd_table]

	; 0x00 Features, 0x25 READ DMA EXT, 0x80 C bit set, 0x27 H2D
	mov	eax,	0x00258027
	stosd

	; przywróć numer bezwzględny pierwszego sektora do odczytania
	pop	eax

	; port 0
	and	eax,	0x00FFFFFF

	; włącz tryb LBA
	bts	eax,	30
	stosd	; LBA 23..0

	; przywróć numer bezwzględny pierwszego sektora do odczytania
	pop	eax

	; przesuń bity 31..24 na początek rejestru
	shr	eax,	24
	stosd	; Feature 15..8, LBA 31..24

	; załaduj ilość sektorów do odczytania
	mov	eax,	ecx
	stosd	; Control 31..24, ICC 23..16, Count 15..0

	; 32 bity zastrzeżone
	xor	eax,	eax
	stosd

	mov	edi,	dword [variable_ahci_cmd_table]

	; pobierz adres docelowy
	pop	eax

	; bity 31..0
	mov	dword [edi + VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBA],	eax
	; bity 63..32
	xor	eax,	eax
	mov	dword [edi + VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBA + VARIABLE_DWORD_SIZE],	eax

	; pobierz ilość sektorów do odczytania
	pop	eax
	; zamień na Bajty
	shl	eax,	9
	; licz od zera
	dec	eax
	mov	dword [edi + VARIABLE_AHCI_COMMAND_TABLE_PRDT_DBC],	eax

	mov	esi,	dword [variable_ahci_base_address]
	add	esi,	VARIABLE_AHCI_PORT_REGISTER_BASE_ADDRESS

	; zresetuj status przerwania
	mov	dword [esi + VARIABLE_AHCI_PORT_REGISTER_IS],	VARIABLE_EMPTY

	; pobierz informacje o poleceniu i statusie
	mov	eax,	dword [esi + VARIABLE_AHCI_PORT_REGISTER_CMD]
	bts	eax,	4	; FRE - włącz przesyłanie z dysku do pamięci
	bts	eax,	0	; ST - rozpocznij
	; aktualizuj
	mov	dword [esi + VARIABLE_AHCI_PORT_REGISTER_CMD],	eax

	; Wykonaj działania na porcie 0
	mov	dword [esi + VARIABLE_AHCI_PORT_REGISTER_CI],	VARIABLE_TRUE

.pool:
	; czekaj na zakończenie operacji przesyłu danych
	cmp	dword [esi + VARIABLE_AHCI_PORT_REGISTER_CI], VARIABLE_EMPTY
	jne	.pool

	; pobierz informacje o poleceniu i statusie
	mov	eax,	dword [esi + VARIABLE_AHCI_PORT_REGISTER_CMD]
	btr	eax,	4	; FRE - wyłącz przesyłanie z dysku do pamięci
	btr	eax,	0	; ST - zatrzymaj
	; aktualizuj
	mov	dword [esi + VARIABLE_AHCI_PORT_REGISTER_CMD],	eax

	; przywróć oryginalne rejestry
	pop	edi
	pop	esi
	pop	edx
	pop	ecx
	pop	ebx
	pop	eax

	; powrót z procedury
	ret
