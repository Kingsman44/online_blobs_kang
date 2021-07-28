#path="../vendor/mido/proprietary/"
path=""
error=0
if [ ! -z "$1" ]; then

    if [ ! -z "$(echo "$@" | grep -- '--force')" ]; then
        force=1
    else
        force=0
    fi
    para=${@/$1/}
    url=$1
    repo="${url##*/}"
    branch="$(curl --silent $1 | grep .zip | grep href=)"
    branch="${branch/<\/a>/}"
    branch="${branch##*/}"
    branch="${branch/$repo-/}"
    branch=$(echo $branch | cut -d\" -f1)
    branch="${branch/.zip/}"
    #echo $branch
    if [ ! -z "$(echo "$para" | grep -- '-b ')" ]; then
        branch="${para##*-b }"
        branch=$(echo $branch | cut -d' ' -f1)
	echo $branch
        if [ -z $branch ]; then
            echo "Error: No branch name if given"
            error=1
        fi
    fi

    if [ -z $branch ] && [ $force -eq 0 ]; then
        echo "Invalid link"
        echo "If you think, link is valid use --force tag"
        error=1
    fi

    #echo "Error:$error"
    if [ $error -eq 0 ]; then
        if [ -z "$(echo $url | grep 'github.com')" ]; then
            rawlink="$1/-/raw/$branch"
        else
            rawlink="$1/$branch"
            rawlink="${rawlink/github.com/raw.githubusercontent.com}"
        fi

        #echo $rawlink
        fold=""
        rm -rf temp.txt

        wget -q $rawlink/all_files.txt -O temp.txt
        if [ -z "$(cat temp.txt)" ]; then
            rm -rf temp.txt
            echo "</html>" > temp.txt
        fi

        if [ -z "$(cat temp.txt | grep '</html>')" ]; then
            dump=true
        elif [ ! -z "$(echo "$@" | grep -- '--force')" ]; then
            dump=false
        elif [ ! -z "$2" ] && [ "$(echo $2 | head -c 1)" != "-" ]; then
            rm -rf temp.txt
            #echo "yes"
            wget -q $rawlink/$2/$2-vendor.mk -O temp.txt
            dump=true
            if [ -z "$(cat temp.txt)" ]; then
                error=1
                echo "Error: $2/$2-vendor.mk doesn't exist"
            else
                fold="$2/proprietary/"
            fi
        else
            error=1
            echo "Error: Link is not valid dump or device not given"
        fi
    fi
    if [ $error -eq 0 ]; then
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
                    urlfile="${file/@/%40}"
                    if [ $dump == "true" ]; then
                        dumpfile="proprietary/$(cat temp.txt | grep $file | cut -d: -f1)"
                        dumpfile="${dumpfile/ /}"
                        #echo $dumpfile
                        dumpfile="${dumpfile##*proprietary/}"
                        #echo $dumpfile
                        if [ -z "$dumpfile" ]; then
                            if [ ! -z "$file2" ]; then
                                if [ ! -z "$(cat temp.txt | grep $file2 | cut -d: -f1)"]; then
                                    dumpfile="proprietary/$(cat temp.txt | grep $file2 | cut -d: -f1)"
                                    dumpfile="${dumpfile/ /}"
                                    dumpfile="${dumpfile##*proprietary/}"
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
                            mkdir -p $path$filedir
                            wget -q --show-progress $rawlink/$fold$dumpfile -O $path$file
                            if [ ! -z "$(echo $file | grep 'bin/')" ]; then
                                chmod 0755 $path$file
                            fi
                        fi
                    else
                        if [ -f $path$file ]; then
                            rm -rf $path$file
                        fi
                        wget -q --show-progress $1/$urlfile -O $path$file
                        if [ ! -z "$(echo $file | grep 'bin/')" ]; then
                            chmod 0755 $path$file
                        fi
                    fi
                fi
            fi
            error=0
        done <files.txt
    fi
else
    echo "Error: link not specified"
fi
rm -rf temp.txt
