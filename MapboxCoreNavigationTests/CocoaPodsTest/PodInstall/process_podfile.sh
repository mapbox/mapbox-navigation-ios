# Formats the Podfile according to the current PR, branch, and fork.
USER_GH_SUFFIX=`git config --get remote.origin.url | cut -d ":" -f 2`
GH_URL="https://github.com/$USER_GH_SUFFIX"

sed -i '' "s;BRANCH_NAME;$BITRISE_GIT_BRANCH;g" Podfile
sed -i '' "s;GIT_REPO_URL;"$BITRISEIO_PULL_REQUEST_REPOSITORY_URL";g" Podfile
