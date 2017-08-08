#!/usr/bin/env bash

NAVIGATION=../MapboxNavigation
CORE=../MapboxCoreNavigation

LANGUAGES=( "Base" )

for lang in ${LANGUAGES[@]}
do
    echo "Extracting ${lang} strings"

    # Extract localizable strings from .swift files
    find ${NAVIGATION} -name "*.swift" -print0 | xargs -0 xcrun extractLocStrings -o "${NAVIGATION}/Resources/${lang}.lproj"
    STRINGS_FILE="${NAVIGATION}/Resources/${lang}.lproj/Localizable.strings"

    # Convert UTF-16LE generated files to UTF-8
    iconv -f UTF-16LE -t UTF-8 ${STRINGS_FILE} > ${STRINGS_FILE}.new
    mv -f ${STRINGS_FILE}.new ${STRINGS_FILE}
done
