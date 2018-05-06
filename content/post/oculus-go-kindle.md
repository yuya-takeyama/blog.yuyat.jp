+++
title = "Oculus Go で Kindle の電子書籍を寝ながら読む"
date = "2018-05-07T04:30:00+09:00"
images = ["/images/oculus-go-kindle/kindle.png"]
+++
[Oculus Go](https://www.oculus.com/go/) を買いました。64GB のものが 29,800 円税込送料なしという圧倒的格安なので、VR に興味のある方は是非買いましょう。Amazon で売られている転売品はくれぐれも買わないように。

[寝転んでNetflixを大画面で観る方法（Oculus Goユーザー必見）](https://www.moguravr.com/netflix-oculus-go/)という記事を読んで、寝ながらの Netflix の体験がとにかく良かったので、Kindle の書籍も同じように読めないかやってみました。

<!--more-->

## TL;DR

* Oculus Go 標準のブラウザで [Kindle Cloud Reader](https://read.amazon.co.jp/) を Request desktop mode で開く
* 日本語の書籍は基本的に Kindle Cloud Reader 自体の制約で開けない
* 漫画は開けるが、読み込みが遅かったり、画面サイズの都合で見開き表示ができなかったりと体験が良くない
* 洋書であれば割と普通に読める

## 寝ながら本が読みたい

前から常々寝ながら Kindle 書籍が読みたいと思っていて、去年はそのために iPad 用のアームを買っていました。

* [プログラマが 2017 年に買って良かったもの](/post/best-buys-2017/)

読むこと自体は寝ながらできるものの、ページをめくる時には手を上に伸ばさないといけないのが煩わしく、リモコンでの操作も難しそうなので、諦めていました。

が、そこで Oculus Go です。

## Oculus Go のブラウザで Kindle Cloud Reader を開く

Kindle Cloud Reader はブラウザで Kindle の電子書籍を読める Web アプリです。

Oculus Go のブラウザそのままで開くと、非対応ということで Android アプリのダウンロードを促されますが、Oculus Go では Android アプリを動かすことはできません。

標準ブラウザのブラウジングウィンドウ右上にある Request desktop mode ボタンを有効にした上で [Kindle Cloud Reader](https://read.amazon.co.jp/) を開くことで、うまくアクセスできます。

ただし、キャッシュか何かの都合？でうまく開けないことがあり、そういうときは `?foo` といったクエリを URL 末尾に付加すると開けたり開けなかったりします。

また、ブラウザを開いた状態で寝そべって、コントローラーを上に向けて Oculus ボタンを長押しすれば天井にブラウザを表示することができます。

<img src="/images/oculus-go-kindle/kindle.png" width="672" height="670">

## 制約

### 日本語書籍が読めない

日本語の書籍は基本的には読めません。全てが全て読めないというわけではなさそうですが、手元で試した限りは読めるものはありませんでした。

* [Kindle Cloud Reader でコミック・雑誌以外の”和書”が読めないわけでもない！試してみる価値あり！](http://mogi2fruits.net/blog/webservice-application/kindle/2826/)

### Offline download ができない

Kindle Cloud Reader にはダウンロードしておくことで、オフラインでも書籍を読める機能があります。ざっと調べた感じ Application Cache API で実装しているようです。

ですが、Oculus Go 標準のブラウザでは Application Cache API が使えないのか、ダウンロードがうまくいかないようです。

それで何が問題かというと、漫画を読むときは読み込み時間がかなりかかることになり、ネットワーク環境にもよるかもしれませんが、快適に読むことが難しくなります。

### 見開き表示ができない

これはブラウザの画面サイズの問題だと思うのですが、漫画の見開き表示ができませんでした。Mac のブラウザで試した感じでは画面サイズを十分に広げさえすれば見開き表示になるようです。

Oculus Go 標準のブラウザでは画面サイズは幅を 3 段階に切り替えられますが、任意のサイズに変更することはできないようです。選択できる最大の幅を選択しても見開き表示にならないので、どうやら難しそうです。

## 結論としてはほぼ洋書専用

とういわけでまともに読めるのは活字の洋書だけということになりました。

## その他にも試してみた

### 青空文庫

ブラウザ上で読む書籍といえばやはり青空文庫でしょう。

こちらはいわゆる電子書籍のような UI はないものの、普通に読むことができました。やはり正しくマークアップされた HTML はこういうとき強いですね。

<img src="/images/oculus-go-kindle/aozora.png" width="670" height="666">

### Amazon Prime Video

書籍ではないですが、同じ Amazon ということで Amazon Prime Video も試してみましたが、これは普通に視聴できました。

アプリではなくとも、再生さえできれば Netflix アプリと同じく最高の体験が得られます。

## まとめ

Kindle は割と残念な感じでしたが、ブラウザベースの電子書籍サービスは試してみる価値が大いにあるでしょう。

自分では試せてないですが、Windows 機を持っているのであれば、[Bigscreen](https://bigscreenvr.com/) 上で [Kindle for Windows](https://www.amazon.co.jp/dp/B011UEHYWQ) を開いてみるというのもいいかもしれません。

<iframe style="width:120px;height:240px;" marginwidth="0" marginheight="0" scrolling="no" frameborder="0" src="//rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=yuyat-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=B078MQQJPZ&linkId=3c1b7ebb75d985e65a7231323224f485"></iframe>
<iframe style="width:120px;height:240px;" marginwidth="0" marginheight="0" scrolling="no" frameborder="0" src="//rcm-fe.amazon-adsystem.com/e/cm?lt1=_blank&bc1=000000&IS2=1&bg1=FFFFFF&fc1=000000&lc1=0000FF&t=yuyat-22&o=9&p=8&l=as4&m=amazon&f=ifr&ref=as_ss_li_til&asins=B0184N7WWS&linkId=1bf535dc833fa92a3a33c2a213f3bdb2"></iframe>
