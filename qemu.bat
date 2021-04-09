start ../qemu/qemu-system-x86_64w -boot a -fda build/cyjon.img -hda build/fat32.img -hdd build/ext2.img -m 32 -smp 2 -rtc base=localtime -serial file:serial.log
