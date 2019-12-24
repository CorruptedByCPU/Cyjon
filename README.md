# Cyjon

Prosty i wielozadaniowy system operacyjny, napisany w języku asemblera dla procesorów z rodziny amd64/x86-64.

![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/cyjon.png)

![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/ping.png)

![screenshot](https://raw.githubusercontent.com/blackend/cyjon/master/http.png)

### Wymagania:

  - 2 MiB pamięci RAM
  - klawiatura na porcie PS2

### Opcjonalne:

  - kontroler sieci Intel 82540EM (E1000)

### Kompilacja:

	nasm -f bin kernel/kernel.asm	-o build/kernel
	nasm -f bin zero/zero.asm	-o build/disk.raw

### Uruchomienie:

	qemu-system-x86_64 -drive file=build/disk.raw,media=disk,format=raw -m 2 -smp 1 -rtc base=localtime
