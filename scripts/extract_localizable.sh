#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

NAVIGATION="${DIR}/../MapboxNavigation"
CORE="${DIR}/../MapboxCoreNavigation"

LANGUAGES=( "Base" )

for lang in ${LANGUAGES[@]}
do
    echo "Extracting ${lang} strings"

    # Extract localizable strings from .swift files
    find ${NAVIGATION} -name "*.swift" -print0 | xargs -0 xcrun extractLocStrings -o "${NAVIGATION}/Resources/${lang}.lproj"
    STRINGS_FILE="${NAVIGATION}/Resources/${lang}.lproj/Localizable.strings"

    # Extract localizable strings from .swift files
    find ${CORE} -name "*.swift" -print0 | xargs -0 xcrun extractLocStrings -o "${CORE}/Resources/${lang}.lproj"
    STRINGS_FILE="${CORE}/Resources/${lang}.lproj/Localizable.strings"

    # Extract localizable strings from storyboard
    ibtool ${NAVIGATION}/Resources/${lang}.lproj/Navigation.storyboard --generate-strings-file ${NAVIGATION}/Resources/${lang}.lproj/Navigation.strings

    # Remove strings that should not be translated
    source "${DIR}/file_conversion.sh"
    convertIfNeeded "${NAVIGATION}/Resources/${lang}.lproj/Navigation.strings"
    sed -i '' -e '/DO NOT TRANSLATE/{N;N;d;}' "${NAVIGATION}/Resources/${lang}.lproj/Navigation.strings"

    # Convert UTF-16LE generated files to UTF-8
    iconv -f UTF-16LE -t UTF-8 ${STRINGS_FILE} > ${STRINGS_FILE}.new
    mv -f ${STRINGS_FILE}.new ${STRINGS_FILE}
done
