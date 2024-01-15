echo -n "Linii kodu: "
for i in `find . | grep asm`; do cat $i | grep -v -e '^$' -e '^[[:space:]];'; done | wc -l
