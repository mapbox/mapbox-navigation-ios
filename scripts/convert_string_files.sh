#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/file_conversion.sh"
DIRECTORIES=( "${DIR}/../Sources/MapboxNavigation" "${DIR}/../Sources/MapboxCoreNavigation" "${DIR}/../Example" )

for dir in ${DIRECTORIES[@]}
do
    for file in $(find $dir -name '*.strings');
    do  
        convertIfNeeded $file
    done
done
