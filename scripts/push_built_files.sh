#!/bin/bash

set -eu
set -o pipefail

if [ -z "$(git status --porcelain public)" ]; then
  echo "There are nothing to push"
else
  echo "There are changes to push"
  ghcp commit \
    -r "$GITHUB_REPOSITORY" \
    -b "$GITHUB_BRANCH" \
    -m "Update built files" \
    public
  echo "Pushed built files"
  echo "::notice::Retry in the next job"
  exit 1
fi
