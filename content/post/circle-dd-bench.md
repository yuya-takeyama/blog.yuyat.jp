---
title: "CircleCI 上でのコマンドの実行時間を Datadog に残す circle-dd-bench 作った"
date: 2018-12-25T23:30:00+09:00
---
この記事は [CircleCI Advent Calendar 2018](https://qiita.com/advent-calendar/2018/circleci) 7 日目の記事です。今日は 12 月 25 日ですが、自分の担当分をサボっていたわけではなく、週末作ったツールについて今朝方ツイートしたところ、CircleCI Japan の中の方に「アドベントカレンダーの7日目が空いてしまったのてすがもしよければ」と誘われて書いている次第です。

<blockquote class="twitter-tweet" data-lang="en"><p lang="ja" dir="ltr">CircleCI でコマンドごとの実行時間を Datadog に記録するためのコマンドを作った <a href="https://t.co/TojoKhOQ1f">https://t.co/TojoKhOQ1f</a></p>&mdash; Yuya Takeyama (@yuya_takeyama) <a href="https://twitter.com/yuya_takeyama/status/1077375699969728514?ref_src=twsrc%5Etfw">December 25, 2018</a></blockquote>
<script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

というわけで早速この [circle-dd-bench](https://github.com/yuya-takeyama/circle-dd-bench) というツールについて紹介します。

<!--more-->

## これは何？

これは CircleCI 内でコマンドを実行する際、ラッパーとして使用することで、実行時間を Datadog にメトリックとして記録するというものです。

例えばこのようなコマンドを実行していた場合

```
docker build . -t burzum
```

このように書き換えると使用できます。

```
circle-dd-bench --tag command:docker-build --tag product:burzum -- docker build . -t burzum
```

実際には `DATADOG_API_KEY` という環境変数に Datadog の API Key を持たせておく必要があります。

`--tag` は必須ではなく、デフォルトで CircleCI の以下のような環境変数がタグとして付与されます。

* `CIRCLE_PROJECT_USERNAME`
* `CIRCLE_PROJECT_REPONAME`
* `CIRCLE_BRANCH`
* `CIRCLE_JOB`

## 使ってみた

実際にこの `circle-dd-bench` を使って記録したメトリックを元に Datadog 上で作成したダッシュボードがこちらです。ここではあらゆるサービスの `docker build` の実行時間を計測しています。

<img src="/images/circle-dd-bench/datadog.png" width="1156" height="322">

まだ CircleCI の config に組み込む Pull Request を出して、そのブランチ上で 2-3 回実行しただけで、`Dockerfile` の最適化を行なってはいないため、サービスごとの `docker build` にかかる時間の変化は誤差のみです。ですが、どのサービスの `docker build` に時間がかかっているかは一目瞭然なので、それから最適化に着手していけばいいことになります。

## モチベーション

一言でいうと、CircleCI の実行時間を最適化するにあたって、各コマンド単位でどれぐらい時間がかかっているのかを定点観測しておきたかったためです。

私が社員として所属する Quipper ではマイクロサービス化を進めるにあたって、かつては 1 サービス 1 リポジトリだったものを、一つの Monorepo に集約しています。背景については以下の記事やスライドをご覧ください。

* [Kubernetes導入で実現したい世界とその先にあるMicroservices](https://quipper.hatenablog.com/entry/future-with-kubernetes)
* [How Quipper Works with CircleCI](https://speakerdeck.com/yuyatakeyama/how-quipper-works-with-circleci)

特にみていただきたいのは後者のスライドに含まれる以下の [CircleCI の Workflow のスクリーンショット](https://speakerdeck.com/yuyatakeyama/how-quipper-works-with-circleci?slide=14) です。

<img src="/images/circle-dd-bench/workflow.png" width="1126" height="655">

たくさんのサービスの Docker Build やユニットテストが並列して実行されるため、このスクリーンショットを作成した時点で 83 もの Job が Workflow 内に含まれます (その後もう少し増えています)

この図を踏まえてもう少し背景を説明すると、以下のような理由が挙げられます。

### CircleCI の Insights が Workflow では役に立たない

CircleCI には Insights という機能があり、Job の実行時間の履歴をグラフとしてビジュアライズする機能があります。

これは CircleCI 1.0 時代には大変有用でしたが、CircleCI 2.0 の Workflow を使っている場合はそうではありません。質の異なる複数の Job が一様にグラフ化されるため、一見して役に立てるのはこんなんです。

なので別のアプローチでビジュアライズを試みる必要があります。

### 同じコマンドでも実行時間にばらつきがある

ここでは特に `docker build` を念頭におきますが、`docker build` はキャッシュの有無であったり、キャッシュがあるにしてもどの layer までのキャッシュが使えるかといった場合によって実行時間はまちまちです。最適化の結果ベストケースでの実行時間は速くなっても、キャッシュが効く確率が低く、全体としての実行時間は遅くなる、ということもあるでしょう。

そういった状況を正しく判断できるようにするには、継続的に実行時間を残しておき、ビジュアライズしておくと Fact Based に判断しやすいでしょう。

### Job 単位での計測ではうまくいかないケースに対応したい

先に掲載した Workflow は、実際は変更を検知したサービスに対してのみユニットテストや `docker build` の実行を行なっています。変更がなかった場合は最後のビルドを使いまわしています。

その場合、`docker build` を実行したら数分かかるのに、スキップした場合は数秒で終わったりと、またばらつきが生まれてしまいます。なので、単純に Job 単位での実行時間を記録するのは適切でなくなります。

`circle-dd-bench` を使ったアプローチでは、`docker build` を実行した時のみ計測・記録が行われるので、そういったばらつきを無視することができます。

## まとめ

[circle-dd-bench](https://github.com/yuya-takeyama/circle-dd-bench) を使うと Fact Based に CircleCI の Workflow を最適化していけるかもしれません。同じような問題を抱えている方は是非使ってみてください。

<iframe width="560" height="315" src="https://www.youtube.com/embed/WJBeFy3VcgY" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
