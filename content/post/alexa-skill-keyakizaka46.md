---
title: "欅坂46 の情報が聞ける Alexa Skill を作った"
date: 2017-12-31T20:30:19+09:00
---
なかなか来てくれなかった [Amazon Echo Dot](http://amzn.to/2zT3Hxt) の招待がようやく来たので、早速買ってみました。

ある日、テレビでたまたま、平井堅のノンフィクションという曲に合わせて踊る平手友梨奈さんを観て衝撃を受けて以来、欅坂46 の事ばっかり考えているし CD や雑誌をすごい勢いで買って [COUNTDOWN JAPAN](http://countdownjapan.jp/) ではライブも観て来ました。[避雷針](https://www.youtube.com/watch?v=8y14n7mEVlo)すごく良かったです。

というわけで題材は欅坂46 です。

<!--more-->

## 作ったもの

今のところ 2 つの機能があります。

* 特定の日にちのスケジュールを読み上げる
* 特定の日にちまたは月が誕生日のメンバーを読み上げる。

<iframe width="560" height="315" src="https://www.youtube.com/embed/fAYt8XUeUFY" frameborder="0" gesture="media" allow="encrypted-media" allowfullscreen></iframe>

なお、データについては[欅坂46公式サイト](http://www.keyakizaka46.com/)から勝手にスクレイピングしているので、公式のストア (?) には登録していないですしそのつもりもありません。ベータテスト機能で自分をテスターとして登録しています。

## ソースコード

GitHub に MIT License で公開しています。

* [yuya-takeyama/alexa-keyakizaka-info](https://github.com/yuya-takeyama/alexa-keyakizaka-info)

また、Alexa Skill の Intent とかの設定は以下のようになっています。

* [欅坂情報 Alexa Skill の Intent とかの設定](https://gist.github.com/yuya-takeyama/c05d131d63865aa952eaa37470dc400f)

## 構成

* 言語: TypeScript
* 動作環境: AWS Lambda (Node.js 6.10)
* 主なライブラリ
  * [alexa-sdk](https://www.npmjs.com/package/alexa-sdk)
  * [axios](https://www.npmjs.com/package/axios)
  * [jsdom](https://github.com/tmpvar/jsdom)

## 仕組み

先にも書いた通り、スケジュール・誕生日のいずれも公式サイトのスケジュールページからスクレイピングしてます。

誕生日については、事前にデータだけ用意をしておけばスクレイピングは必要ないですし、メンバー名から誕生日を読み上げる事も実装できるので、そういう感じに作り変えるかもしれません。

必要な情報を元に読み上げる文言を組み立てて、alexa-sdk を使ってレスポンスを返してます。

リクエストを受けて動作するプログラムは AWS Lambda 上で動作しており、Alexa Skill としては基本的な構成だと思います。

## 作ってみて思ったこと

### タイムゾーンは基本的に考えなくて良い

これはもちろん Skill の性質にもよるんですが、今回のケースでいうとタイムゾーンのことを考慮する必要はありませんでした。

今回でいうと「今日」とか「あさって」とか「来週の金曜日」といった感じに日付を指定しますが、これらはリクエストの中に Slot として含まれます。まぁ平たくいうとパラメータです。これは事前に定義したものを受け取れます。

これらの日付については Amazon Echo 側のタイムゾーンに基づいて送られてくるようで、例えば日本時間 12 月 31 日の午前 4 時は UTC ではまだ 12 月 30 の 19 時ですが、Lambda には「2017-12-31」という文字列で受け取れます。

開発中にハマったのが、Service Simulator から「今日」と送ると前日の日付が送られて来て、おそらく UTC の日付が送られて来ていたんですが、Amazon Echo Dot 実機からだと JST と思われる日付で受け取れていました。

今回は日付ベースの処理しかなかったのでこういう結論になりましたが、例えば時刻の計算を行うようなアプリとかだと当然タイムゾーンは考慮する必要があると思います。

### 開発中はフィードバックのループを回すのが大変

作る前から想像していましたが、やはり試行錯誤を繰り返すのに時間がかかります。

今回は CircleCI で AWS Lambda へのデプロイを自動化したところで効率よく回せるようになって来ました。

本番用とテスト用二つの Alexa Skill を登録しておいて、機能ブランチへの push ごとにテスト用のアプリを更新、master にマージすると本番を更新、としています。

* [.circleci/config.yml](https://github.com/yuya-takeyama/alexa-keyakizaka-info/blob/master/.circleci/config.yml)

今のところ awscli のインストールに時間がかかってしまっていて、あらかじめインストールした Docker Image を作っておけば短縮できると思いますが、まぁその辺は後回しで。

あとはスケジュールの取得とか誕生日の取得とかの部分は独立してテストできるようにしておくと細かくテストできて良かったです。

* [./bin](https://github.com/yuya-takeyama/alexa-keyakizaka-info/tree/master/bin)

### 手軽にハックできて楽しい！

先に Google Home も買っていて、そっちは Nature Remo と IFTTT を組み合わせて照明、テレビ、エアコンの操作に毎日使っていますが、まだアプリの開発には手を出していません。

一方 Alexa は Lambda に Node.js のコードをちょっとデプロイするだけで簡単に動かせてお手軽なので、購入初日から手をつけていました。

事前に AWS のアカウントを持っているかとか、Lambda を触ったことがあるかによっても変わってくるとは思いますが、その辺を仕事で触っている人には本当に簡単だと思います。
