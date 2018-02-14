# Formats the Podfile according to the current PR, branch, and fork.

sed -i '' "s;BRANCH_NAME;$BITRISE_GIT_BRANCH;g" Podfile
sed -i '' "s;GIT_REPO_URL;"$BITRISEIO_PULL_REQUEST_REPOSITORY_URL";g" Podfile
