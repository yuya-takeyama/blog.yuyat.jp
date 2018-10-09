---
title: "docker build 内の bundle install を最適化するために guruguru-cache というツールを作った"
date: 2018-10-09T01:10:00+09:00
---
作りました。

* [yuya-takeyama/guruguru-cache](https://github.com/yuya-takeyama/guruguru-cache)

<!--more-->

## 解決したい問題

Quipper では開発プラットフォームが Deis (OSS の Heroku クローン) から割と素な感じの Kubernetes へと変わったので、元々は Buildpack で行なっていたコンテナイメージのビルドはシェルスクリプト内で `docker build` を直接実行して行うようになりました。

* [Kubernetes導入で実現したい世界とその先にあるMicroservices](https://quipper.hatenablog.com/entry/future-with-kubernetes)

Monorepo なので、Pull Request を出したりマージすると変更のあったサービスの Docker Image のビルドが一気に走るのですが、並列とはいえキューがたまりがちになってきたので、実行時間が気になり始めました。

### `bundle install` が長い

特に気になるのがこれです。Quipper の場合 Ruby で書かれたアプリが多いので主に Bundler ですが、Node.js の Yarn 等でも同様の問題があります。

この問題に対するよく知られた対処として、「`Gemfile`/`Gemfile.lock` を先に `ADD`/`COPY` して `bundle install` を実行したあとでアプリ全体を `ADD`/`COPY` する」というものがあります。
(以前は Ruby のオフィシャルイメージの中の `onbuild` タグがついたものが同じようなことをしてくれましたが[いつの間にか deprecate されていた](https://github.com/docker-library/official-images/issues/2076)ようです)

* [Docker で bundle install を爆速にする](https://qiita.com/kaiinui/items/5ec52437d114e364b7f0)

こうすることで、`Gemfile`/`Gemfile.lock` 以外のファイルに更新が起こった時点で Docker のレイヤーキャッシュが無効になり、`bundle install` がゼロからになってしまう問題を避けられます。

ですが、この場合も結局 `Gemfile` に 1 gem 追加しただけでも `bundle install` は最初から実行されて、特に `nokogiri` のようなネイティブ拡張を含む gem のビルドに時間を取られてしまうことには変わりありません。

これかを解決するには、`docker build` 時に `bundle install` したディレクトリ全体をキャッシュとして保持しておき、次回以降のビルドに引き継ぐ必要があります。

## guruguru-cache

そこで作ったのが guruguru-cache です。

* [yuya-takeyama/guruguru-cache](https://github.com/yuya-takeyama/guruguru-cache)

[CircleCI 2.0 のキャッシュシステム](https://circleci.com/docs/2.0/caching/)がシンプルで好きだったので、これと似たようなことがコマンドでできれば良いなと思って作りました。**Circle** CI 由来なのでぐるぐるです。[乃木坂46のデビューシングル](https://www.youtube.com/watch?v=Ypx_A6No600)や[ジャーマンロックバンド](https://en.wikipedia.org/wiki/Guru_Guru)は関係ありません。

### 必要なもの

キャッシュファイルは S3 に保存するため、S3 バケットと、そバケットにアクセスできる IAM User 及びアクセスキーが必要です。現状は環境変数でしか渡せないので、以下の値を用意する必要があります。

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_REGION`

また、必須ではありませんが、[Object Expiration](https://docs.aws.amazon.com/AmazonS3/latest/dev/lifecycle-expire-general-considerations.html) の設定をしておくと良いでしょう。

### インストール

現状リリース済みのバイナリは用意していないので、`go get` で自前ビルドするか、`docker build` 用であれば latest の Docker イメージからコピーしてくるのが簡単です。

```dockerfile
# In Dockerfile
COPY --from=yuyat/guruguru-cache /usr/local/bin/guruguru-cache /usr/local/bin
```

### キャッシュの保存


```
$ guruguru-cache store [flags] [cache key] [paths...]

Flags:
  -h, --help               help for store
      --s3-bucket string   S3 bucket to upload
```

第一引数にキャッシュキーを指定し、第二引数以降にはキャッシュ対象のパスを複数指定できます。

```
$ guruguru-cache store --s3-bucket=example-cache \
  'gem-v1-{{ arch }}-{{ checksum "Gemfile.lock" }}' \
  vendor/bundle
```

キャッシュキーには CircleCI と同様のテンプレート記法が使えます。テンプレート記法についてはあとで別途説明します。

### キャッシュの復元


```
$ guruguru-cache restore [flags] [cache keys...]

Flags:
  -h, --help               help for restore
      --s3-bucket string   S3 bucket to upload
```

キャッシュキーを複数指定することができます。順番にキャッシュを前方一致で探索し、見つかるまで次のキーにフォールバックしていきます。キャッシュが見つからなければ何もせず終了します。

```
$ guruguru-cache restore --s3-bucket=example-cache \
  'gem-v1-{{ arch }}-{{ checksum "Gemfile.lock" }}' \
  'gem-v1-{{ arch }}'
```

この例ではまず `Gemfile.lock` のチェックサムが一致するキャッシュを探索します。これが見つかった場合、通常は gem が過不足なくキャッシュから復元されるので、`bundle install` は一瞬で終わるはずです。 (もちろん実装依存ですが)

チェックサムが一致するキャッシュが見つからなかった場合、2 番目の `gem-v1-{{ arch }}` にフォールバックします。複数見つかった場合は作成日時が一番新しいものを取得します。この辺は CircleCI と同様の挙動にしたつもりです。

### キャッシュキーのテンプレート

キャッシュキーには以下のテンプレート記法が使えます。まんま CircleCI です。

* `{{ checksum "FILEPATH" }}`: ファイルの MD5 チェックサム
* `{{ arch }}`: CPU アーキテクチャ
* `{{ epoch }}`: UNIX タイムスタンプ
* `{{ .Environment.FOO }}`: 環境変数

`{{ .Branch }}` や `{{ .Revision }}` のような CircleCI 固有の環境変数に依存したものはありません。CI 基盤で適宜取得して `docker build` 時に `--build-arg` として渡す、等する必要があります。

## デモ

CircleCI 内で `docker build` を行う例を以下に用意してみました。ファイルとして見るべきものは以下の 2 つです。

* [Dockerfile](https://github.com/yuya-takeyama/guruguru-cache-circleci-example/blob/master/Dockerfile)
  * キャッシュの復元 -> `bundle install` -> キャッシュの保存となっていることがわかると思います
  * CircleCI のジョブ本体のコンテナと Remote Docker とでキャッシュを共有できたら良いかなと思いましたが、実行してみたときは CPU アーキテクチャの微妙な違いによってうまく共有できませんでした
    * https://circleci.com/gh/yuya-takeyama/guruguru-cache-circleci-example/4
    * 現実のケースではテストの実行用と本番環境での実行用とでは必要な gem が微妙に異なると思うので、キャッシュを共有できてもそんなに嬉しくない気もします
* [.circleci/config.yml](https://github.com/yuya-takeyama/guruguru-cache-circleci-example/blob/master/.circleci/config.yml)
  * `guruguru-cache` の実行に必要な環境変数を `--build-arg` として渡しています
  * CircleCI のジョブ本体のコンテナと Remote Docker とでキャッシュを共有できたら良いかなと思いましたが、実行してみたときは CPU アーキテクチャの微妙な違いによってうまく共有できませんでした
    * https://circleci.com/gh/yuya-takeyama/guruguru-cache-circleci-example/4
    * 現実のケースではテストの実行用と本番環境での実行用とでは必要な gem が微妙に異なると思うので、キャッシュを共有できてもそんなに嬉しくない気もします

### ビルド時間の計測

はじめに、初回のキャッシュなしの状態です。キャッシュを復元・保存するロジックは既に入っていますが、初回なので当然キャッシュがない状態です。コードはほぼ `rails new` した直後のものです。

* https://circleci.com/gh/yuya-takeyama/guruguru-cache-circleci-example/4
  * `docker build`: 02:01
    * `guruguru-cache restore`: 約 1 秒
    * `guruguru-cache store`: 約 10 秒

次に、ネイティブ拡張を含む[いくつかの gem を追加](https://github.com/yuya-takeyama/guruguru-cache-circleci-example/commit/bf53270f59062927496ded5f8304d76c34b8d4bc)した状態で計測してみます。

* https://circleci.com/gh/yuya-takeyama/guruguru-cache-circleci-example/5
  * `docker build`: 01:34
    * `guruguru-cache restore`: 約 15 秒
    * `guruguru-cache store`: 約 20 秒
  * ほとんどの gem はキャッシュから復元されるので、差分だけのインストールが行われていることがわかります
  * `libv8` や `mini_racer` 等の、ビルドが必要な gem がいくつか含まれていても、全体としては速くなっていることがわかります

そして、同じ gem を追加した状態だが、`guruguru-cache` を一切使わないものです。

* https://circleci.com/gh/yuya-takeyama/guruguru-cache-circleci-example/6
  * `docker build`: 02:12
    * `guruguru-cache` にかかる時間はなし

というわけで、これを見る限りでは `guruguru-cache` を使うメリットはあると言えそうです。

実際は `nokogiri` のようなビルドに時間のかかる gem がどれだけ含まれるのかにも寄るし、レイヤーキャッシュによる `bundle install` 自体のインストールがどれだけスキップされる場合だったり、レイヤーキャッシュはないが `guruguru-cache` のキャッシュはそのまま存在してキャッシュの保存はスキップされるケースなど、色々パターンがあるので、もう少し長い目で計測・観察が必要そうです。

## 今後改善したいポイント

### キャッシュのネームスペース

単一のバケットに複数リポジトリのキャッシュを格納できるよう、ネームスペースの指定ができてはどうかと思っています。S3 上はパスの prefix になるだけなので、キャッシュキー自体に含めてもいいかもしれませんが、この後の設定ファイルも込みでやると便利かもしれません。

### 設定ファイルへの対応

CircleCI のキャッシュでは、ビルドの設定ファイルのあちこちにキャッシュキーが散らばるので、一斉にキーを変更する必要があるときに煩雑になってしまう問題があると感じています。

なので、`guruguru-cache` 用の設定ファイル内にキーの情報をプリセットとして持たせておいて、コマンドからはそのプリセットを指定するだけにできると良いのではないかと考えています。イメージ的には以下のような感じ。

```yml
# 設定ファイル
s3-bucket: example-cache
namespace: my-blog-app
presets:
  gem:
    store:
      key: gem-v1-{{ arch }}-{{ checksum "Gemfile.lock" }}
      paths:
        - vendor/bundle
    restore:
      keys:
        - gem-v1-{{ arch }}-{{ checksum "Gemfile.lock" }}
        - gem-v1-{{ arch }}
  npm:
    store:
      key: npm-v1-{{ arch }}-{{ checksum "yarn.lock" }}
      paths:
        - node_modules
    restore:
      keys:
        - npm-v1-{{ arch }}-{{ checksum "yarn.lock" }}
        - npm-v1-{{ arch }}
```

```dockerfile
# Dockerfile
RUN guruguru-cache restore --preset gem
RUN bundle install --path=vendor/bundle
RUN guruguru-cache store --preset gem

RUN guruguru-cache restore --preset npm
RUN yarn install
RUN guruguru-cache store --preset npm
```

### アップロード・ダウンロードの高速化

全然検証してませんが、RANGE リクエストを並列化させれば高速化できるんじゃないかと思っています。

### ファイル属性の維持

キャッシュ展開時のファイル属性 (更新日時とか) は今のところ適当ですが、ちゃんと保持した方が良いケースが多いと思うのでちゃんとしたいです。
