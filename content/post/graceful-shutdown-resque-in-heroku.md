+++
date = "2017-04-10T02:02:59+09:00"
title = "Heroku で Resque を Graceful Shutdown する"

+++
Heroku で Resque を動かす場合、何も考えないでセットアップすると、デプロイによるプロセスの再起動時や、Dyno のスケールダウン時に Worker プロセスが強制終了され、`Resque::DirtyExit` としてエラーになってしまいます。

これを避けるために正しく **Graceful Shutdown** する方法について調べてみました。

<!--more-->

## 前提とするバージョン

* Ruby 2.4.1
* Rails 5.0.2
* Resque 1.27.2

## Graceful Shutdown とは (この記事における定義)

厳密な定義を知っているわけではないですが、この記事では以下のような定義で話を進めます。

* Graceful Shutdown: 中途半端なデータが残らないよう、行儀よくプロセスを終了する

さらにこれを細分化して、この記事では以下のように呼ぶことにします。これらは私の造語で、全く一般的でない呼び方です。

  * Halfway Graceful Shutdown: やりかけの処理に完了処理を行ってから全体の途中で処理を終了する
  * Entire Graceful Shutdown: すべての処理が完了してから終了する

例えば、100 件のデータを処理する Worker があり、50 件目を行っている途中で終了のシグナルを受け取った場合、その 50 件目まで正しくやりきったタイミングで終了するのが **Halfway Graceful Shutdown**。

そして、50 件目の段階で終了のシグナルを受け取っても、100 件すべてをやりきった上で終了するのが **Entire Graceful Shutdown** となります。

これに対して、いきなり終了してしまうことをここでは **Immediate Shutdown** と呼ぶことにします。
これも一般的な用語なのかはわからないですが、検索した感じではこういう用語を使っているドキュメントもいくつか見つかりました。

## Resque における Graceful Shutdown

Resque では Graceful Shutdown を行う方法として、QUIT シグナルによる方法が提供されています。

* [resque/resque: Signals](https://github.com/resque/resque#signals)

つまり Resque のプロセス ID に対して以下のようなコマンドを実行すれば良いことになります。

```
$ kill -QUIT PID
```

なお、`QUIT` を受け取った時の挙動は、この記事の定義で言えば Entire Graceful Shutdown です。

## Heroku で Graceful Shutdown を行う際の問題点

Heroku のような PaaS では任意の UNIX プロセスに対して任意のシグナルを送ることはできないことが一般的でしょう。 (少なくとも Heorku ではできません)

それでいて、以下のような場合は `TERM` シグナルが送信されます。

* デプロイの実行による Dyno の再起動
* Dyno のスケールダウン

Heroku ではこれらの場合、まずは `TERM` シグナルが送られ、それでもプロセスが残っている場合は 30 秒後に `KILL` シグナルが送られて強制終了となります。

* [Heroku Error Codes: R12 - Exit Timeout](https://devcenter.heroku.com/articles/error-codes#r12-exit-timeout)

そして `TERM` が送られた場合の Resque のデフォルトの挙動は Immediate Shutdown です。

## Heroku で Resque を Graceful Shutdown する

実は [Resque の README](https://github.com/resque/resque#resque) や [Heroku のドキュメント](https://devcenter.heroku.com/articles/queuing-ruby-resque#process-options)にもいろいろ説明はあるんですが、以下のような理由で、一読しただけ正しく理解するのは難しいと思いました。

* Resque の `master` ブランチの README に書いてある内容の一部は現状の最新版 (`v1.27.2`) では使えないのでややこしい
  * [`RESQUE_PRE_SHUTDOWN_TIMEOUT`](https://github.com/resque/resque/pull/1514) というオプションはまだリリースされていない
* Resque のドキュメントには記載されていないが有用なオプションがある
  * Entire Gracful Shutdown を行う上で必要な [GRACEFUL_TERM](https://github.com/resque/resque/pull/1007) というオプション
* Heroku のドキュメントは Resque に関する情報が一部古いか間違っている
  * 少なくとも Rails 5.0.2 では `rake resque:work` ではなく `rake environment resque:work` としないとエラーで Worker が起動できない
  * SIGTERM から 10 秒後に SIGKILL、と言う説明があるが正しくは 30 秒

Resque の `GRACEFUL_TERM` についてはプルリクエストを送ればいいとして、Heroku のドキュメントの問題についてはどこに報告すべきかよくわからないので知ってる人は教えてください。

### Halfway Graceful Shutdown

これは実は以下の記事でほぼ説明されています。

* [HerokuでResqueを使うときに優雅に再起動する](http://webtech-walker.com/archive/2012/09/resque_heroku.html)

ただしこれも 4 年半ほど前の記事なので、現時点では以下のようにする必要があるでしょう。

#### Worker の実装 

`perform` メソッドの中で `Resque::TermException` を `rescue` し、完了処理を実装します。

これについては上記の記事通りで問題ありません。

#### Procfile

以下のようにします。

```
resque: QUEUE=* TERM_CHILD=1 RESQUE_TERM_TIMEOUT=30 bundle exec rake environment resque:work
```

現在のバージョンでは `QUEUE` の指定が必須です。 (もちろん必要に応じて変更する)

`TERM_CHILD` をセットすると `TERM` シグナルを受け取った時の挙動が変わります。

デフォルトでは `TERM` を受け取ると容赦なく Worker である子プロセスに `KILL` を送り Immediate Shutdown となります。

これに対して `TERM_CHILD` をセットした場合は以下のような流れになります。

1. Worker である子プロセスに対して `TERM` を送る
  * `Resque::TermException` が `raise` される
1. `TERM_TIMEOUT` に指定した秒数の間、子プロセスが終了するのを待つ
1. それでも子プロセスが残っていれば今度は `KILL` を送って強制終了する

前述の Heroku の制限のため、`RESQUE_TERM_TIMEOUT` は 30 秒以下にする必要があります。 (それ以上を指定しても結局 Heroku から `KILL` される)

### `RESQUE_PRE_SHUTDOWN_TIMEOUT` について

前述の通り未リリースではあるものの、`master` ブランチに入っていてそのうち使えるようになると思われるこのオプションについても調べてみました。

これは `TERM_CHILD` をセットしている場合のみに有効なオプションで、子プロセスに `TERM` を送る前の待ち時間を秒数で指定することができます。

つまりこれは `Halfway Graceful Shutdown` と `Entire Graceful Shutdown` 複合です。

例えば `Procfile` を以下のようにした場合、`TERM` を受け取った後の挙動は以下のようになります。

```
resque: QUEUE=* TERM_CHILD=1 RESQUE_PRE_SHUTDOWN_TIMEOUT=20 RESQUE_TERM_TIMEOUT=10 bundle exec rake environment resque:work
```

1. 子プロセスの処理が完了するまで 20 秒間待つ
  * この 20 秒間に処理が全て完了すれば Entire Graceful Shutdown
1. 子プロセスに `TERM` を送る
  * `Resque::TermException` が `raise` される
  * この場合は Halfway Graceful Shutdown
1. 子プロセスが終了するまでさらに 10 秒間待つ
1. それでも子プロセスが残っていれば今度は `KILL` を送って強制終了する

具体的な秒数については実際に動いている Worker の実行時間を元にチューニングするのが良いでしょう。

いずれにせよ `RESQUE_PRE_SHUTDOWN_TIMEOUT` と `RESQUE_TERM_TIMEOUT` の合計は 30 以下にする必要があります。


### Entire Graceful Shutdown

これについては説明されている記事が見つけられなかったので、自分で実際に Heroku で動かしながらわかったことを元に書きます。

#### Worker の実装 

Halfway Graceful Shutdown を行わないのであれば、`Resque::TermException` の `rescue` は不要です。

#### Procfile

以下のようにします。

```
resque: QUEUE=* GRACEFUL_TERM=1 bundle exec rake environment resque:work
```

この場合は `TERM_CHILD` を指定してはいけません。指定した場合、`GRACEFUL_TERM` の設定が[無効果されます](https://github.com/resque/resque/blob/v1.27.2/lib/resque/worker.rb#L866)。

#### `GRACEFUL_TERM` とは

これは `TERM` を受け取った時の処理を (Entire) Graceful Shutdown にするというものです。

前述の通り今の所ドキュメント化されていないようです。

## どちらの方法を選ぶべきか

基本的には Halfway Graceful Shutdown を選ぶべきでしょう。

Heroku では 30 秒制限がある以上、Entire Graceful Shutdown を選ぶとしても、Worker は全て 30 秒で完了できなくてはなりません。通常 1 分かかる処理があったとして、20 秒時点で `TERM` を受け取った場合、Entire Graceful Shutdown では最後の 10 秒分の処理を残して強制終了されてしまうからです。

30 秒間に全てを終えることはできなくても、今やりかけの分だけ綺麗に完了させることはできるかもしれません。

ただし、Halfway Graceful Shutdown を行うには、前述の通り `Resque::TermException` を正しく `rescue` するような実装を行わなければなりません。

全ての Worker が 30 秒もかからないような場合であれば、その実装をサボって Entire Graceful Shutdown で妥協するのも良いでしょう。

## 関連するソースの読み方

ここに書いてあることは基本的には `Resque::Worker` だけ読めば全て書いてあります。

* [resque/lib/resque/worker.rb](https://github.com/resque/resque/blob/master/lib/resque/worker.rb)

Resque は想像していたよりは意外と重厚な感じではなく、比較的読みやすい分量だと思いました。UNIX プロセスについての勉強としても面白いと思うのでオススメです。
