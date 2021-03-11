start ../qemu/qemu-system-x86_64w -boot a -fda build/cyjon.img -hdb build/fat32.img -m 16 -smp 2 -rtc base=localtime -serial file:serial.log
