---
title: "Kubernetes The Hard Way をやってみた"
date: 2018-12-30T01:25:45+09:00
---
冬休みに入ったので、前からやってみたいと思っていた [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) をやってみました。という日記です。

<!--more-->

## 何故やったか

4 月に SRE チームに異動してから 8 ヶ月ほど経ち、その感 Kubernetes クラスタの構築・運用・アプリケーションの移行などあらゆることをして来ましたが、未だに Kubernetes わかってる感が薄いので、もっと細かいところまで理解しようというモチベーションでやってみました。

## 手順

ほぼ 100% [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) に書いてある手順通りです。GCP を使って、複数のサーバでの作業が必要な時は tmux の `set synchronize-panes on` を使って (実は初めて使った)。

## 所要時間

合計 3 時間弱でした。思ったほど時間がかからなかったので、別に普通の土日でもできますね。所要時間は個人 Slack でスレッド内に進捗や気になった点をメモしながらだったので、それで計測しています。

* Prerequisites ~ Provisioning a CA and Generating TLS Certificates
  * 55 分
  * Provisioning a CA and Generating TLS Certificates はひたすらいろんな鍵を生成するばかりで退屈だった
* Generating Kubernetes Configuration Files for Authentication ~ Bootstrapping the Kubernetes Control Plane
  * 50 分
  * Bootstrapping the Kubernetes Control Plane は全体で一番時間がかかったように思う
* Bootstrapping the Kubernetes Worker Nodes ~ Cleaning Up
  * 55 分
  * 実際に Nginx が動いたりするとそこそこ嬉しかった

なお、個人の GCP アカウントは以前から持っていたので、そこの時間は含まれません。作業に使用する tmux も普段から使っており、そのインストール時間も含まれません。

## 感想

* 思ったほど Hard ではない
  * 基本的にはコマンドをコピペするだけで動くので、ミスしなければ誰がやっても普通に動くと思う
  * むしろ無意識的にやってもできそうだが、それだとさすがに意味がないので、コマンドだったり設定ファイルの中身はじっくり眺めながら進めた方が良い
* 対象者は Kubernetes の運用やその上での開発をある程度やっている人か
  * コピペだけでもできるので、Kubernetes を全く知らない人でもできるとは思うが、さすがにそれで何かを得るのは難しいのではと思った
* これをやっただけで「これ」と言える何かを得るのは簡単ではないかも
  * 全体的なイメージはなんとなく持つことができる
  * やってみても、Kubernetes のセットアップ方法は様々なので、どこまでが普遍的な知識なのはわかりづらい
    * 今回は kube-proxy を systemd で起動したけど、普段仕事で使っているクラスタでは DaemonSet で起動してるはずで、それによって何が違ってくるんだろう、とか
  * 疑問を元に何かを調べるためのきっかけとしては良いかもしれない
