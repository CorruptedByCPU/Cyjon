rm build/cyjon.img.lock
rm build/fat32.img.lock
rm build/ext2.img.lock
bochs -f bochsrc-linux.bxrc -q
