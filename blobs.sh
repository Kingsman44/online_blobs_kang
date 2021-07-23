error=0
path=vendor/mido/proprietary/
rm -rf temp.txt
if [ ! -z "$(echo $@ | grep -- '-dump')" ]; then
    dump=true
    wget -q $1/all_files.txt -O temp.txt
else
    dump=false
fi

while read p; do
    if [ ! -z "$(echo $p)" ]; then
        if [ "$(echo $p | head -c 1)" != "#" ]; then
            if [ -z "$(echo $p | grep ':')" ]; then
                file="$(echo $p | cut -d'|' -f1)"
                file2=""
            else
                if [ $dump == "false" ]; then
                    file="$(echo $p | cut -d'|' -f1 | cut -d: -f2)"
                    file2=""
                else
                    file="$(echo $p | cut -d'|' -f1 | cut -d: -f2)"
                    file2="$(echo $p | cut -d'|' -f1 | cut -d: -f1)"
                fi
            fi
            if [ "$(echo $p | head -c 1)" == "-" ]; then
                file="${file:1}"
                if [ ! -z "$file2" ]; then
                    file2="${file2:1}"
                fi
            fi
            filename="${file##*/}"
            filedir="${file/\/$filename/}"
            mkdir -p $path$filedir
            urlfile="${file/@/%40}"
            if [ $dump == "false" ]; then
                if [ -f $path$file ]; then
                    rm -rf $path$file
                fi
                wget -q --show-progress $1/$urlfile -O $path$file
                if [ ! -z "$(echo $file | grep 'bin/')" ]; then
                    chmod 0755 $path$file
                fi
            else
                dumpfile="$(cat temp.txt | grep $file)"
                if [ -z "$dumpfile" ]; then
                    if [ ! -z "$file2" ]; then
                        if [ ! -z "$(cat temp.txt | grep $file2)"]; then
                            dumpfile="$(cat temp.txt | grep $file2)"
                        else
                            echo "Cannot find file $file"
                            error=1
                        fi
                    else
                        echo "Cannot find file $file"
                        error=1
                    fi
                fi
                if [ $error -eq 0 ]; then
                    if [ -f $path$file ]; then
                        rm -rf $path$file
                    fi
                    wget -q --show-progress $1/$dumpfile -O $path$file
		    if [ ! -z "$(echo $file | grep 'bin/')" ]; then
                        chmod 0755 $path$file
                    fi
                fi
            fi
        fi
    fi
    error=0
done <files.txt
rm -rf temp.txt
