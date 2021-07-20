while read p; do
if [ ! -z "$(echo $p)" ]; then
if [ "$(echo $p | head -c 1)" != "#" ]; then
if [ -z "$(echo $p | grep ':')" ]; then
  file="$(echo $p | cut -d'|' -f1)"
else
  file="$(echo $p | cut -d'|' -f1 | cut -d: -f2)"
fi
if [ -f $file ]; then
rm -rf $file
fi
filename="${file##*/}"
filedir="${file/\/$filename/}"
mkdir -p $filedir
urlfile="${file/@/%40}"
wget -q --show-progress $1/$urlfile -O $file
fi
fi
done <files.txt
