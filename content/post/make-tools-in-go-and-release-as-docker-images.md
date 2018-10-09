---
title: "CLI ツールを Go で書いて Docker イメージとしてリリースする"
date: 2018-10-09T23:38:11+09:00
---
最近ようやく開発ツールとして Docker が手に馴染んできたので、タイトルの件も含めていくつか雑多に書きます。

<!--more-->

## CLI ツールを Go で書いて Docker イメージとしてリリースする

コマンドラインツールを Go で書く、というのは以前からやっていて、主な理由としては「クロスコンパイルができるのでバイナリリリースが簡単」というのがありました。便利なので、クロスコンパイルから GitHub へのリリースを一発でやってくれるラッパーツールを書いたこともありました (一応動くものの、開発は非常に中途半端なところで止まってますが)

* [gox して ghr するツール ggallin 作った](https://qiita.com/yuya_takeyama/items/ac200058f9a27a5db12f)

その後、2017 年に入って Docker で Multi-Stage Builds という機能が実装されてからは、`Dockerfile` 内の build ステージで `go build` したバイナリを最終的なステージから `COPY --from=build` して使う、ということもやってきました。

* [Use multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)

この `COPY --from` ですが、ドキュメントをよく見ると `COPY --from=nginx:latest` などとすることで、外部のイメージも stage として利用することができると書いてあります。

これを利用すると、`Dockerfile` 内で必要なツールはこんな感じにインストールすることができるようになります。 (例は前の記事で紹介している [guruguru-cache](/post/guruguru-cache/) をインストールするもの)

```
COPY --from=yuyat/guruguru-cache /usr/local/bin/guruguru-cache /usr/local/bin
```

guruguru-cache は Go で書かれていてシングルバイナリとしてビルドされているので、このように `$PATH` の通ったところに `COPY` してくるだけで使えるようになります。

ただし、動的リンクされている場合は動かないことがあるので、静的リンクにする必要があります。以下の記事を参考にしています。

* [Totally static Go builds](http://blog.wrouesnel.com/articles/Totally%20static%20Go%20builds/)

以前に [Rust で書いたツール](https://github.com/yuya-takeyama/circle-gh-tee) も同じやり方で手元で使ってたりするんですが、この時はその辺に気を使っていたわけではないので、たまたま動いているだけかもしれません。 (ビルドと実行が同じベースイメージで行われていれば普通に動くことも多い)

最近 Webpacker 用の `Dockerfile` で、ruby のイメージの中から `COPY --from=node` で `node` のバイナリを直接引っ張ってきているのをちょいちょい見ますが、Quipper で一番 Docker に詳しい [@mtsmfm](http://twitter.com/mtsmfm) さんに聞いたところ、「多分 ruby と node のベースイメージが近いからたまたま動いているだけで、手元で使うのはいいけど本番ではやるべきではないですね」とのような意見をもらって、「なるほど、確かに〜」と思ったのでした。 (確かにどちらも `buildpack-deps:stretch` がベース。バージョンによっても違うかもですが)

* [ruby](https://github.com/docker-library/ruby/blob/ccacdf5eb9e69b6f249a890c87621679410e7d74/2.5/stretch/Dockerfile)
* [node](https://github.com/nodejs/docker-node/blob/11d4e7fb83a52801e177a08c12eeacaf41498a54/10/stretch/Dockerfile)

あと言うまでもないとは思いますが、これはあくまでも `docker build` 内で実行する開発ツール的なやつに有効なテクニックで、サーバやミドルウェアは素直で別コンテナで動かしてネットワークを通じてやり取りするのが良いでしょう (Apache と MySQL の両方を動かすようなイメージを作るべきではない)

## Docker Hub よりも Docker Cloud

というわけで最近は前よりも Docker イメージを作ることが増えて、ちょっと前までは Docker Hub を使っていました。

でもビルドの進捗がよくわからんなー、と思って社内の Slack で文句を言っていたところ、これまた [@mtsmfm](http://twitter.com/mtsmfm) さんから「進捗は Docker Cloud の方がわかりやすい」ということだったのでそちらを使い始めました。

名前はなんとなく知っていたものの、そこで初めて知ったのはどちらも Docker, Inc. が運営するサービスなんですね。しかも内部的にリポジトリのデータは共有されており、`docker push` すると両方に同じイメージが表れるという不思議な作り。Docker Hub だと他人の public なイメージも閲覧できるのに対して、Docker Cloud は基本的に自分か所属する組織のイメージ以外は見えないので、Hub としての機能は持ってないようです。

使ってみると UI 以外にも Automated Build が少しいい感じになっていて、Git の tag は `v1.2.3` だったら Docker イメージの tag は `1.2.3` というように先頭の v を取る、みたいなことも簡単にできるので便利です。
