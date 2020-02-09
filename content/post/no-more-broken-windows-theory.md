+++
date = "2020-02-01T16:00:00+09:00"
title = "ソフトウェア開発の文脈で割れ窓理論を引用するのはミスリーディングではないか"
+++
基本的には Twitter に既に書いた内容のまとめです。

<!--more-->

## 元ツイート

いくつかのツイートがこのスレッドに続いています。

<blockquote class="twitter-tweet"><p lang="ja" dir="ltr">📝 割れ窓理論と SRE (Site Reliability Engineering) は相容れないかもしれない、という話を書いていくので意見のある方は reply ください</p>&mdash; Yuya Takeyama (@yuya_takeyama) <a href="https://twitter.com/yuya_takeyama/status/1222783547578167298?ref_src=twsrc%5Etfw">January 30, 2020</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

## 趣旨

### 割れ窓理論の本質

皆さんは割れ窓理論の本質がなんであるかご存知でしょうか。私は知りません。

ですが、私は「軽微な犯罪も徹底的に取り締まること」が「凶悪犯罪を含めた犯罪を抑止できる」という点に集約されるのではないかと思っています。まぁこれは Wikipedia 上の文言そのままなんですが。

* [割れ窓理論](https://ja.wikipedia.org/wiki/%E5%89%B2%E3%82%8C%E7%AA%93%E7%90%86%E8%AB%96)

### ゼロ・トレランス政策と限界効用の逓減性

ニューヨークではゼロ・トレランス政策として実行され、実際に犯罪現象の成果が現れたそうです。一方で、その政策を実行した都市でもしなかった都市でも犯罪の発生率は同様である、という批判もあるようです。これもなんと Wikipedia に書いています。

ということを踏まえて、私は割れ窓理論については懐疑的な立場です。

直感的にゼロ・トレランスがダメだな、と思うのは、あらゆる施策の効用には逓減性があるはずだからです。[限界効用逓減の法則](https://ja.wikipedia.org/wiki/%E9%99%90%E7%95%8C%E5%8A%B9%E7%94%A8)というのは大学の一般教養でとった経済学史の授業で習ったはずですが、まぁ日頃使わない知識は当然忘れますよね。どちらかというと [@fladdict](https://twitter.com/fladdict?lang=en) さんのこの記事を読んでから最近強く意識しています。

* [放出系を習得してから、自分が具現化系だと判明しました。修行をやりなおすべきでしょうか？](https://note.com/fladdict/n/nb178cbe40a6c)

この記事ではあらゆるスキルには逓減性があり、あるひとつのスキルを伸ばせば伸ばすほど、それより先に伸ばすのはより大変になる、だから必要に応じて別のスキルも伸ばしていこう、といったことが書いてあると私は理解しました。深津さんが本当にそのような意図でそれを書いたかは私にはわかりませんが、少なくともそう考える私が今ここにいるということだけは確かなことだと言えそうです。我思う、ゆえに我あり。

### Site Reliability Engineering の本質

ここで突然 Site Reliability Engineering の話をするのは、私が日頃 Site Reliability Engineer として働いているので、ある種のポジショントークです。

が、それを踏まえて、私が考える Site Reliability Engineering の本質は「計測に基づく継続的な改善」だと考えています。そしてそのためのツールとして提示されているのが SLO です。

Site Reliability Engineering や SLO について知らない方のために簡単に説明すると、SLO というのはサイトの信頼性を測る目標値です。例えば全リクエスト中の成功となるレスポンスの割合を 99.9% (スリーナイン) にしよう、99.99% (フォーナイン) にしよう、というものです。

SLO を決める際に大事なのは必ず 100% 未満のどこかにするということです。100% を目指してしまうと、そのために必要なコストが無限に膨張するからです。そもそも、Web サービスのインフラであるネットワークやそれを支えるデバイスにしても、100% 動いているわけではありません。エンドユーザの体験として 100% の信頼性というのはいずれにせよ無理なので、適切な目標を決めてそこを目指そうというものです。

ここにも、限界効用逓減の法則が見えますね。

### 割れ窓というアナロジー

ソフトウェア開発の文脈において、割れ窓理論の引用はよく見ます。が、面倒なのでエビデンスは示しません。私はそれを勉強会やカンファレンスの発表やブログ記事等の中で幾度となくそれを見てきた気がする、ということをここで強く主張しますが、それをあなたに押し付けてもしょうがないことです。

なんでこんなによく見るのか、というのを考えると、私はこの「割れ窓」というアナロジーがわかりやすくて魅力的だからではないかと考えます。窓が全く割れてない学校と、半分ぐらい割れてる学校とを比較して、夜の校舎窓ガラス壊してまわる上でどちらが心理的障壁が少ないか、を考えると想像しやすいんじゃないでしょうか。

<iframe width="560" height="315" src="https://www.youtube.com/embed/sAGtMfkx89Y" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

もちろん、[真っ白なものは汚したくなる](https://amzn.to/2OhsANb)タイプの人にとってはゼロから窓を壊していく方がより大きなカタルシスを得られるはずです。なぜなら効用が逓減していない最大の状態だから。とはいえ基本的にはほとんどの人にとっては良識とかそのようなものがボトルネックになると私は信じています。

ちょっと話がそれましたが、例えば部屋を完璧に片付けて、最初の数日は明らかに「散らかしたくない」という力が自分の内面に働いた経験は多くの人にあるのではないでしょうか。大抵どこかで堰を切って、いつの日かほぼ素の状態に収束するんですが。でもね、別にそんな経験無くたっていいんです。私はそれをあなたに押し付けません。とりあえず「まぁ似たようなことは世の中色々あるな」ぐらいの気持ちで読み進めてもいいし読み進めなくてもいい。[できないことを求めるのもやめにしよう](https://www.sunmusic.org/profile/pekopa.html)。

### 再び割れ窓理論について

ここまで読み進めた方にはお分かりだと思いますが、私は別に割れ窓を減らすことについては何も否定していません。徹底的にやるのが間違いだということを言っています。そして割れ窓理論は徹底的にやることを目指したものである以上、それをソフトウェア開発の文脈で引用するのはミスリーディングではないか、というのがこの記事の主旨です。

## ソフトウェア開発における割れ窓との付き合い方がどうあるべきか

### まずは始めてみる

割れ窓への対処は、ほとんどの場合において何かした方が良いでしょう。何もしていないというゼロの状態に比べて、ひとつ直した状態は効用が逓減していないので大きな効果があると考えられます。

### 続けてみる

実際には、何か新しいことを始める際には、それを始めるコストがかかります。例えばエラーログをどこから追えばいいか、という情報を調べることから始まります。一回わかってしまって、次回以降その知識を使い回せるのなら、そこにかかるコストはゼロということになります。つまり、やるなら一つだけ直すのではなく、それを継続した方が良いでしょう。継続はリズムを生みます。

ここまでであれば「割れ窓は直せば直すほどお得」ということにも読めてしまいますが、もちろんそうではありません。それでは割れ窓理論の本質である「徹底的に取り締まる」になってしまいます。

### 一回性と覚悟

あるときにアプリケーションのエラーログを調べる方法がわかれば、それについての知識は使いまわせても、別の時にはデータベースのログを調べる方法を知る必要があるかもしれません。割れ窓は多様なはずなので、それぞれごとの立ち上げコストがかかります。

ある割れ窓に対する初回固有のコストは一回性のものですが、あらゆる割れ窓は連綿として立ち現れ、その度に初回固有のコストを払うことになります。終わりのない一回性の連続の中で日々割れ窓を直していく覚悟が求められます。

### 計測とそのコスト

ですが、人間の覚悟のあり方は人それぞれによって異なるはずですし、多分有限です。そこの覚悟を支え得るものとして、私は計測があると思ってます。つまり、Site Reliability Engineering の本質である (と私が考えている) 「計測に基づく継続的な改善」をやればいいのです。

ですが、計測にもコストがかかります。割れ窓理論が「徹底的に取り締まる」という結論になってしまったのは、結局のところ計測のコストの問題だったのではと思います。自宅の窓とそれが割れてる数を計測することはできても、スケールを区画、町、都市と広げていくと、どこかで無理になるでしょう。ここにも限界効用の逓減性が見えます。

ソフトウェアにとって特徴的なのは、計測のコストが現実の世界に比べればめちゃくちゃ低いことです。一度計測の仕組みを作ってしまえば、その仕組みは自動的に動きます。

また、Site Reliability Engineering においては、計測すべき対象についていくつか指針や、ツールとしての SLO を示してくれています。

なので、そういった枠組みで考えやすい対象については目標値を決め、計測に応じて必要な分だけ割れ窓を直せば良いことになります。もちろん目標値は 100% 未満のどこかである必要があります。これなら終わりのない一回性の連続を乗り越える勇気も湧いてくるのではないでしょうか。

では、そういった枠組みで考えるのが難しい対象についてはどうすれば良いか。

### 妥協としての割れ窓バジェット

計測が難しいのであれば、量を固定してしまえば良いのではないでしょうか。例えば隔週で金曜日は通常の業務を原則ストップして、割れ窓を直すことに費やす、といった具合です。そういった取り組みを行なっている会社はすでにいくつかあるようです。

* [割れ窓理論を導入してWebサービスのクオリティに直結した話](https://devpixiv.hatenablog.com/entry/2016/12/08/172049)
* [割れ窓理論をWebインフラの改善に活用し、チーム内の知識共有を促進している話](https://blog.hokkai7go.jp/entry/2018/12/13/000146)

10 営業日中 1 営業日を割れ窓を直すためにあらかじめ組み込むので、これはある種バジェットです。

しかし、これはあくまでも計測のコストが高いことに対する妥協であるべきと考えます。といっても上記の企業の取り組みに対して批判しているわけではありません。仕事は妥協の連続。

<iframe scrolling="no" class="alu-embed-iframe-JF9EJz3tWX8ObjG6mp2D" src="https://alu.jp/series/%E6%98%A0%E5%83%8F%E7%A0%94%E3%81%AB%E3%81%AF%E6%89%8B%E3%82%92%E5%87%BA%E3%81%99%E3%81%AA%EF%BC%81/crop/embed/JF9EJz3tWX8ObjG6mp2D/0?referer=oembed" style="margin: auto; display: block; border-width: 0px;"></iframe><div class="alu-embed" style="max-width: 432px;text-align: right;margin: 0 auto;"><a href="https://alu.jp/series/%E6%98%A0%E5%83%8F%E7%A0%94%E3%81%AB%E3%81%AF%E6%89%8B%E3%82%92%E5%87%BA%E3%81%99%E3%81%AA%EF%BC%81/crop/JF9EJz3tWX8ObjG6mp2D/0" target="_blank" style="margin: 0 auto !important;display: inline-block;padding-top: 10px;font-size: 12px;color: #787c7b;text-decoration: none;text-align: right;">映像研には手を出すな！ / alu.jp</a></div>

### 乗り越えられるべき存在としての割れ窓バジェット

日々妥協の中に生きているとしても、同じ妥協に妥協してはいけないと考えます。これは善悪の問題ではなく、楽しさの問題として。人間は飽きる生き物なので、そのままではいつか絶対に割れ窓バジェットの運用は止まっていきます。そしてそれははだいたい少しずつうやむやに進み、どこかで突然に終わるものです。

ではどうすれば良いか。常にプロセスを改善し続けることだと思います。例えばあらゆるエラーログを横串で見られるようにしてみたり、そういったログからメトリクスを生成してみたり、そこから SLO を決めてみたり。あれ、いつの間にか Site Reliability Engineering になってしまった。

もちろん、そうすることができるものについては自然とそうなっていくだろうし、難しいものとしては妥協としてドキュメントを書いたり、問題を緩和してくれるようなツールやライブラリやミドルウェアを導入したり、色々やっていくことになるでしょう。

より根本的な対応として、使われてない機能やサービスを終わらせる、ということもあり得ると思います。ですが、私はそれすらも本当の意味で根本的ではないと思っています。どこかに動いている機能やサービスがある限り、そこからまた割れ窓は生まれ続けるのだから。

大事なのは常に現状に満足せず、より良く割れ窓をなおし続けることだと思います。そのための仕組みづくりが必要だとか、そのための知恵や技術力が必要だとか、そういうことに時間を使えるだけの企業としての体力が必要だとか色々なことが言えますが、結局どこかでほんの少しの情熱が必要になると思います。だから、それでも割れ窓をなおしていく、という気持ちは常に尊いと私は考えます。

## 蛇足: 終末論としての割れ窓理論

### 割れ窓理論は答えのようなものを与えてくれる

昔、何かの本で、「全ての宗教は終末論の構造を持っている」といったような内容のことを読んだ記憶があります。仏教に多いては末法、ユダヤ教やキリスト教においては最後の審判。そういった終わりがあり、歴史はまっすぐそこに進む。そしてそこで救われて天国にいくためには正しいことをしろ、とかその辺の詳細はそれぞれ違うと思いますし、僕は宗教についての専門家ではないので細かい話は避けますが、構造としては共通しているということが言えそうです。

この話、どの本で読んだんだっけな。すくなくとも宮台真司か速水健朗みたいな日本の社会学方面の人の著作だったか、それ以外のどちらかということは言えそうです。いや、もしかしてそんな私の記憶自体が偽りだったとしたら?

ともかく、割れ窓理論もそれらと同じ構造を持っていると私は考えます。割れ窓を徹底的に潰せばそれで良い、という宗教性がそこにはあります。

### Site Reliability Engineering は答えなんて教えてくれない

一方で、Site Reliability Engineering はそのような構造から逸脱した存在だと私は考えます。

Engineering は科学なんだから宗教じゃないのは当たり前じゃないか、と思う人もいるかもしれません。それはそう。

さっきの終末論の構造に Site Reliability Engineering は当てはめた時、答えとして与えられたものは何一つないと私は解釈しています。与えてくれるのは「計測に基づく継続的な改善」という哲学と、それを支える方法論としての SLO であり、エラーバジェットであり、自動化。哲学は不変だとしても、方法論は不変ではないと思うので、SLO すらもいずれは乗り越えられるべきなのでは、というのが私の考えです。

といっても、今すぐ SLO を乗り越える方法論を考えていくべきとは思っていません。世の中のほとんどの人々にとっては、SLO という方法論はまだまだ実践を繰り返して学ぶ余地があるので、今はそれをやった方が戦略としては最適なはずです。ですが、SLO という方法論の効用が限界を迎えた時には、きっと何か新しい方法論が生まれていることでしょう。

### Site Reliability Engineering が教えてくれる明らかな間違い

明確な答えをくれないでお馴染みの Site Reliability Engineering ですが、明確な間違いについてなら教えてくれています。それは 100% の目標です。そしてそれは限界効用逓減の法則のためです。

明らかな間違いがわかったところで、何が正解なのはわからないので、私たちは考え続けなければなりません。思考停止させてくれる割れ窓理論の方が短期的には楽かもしれませんが、考えさせ続けてくれる Site Reliability Engineering の方が、構造的には素敵じゃないか。

### Site Reliability Engineering がはらむ一抹の宗教性

Site Reliability Engineering は終末論の構造を逸脱していると言ったな。あれは嘘だ。いや、割れ窓理論からするとかなり逸脱しているとは言えるんだけど、逸脱しきっているとは言えない、と言った方が良いでしょう。結局のところ「計測に基づく継続的な改善」という哲学が不変なのだとして、それをカール・ポパーの[反証可能性](https://ja.wikipedia.org/wiki/%E5%8F%8D%E8%A8%BC%E5%8F%AF%E8%83%BD%E6%80%A7)に当てはめると、それは科学ではないということが言え、つまりは宗教的な構造を持つことになります。

いや、まぁそこの解釈はあくまで僕個人が勝手に言ってることなので、宗教的な構造というのも全ては僕の脳内世界だけの出来事なんですけどね。