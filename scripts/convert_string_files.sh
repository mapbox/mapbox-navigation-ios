#!/usr/bin/env bash

source ./file_conversion.sh
DIRECTORIES=( "../MapboxNavigation" "../MapboxCoreNavigation" "../Examples" )

for dir in ${DIRECTORIES[@]}
do
    for file in $(find $dir -name '*.strings');
    do  
        convertIfNeeded $file
    done
done
