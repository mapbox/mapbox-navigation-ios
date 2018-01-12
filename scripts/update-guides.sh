set -eu

if [ -d "navigation-ios-examples" ]; then rm -Rf navigation-ios-examples; fi
git clone https://github.com/mapbox/navigation-ios-examples

cp navigation-ios-examples/Navigation-Examples/Examples/*.swift docs/examples

for file in docs/examples/*.swift; do
    # Add markdown formatting
    url="https://github.com/mapbox/navigation-ios-examples/blob/master/Navigation-Examples/Examples/$(basename "$file" .swift).swift"
    urlNote="\n_Source available [here]($url)_\n"

    echo -e "$urlNote\n\`\`\`swift\n$(cat $file)\n\`\`\`" > $file

    # Add .md extension
    mv "$file" "docs/examples/$(basename "$file" .swift).md"
done

for file in docs/examples/*.md; do
  mv "$file" "${file//-/ }"
done

rm -rf navigation-ios-examples
