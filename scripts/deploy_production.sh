#!/bin/bash -eux

if [ -z "${GIT_USER_NAME}" ]; then
  echo "Please set an env var GIT_USER_NAME"
  exit 1
fi

if [ -z "${GIT_USER_EMAIL}" ]; then
  echo "Please set an env var GIT_USER_EMAIL"
  exit 1
fi

GIT_REPO="git@github.com:${CIRCLE_PROJECT_USERNAME}/${CIRCLE_PROJECT_REPONAME}.git"

git submodule init
git submodule update

remote=`git ls-remote --heads 2> /dev/null | grep gh-pages-debug || true`

if [ -n "$remote" ]; then
  git clone -b gh-pages-debug "${GIT_REPO}" public
  rm -rf public/*
else
  git init public
  cd public
  git checkout -b gh-pages-debug
  git remote add origin "${GIT_REPO}"
  cd ..
fi

hugo
cp -prv .circleci public
cd public
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
git add --all
git commit -m 'Update [ci skip]'
git push -f origin gh-pages-debug
