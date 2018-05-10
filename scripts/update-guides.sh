set -eu

EXAMPLES_DIR=../navigation-ios-examples

# If there isn't an existing examples clone, create a temporary one.
if [ ! -d $EXAMPLES_DIR ]; then
  EXAMPLES_DIR=navigation-ios-examples
  if [ -d $EXAMPLES_DIR ]; then rm -Rf navigation-ios-examples; fi
  git clone https://github.com/mapbox/navigation-ios-examples
fi

cp $EXAMPLES_DIR/Navigation-Examples/Examples/*.swift docs/examples

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

# Delete the temporary examples clone.
rm -rf navigation-ios-examples
