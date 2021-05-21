#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

EXAMPLE="${DIR}/../Example"
NAVIGATION="${DIR}/../Sources/MapboxNavigation"
CORE="${DIR}/../Sources/MapboxCoreNavigation"

LANGUAGES=( "en" )

source "${DIR}/file_conversion.sh"

for lang in ${LANGUAGES[@]}
do
    echo "Extracting ${lang} strings"

    # Extract localizable strings from .swift files
    find ${EXAMPLE} -name "*.swift" -print0 | xargs -0 xcrun extractLocStrings -o "${EXAMPLE}/${lang}.lproj"
    STRINGS_FILE="${EXAMPLE}/${lang}.lproj/Localizable.strings"
    convertIfNeeded ${STRINGS_FILE}

    # Extract localizable strings from .swift files
    find ${NAVIGATION} -name "*.swift" -print0 | xargs -0 xcrun extractLocStrings -o "${NAVIGATION}/Resources/${lang}.lproj"
    STRINGS_FILE="${NAVIGATION}/Resources/${lang}.lproj/Localizable.strings"
    convertIfNeeded ${STRINGS_FILE}

    # Extract localizable strings from .swift files
    find ${CORE} -name "*.swift" -print0 | xargs -0 xcrun extractLocStrings -o "${CORE}/Resources/${lang}.lproj"
    STRINGS_FILE="${CORE}/Resources/${lang}.lproj/Localizable.strings"
    convertIfNeeded ${STRINGS_FILE}

    # Extract localizable strings from storyboard
    ibtool ${NAVIGATION}/Resources/Base.lproj/Navigation.storyboard --generate-strings-file ${NAVIGATION}/Resources/${lang}.lproj/Navigation.strings

    # Remove strings that should not be translated
    convertIfNeeded "${NAVIGATION}/Resources/${lang}.lproj/Navigation.strings"
    sed -i '' -e '/DO NOT TRANSLATE/{N;N;d;}' "${NAVIGATION}/Resources/${lang}.lproj/Navigation.strings"
done
