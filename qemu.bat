..\qemu\qemu-system-x86_64w -hda build/disk.raw -m 16 -smp 2 -rtc base=localtime -serial telnet:localhost:4321,server,nowait
