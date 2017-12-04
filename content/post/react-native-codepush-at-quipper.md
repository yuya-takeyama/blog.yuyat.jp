---
title: "Quipper での CodePush を使った OTA 配信とその自動化"
date: 2017-12-06T00:00:00+09:00
---
この記事は [React Native Advent Calendar 2017](https://qiita.com/advent-calendar/2017/react_native) 6 日目の記事です。5 日目は Quipper 同僚の @hotchemi によるあの記事でした。

この記事では Quipper で最近運用が始まった OTA (Over The Air) によるアプリ配信の運用とその自動化について紹介します。

<!--more-->

## OTA (Over The Air) とは

この記事においては React Native における OTA についてなので、アプリ中の JS 部分 (JS Bundle) だけを HTTP 経由で配信することを指します。

ちょっとした不具合の修正だったり、スタイルの微調整などをいつでも行うことができます。

今回紹介する CodePush も 2 年前にはすでに始まっており、以下の記事で紹介されています。

* [React Native - Over-The-Air updates](https://qiita.com/shohey1226/items/20bab79a4778ee774fbd)

## 最近の CodePush 事情

もともと CodePush は Microsoft が運営する独立したサービスでしたが、つい先日 Visual Studio App Center というサービスに統合されました。

アプリのリリースとほぼ同タイミングだったのでちょっと驚きましたが、SDK はそのままでも使えるので特に問題ありませんでした。運営も変わらず Microsoft です。

App Center が何かというと CI とか MBaaS とかが全部入りのサービスで、React Native に限らず Cordova によるアプリや通常の Android/iOS ネイティブアプリ等も対応しています。

今のところビルドとテストは CircleCI、クラッシュリポートは Sentry、プッシュ通知は Firebase という感じで使い分けており、今は CodePush 以外の機能は使っていません。

## CodePush のセットアップ

セットアップについては公式のドキュメント通りで問題ないのでそちらを参照してください。

* [CodePush](https://docs.microsoft.com/en-us/appcenter/distribution/codepush/)

完全に新規のアプリにインストールするときはほぼ問題ないと思いますが、[react-native-navigation](https://github.com/wix/react-native-navigation) のようなネイティブのコードを含むモジュールが既に入っている場合はうまくいかないこともあるので、注意が必要です。

`react-native link` コマンドで自動修正が行われた `AppDelegate.m` 等のファイルはよく注意が必要です。

私たちの場合は以下のようなコードになってしまっていたため、CodePush の分岐に絶対に入らないようになってしまっていました。

```objective-c
  #ifdef DEBUG
    #ifdef DEBUG
        jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
    #else
        // 本当はここの分岐に入って欲しいけど、よく見ると絶対にこの分岐には入らない
        jsCodeLocation = [CodePush bundleURL];
    #endif
  #else
    jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
  #endif
```

CodePush の変更適用後、アプリを再起動するとロールバックしてしまうという現象に悩まされましたが、以下のように直すことで解消できました。

```objective-c
  #ifdef DEBUG
    jsCodeLocation = [CodePush bundleURL];
  #else
    jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index" fallbackResource:nil];
  #endif
```

教訓としては `react-native link` は過度に信用しないように、ということで。

## CodePush による自動 OTA Updates のフロー

基本的には [Git Flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) とほぼ変わらなくて、リリース方法が CodePush とバイナリリリースとで分かれているので、その部分だけ手を加えいています。

<img src="/images/react-native-codepush-at-quipper/branch.png" width="735" height="413">

`master` ブランチは [fastlane](https://fastlane.tools/) でのバイナリの自動リリースに使うつもりですが、頻度は高くないので後回しにしてます。

ビルドやデプロイは先に書いた通り CircleCI を使って、GitHub でのマージをトリガーに実行しています。

App Center の機能が便利そうならそっちを使ってみてもいいかもしれませんが、今のところは特に困っていることもないので考えていません。

## 必要なツールのインストール

CodePush へのアプリの追加や Deployment と呼ばれる環境の追加、デプロイの実行等は基本的に [`appcenter-cli`](https://github.com/Microsoft/appcenter-cli) と呼ばれるツールが必要です。手動操作用と自動化用にグローバル・ローカル両方にインストールします。

```
# グローバルインストール
$ npm install -g appcenter-cli

# プロジェクトへのローカルインストール
$ yarn add -D appcenter-cli
```

ところでこの appcenter-cli ですが、ここ数日の統合のタイミングでドカドカと Pull Request が作られてまとめて取り込まれたせいもあってか、割と致命的な不具合が見つかっては直されている状態なので、正直品質はかなりアレかもしれません。必要に応じては旧 [`code-push-cli`](https://www.npmjs.com/package/code-push-cli) を使うこともあるかもしれません。OSS なので自分で直して Pull Request を送るのも良いと思います。

* [Organization に属するアプリのデプロイが常に失敗する不具合の修正](https://github.com/Microsoft/appcenter-cli/pull/321)
* [--target-binary-version で semver がうまく指定できない問題の修正](https://github.com/Microsoft/appcenter-cli/pull/331)

## App Center への登録

登録は GitHub アカウントでのログイン等で簡単にできます。

* [Signup to Visual Studio App Center](https://appcenter.ms/signup)

## Organization の作成

会社で運用する上では Organization を作っておくのが良いでしょう。Web 上のコンソールから作成します。

## App の作成

作った Organization に紐付く形で App を作成します。これも Web 上のコンソールから。

間違って個人アカウントに紐づけてしまっても、各 App ごとの Settings 画面から Transfer app to organization というメニューで移管が可能なので問題ありません。

## アクセストークンの作成

デプロイを実行するためのアクセストークンを作成します。

```
$ appcenter tokens create -d '用途の説明'
```

アクセストークンは後からの参照はできません。CircleCI であれば環境変数として登録しておきます。

わからなくなった場合は古いトークンを削除して再発行し直すのがいいので、メモする必要はないでしょう。

## Deployment の作成

Deployment というのは CodePush においては環境のことだと思ってください。デフォルトでは Production と Staging というのが作られます。

Quipper では以下のように使っています。

* Development: `develop` ブランチにマージしたものを自動でデプロイ
* Release: リリーステスト用。`release/codepush/v*` にマージすると自動デプロイ
* Production: 本番用。`deploy/codepush` にマージすると自動デプロイ

必要に応じて以下のように作成します。

```
$ appcenter codepush deployment add --app OurOrg/AwesomeApp NewDeploymentName
```

## デプロイのためのスクリプトの用意

自動デプロイのために以下のコマンドを用意します。

* `yarn codepush:login`: アクセストークンによるログイン
* `yarn codepush:deploy`: CodePush へのデプロイの実行

今回は上述の通り CircleCI の環境変数にアクセストークンを持たせているので、`$CODEPUSH_ACCESS_TOKEN` として参照します。

```json
{
  "scripts": {
    "codepush:login": "appcenter login --token $CODEPUSH_ACCESS_TOKEN",
    "codepush:deploy": "./scripts/deploy_codepush Production"
  }
}
```

`yarn codepush:deploy` は `./scripts/deploy_codepush` というシェルスクリプトに切り出してみました。

```bash
#!/bin/bash -ex

if [ $# -ne 1 ]; then
  echo 'Error: Missing argument' 1>&2
  echo "Usage: ${0} DEPLOYMENT_NAME" 1>&2
  exit 1
fi

if [ ! -f "TARGET_BINARY_VERSION" ]; then
  echo 'The file TARGET_BINARY_VERSION is not found' 1>&2
  echo 'The file is used for specifying `--target-binary-version` of `appcenter codepush release-react` command' 1>&2
  exit 1
fi

appcenter codepush release-react \
  -a OurOrg/AwesomeApp \
  --deployment-name "${1}" \
  --target-binary-version `cat TARGET_BINARY_VERSION | egrep -v '^#'`

exit $?
```

ここでは `--target-binary-option` というオプションを指定しています。これはネイティブモジュールの追加・修正があった場合、CodePush だけではうまく変更が適用できないので、Semantic Versioning でバイナリリリースのバージョンを指定するという機能です。

`TARGET_BINARY_VERSION` というファイルでバージョンを指定しています。

```
# The content of this file is specified as `--target-binary-version` in the deploy script `./scripts/deploy_codepush`.
# When you introduced a new native module, please release the binary first and update this file.
# You can specify it by following Semantic Versioning.
# ref: https://docs.microsoft.com/en-us/appcenter/distribution/codepush/cli#target-binary-version-parameter
1.2.0
```

本来は Semantic Versioning で `1.2.x` や `~1.2.0` といった指定ができるはずですが、今は不具合があるので `1.2.0` のような固定バージョンを指定する必要があります。以下の Pull Request がリリースされれば解消されるはずです。

* [Fix validation of `--target-binary-version`](https://github.com/Microsoft/appcenter-cli/pull/331)

なお、現在のプロジェクトでは TypeScript を使っているので、実際には事前に `yarn build` コマンドで JS ファイルへのトランスパイルを実行しています。

## CircleCI での自動デプロイの設定

CircleCI 2.0 の Workflow を使っています。

```yaml
version: 2
jobs:
# ...
  deploy_to_codepush_release:
    docker:
      - image: circleci/node:8.7.0
    steps:
      - checkout
      - restore_cache:
          keys:
            - v1-{{ arch }}-{{ .Branch }}-{{ checksum "yarn.lock" }}
            - v1-{{ arch }}
      - run:
          name: Install dependencies
          command: 'yarn install'
      - run:
          name: Deploy to CodePush
          command: 'yarn codepush:login && yarn codepush:deploy Release'

  deploy_to_codepush_production:
    docker:
      - image: circleci/node:8.7.0
    steps:
      - checkout
      - restore_cache:
          keys:
            - v1-{{ arch }}-{{ .Branch }}-{{ checksum "yarn.lock" }}
            - v1-{{ arch }}
      - run:
          name: Install dependencies
          command: 'yarn install'
      - run:
          name: Deploy to CodePush
          command: 'yarn codepush:login && yarn codepush:deploy Production'

workflows:
  version: 2
  build-test-deploy:
    jobs:
      - bundle_dependencies
      - test:
          requires:
            - bundle_dependencies
      - deploy_to_codepush_release:
          requires:
            - test
          filters:
            branches:
              only: /^release\/codepush\/.*/
      - deploy_to_codepush_production:
          requires:
            - test
          filters:
            branches:
              only: 'deploy/codepush'
```

あとは `release/codepush/v*` といった名前のブランチを作ればリリース用の JS Bundle がデプロイされ、QA を通れば `deploy/codepush` にマージすることでユーザ向けにデプロイされます。

あとは開発に集中して高速のリリースを回して行きましょう！
