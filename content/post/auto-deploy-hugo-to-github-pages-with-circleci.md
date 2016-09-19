+++
date = "2016-09-19T10:30:35+09:00"
title = "Hugo で作ったサイトを CircleCI で GitHub Pages に自動デプロイ"

+++
Hugo は Jekyll と違って、GitHub Pages に push すれば勝手にページ生成はされません。  
どうにかして自分で Hugo を実行し、それで生成されたファイルを push する必要があります。  
このブログを構築するにあたって、CircleCI でビルドして自動デプロイする手順がまとまったので公開します。

なお、このブログはカスタムドメインを使用していますが、それについての説明はこの記事ではしません。

## 前提とする環境

* Hugo Ver. 0.16

## 概要

以下のような環境・手順で自動デプロイが行われるようにします。

* 記事のソースは `master` ブランチに push する
* GitHub Pages 用のブランチには `gh-pages` を使う
* `master` ブランチが更新された時に `gh-pages` が自動的に更新される

## セットアップ手順

### 対象ブランチの設定

当然ですがリポジトリを準備します。

そしてリポジトリの Settings から GitHub Pages の Source として `gh-pages` を選択します。

ただし、`gh-pages` ブランチがない状態だと選択できないと思うので、その場合は手動でブランチだけ作るか、CircleCI によるデプロイが行われた後で行うと良いでしょう。

<img src="/images/auto-deploy-hugo-to-github-pagesmd-with-circleci/github-setting.png" width="248" height="222">

### デプロイキーの用意

CircleCI は CI 対象のリポジトリを登録する時に、自動的に対象リポジトリの SSH キーを生成します。  
が、これは read-only なので、今回の様に CircleCI から GitHub に push したい場合は使えません。  
なので手動で生成し、登録する必要があります。

鍵の生成については GitHub のドキュメント等を参照してください。  
[Generating a new SSH key](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/#generating-a-new-ssh-key)


生成したら GitHub リポジトリの Settings -> Deploy keys -> Add deploy key と進み、Key には生成した公開鍵ファイルの中身を貼り付け、Allow write access にチェックを入れてください。

<img src="/images/auto-deploy-hugo-to-github-pagesmd-with-circleci/add-a-deploy-key.png" width="311" height="502">

また、CircleCI 側には秘密鍵を登録します。  
Project Settings -> SSH Permissions -> Add SSH Key と進み、hostname には github.com、Private Key には秘密鍵の中身を貼り付けてください。  
これで github.com へのデプロイ時にはこの鍵ファイルが使われるようになります。

<img src="/images/auto-deploy-hugo-to-github-pagesmd-with-circleci/add-an-ssh-key.png" width="429" height="289">

### デプロイスクリプトの用意

circle.yml は以下のようなものを準備します。  
`master` ブランチが更新された時はデプロイ用のスクリプトを実行するようになっています。

```yml
dependencies:
  pre:
  - wget https://github.com/spf13/hugo/releases/download/v0.16/hugo_0.16-1_amd64.deb
  - sudo dpkg -i hugo_0.16-1_amd64.deb

test:
  override:
    - "true"

deployment:
  production:
    branch: master
    commands:
    - ./scripts/deploy_production.sh
```

デプロイスクリプトは以下のようにします。  
これを `scripts/deploy_production.sh` という名前で保存して、忘れずに `chmod +x` しておきましょう。  
設定部分は環境変数でセットするようにしてあるので、コピペそのままで使えると思います。

```bash
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

remote=`git ls-remote --heads 2> /dev/null | grep gh-pages || true`

if [ -n "$remote" ]; then
  git clone -b gh-pages "${GIT_REPO}" public
  rm -rf public/*
else
  git init public
  cd public
  git checkout -b gh-pages
  git remote add origin "${GIT_REPO}"
  cd ..
fi

hugo
cd public
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
git add --all
git commit -m 'Update [ci skip]'
git push -f origin gh-pages
```

環境変数は CircleCI の Project Settings から Environment Variables へと進んで、以下を登録します。

* `GIT_USER_NAME`: git commit 時の名前
* `GIT_USER_EMAIL`: git commit 時のメールアドレス

いずれも普段使いの Git と同じ設定にするのが良いでしょう。

### Hugo をセットアップして git push

あとは Hugo のファイルを `git push` すれば勝手にデプロイされます。  
このとき以下の点に注意してください。

* `public` ディレクトリは `.gitignore` に入れておき、生成されたファイルはコミットしないようにする
* `config.toml` に `theme` を設定する
  * 本来コマンドラインオプションで渡すこともできるが、デプロイスクリプト中では指定していないので

## まとめ

こうして出来上がったのがこのブログです。  
リポジトリは公開してあるので、気になる点があればチェックしてみてください。

https://github.com/yuya-takeyama/blog.yuyat.jp

Enjoy blogging!
