#!/usr/bin/env/bash

function convertIfNeeded {
    # Convert from UTF-16LE to UTF-8
    if [[ $(file -I $1) == *"utf-16le"* ]];then
        iconv -f UTF-16 -t UTF-8 ${1} > ${1}.converted
        mv -f ${1}.converted ${1}
        echo "Converted $1"
    else
        echo "$1 is already UTF-8"
    fi
}
