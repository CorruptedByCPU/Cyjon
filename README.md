# Cyjon

Prosty i wielozadaniowy system operacyjny, napisany w języku asemblera dla procesorów z rodziny amd64/x86-64.

![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/cyjon.png)

### Wymagania:

  - 2 MiB pamięci RAM (1 MiB za adresem 0x00100000)
  - klawiatura na porcie PS2 (część BIOSów emuluje klawiatury USB)

### Opcjonalne:

  - kontroler sieci Intel 82540EM (E1000)

### Uwagi:

Przy programowaniu/testowaniu sieci (TCP/IP), korzystam tylko z symulatora **Bochs** na MS/Windows.

	# bochs.rc
	plugin_ctrl: e1000=1
	e1000: enabled=1, mac=00:22:44:66:88:aa, ethmod=win32, ethdev=\Device\NPF_{ebe79137-186a-4318-b187-0158cf04efd1}, script=none

Natomiast, wszelkie inne operacje na systemie GNU/Linux. Dystrybucja jest nieważna, całe środowisko programistyczne muszę skompilować pod siebie i włączyć opcje, które domyślnie nie są dostepne w gotowych pakietach.

### Kompilacja (GNU/Linux):

	# select a resolution supported by the BIOS
	WIDTH=640
	HEIGHT=480

	nasm -f bin software/init.asm		-o build/init
	nasm -f bin software/shell.asm		-o build/shell
	nasm -f bin software/hello.asm		-o build/hello

	nasm -f bin kernel/init/boot.asm	-o build/boot
	nasm -f bin kernel/kernel.asm		-o build/kernel \
		-dMULTIBOOT_VIDEO_WIDTH_pixel=${WIDTH} \
		-dMULTIBOOT_VIDEO_HEIGHT_pixel=${HEIGHT}
	nasm -f bin zero/zero.asm		-o build/disk.raw \
		-dMULTIBOOT_VIDEO_WIDTH_pixel=${WIDTH} \
		-dMULTIBOOT_VIDEO_HEIGHT_pixel=${HEIGHT}

### Kompilacja (MS Windows):

	rem select a resolution supported by the BIOS
	set WIDTH=640
	set HEIGHT=480

	nasm -f bin software/init.asm		-o build/init
	nasm -f bin software/shell.asm		-o build/shell
	nasm -f bin software/hello.asm		-o build/hello

	nasm -f bin kernel/init/boot.asm	-o build/boot
	nasm -f bin kernel/kernel.asm		-o build/kernel -dMULTIBOOT_VIDEO_WIDTH_pixel=%WIDTH% -dMULTIBOOT_VIDEO_HEIGHT_pixel=%HEIGHT%
	nasm -f bin zero/zero.asm		-o build/disk.raw -dMULTIBOOT_VIDEO_WIDTH_pixel=%WIDTH% -dMULTIBOOT_VIDEO_HEIGHT_pixel=%HEIGHT%

### Uruchomienie:

	# 2 MiB RAM, 2 procesory logiczne, bez obsługi sieci, dysk podłączony do kontrolera IDE
	qemu-system-x86_64 -hda file=build/disk.raw -m 2 -smp 2 -rtc base=localtime
