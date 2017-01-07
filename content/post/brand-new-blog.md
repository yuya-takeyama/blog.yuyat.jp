+++
date = "2016-09-19T02:39:31+09:00"
draft = false
title = "ブログを Hugo でリニューアルした"

+++
長年 Wordpress を使ってきたけどいい加減辛くなってきたので [Hugo](https://gohugo.io/) に移行しました。

<!--more-->

過去ブログのデータ移行については過去に何度も挫折していて、結局リバースプロキシを使っていい感じに振り分けることにしました。  
以前の記事 URL は基本的に全て生きているはずです。  
コメントとかはできませんが。

新ブログは GitHub Pages からリバースプロキシを介して配信しています。  
Let's Encrypt で SSL 化し、ついでに Nginx も HTTP2 化したので、その辺のネタはそのうちに書いていければと思ってます。

あと、テーマは [@chibicode](https://github.com/chibicode) さんの [hugo-theme-shiori](https://github.com/chibicode/hugo-theme-shiori) をカスタマイズして使っています。

今後ともよろしくお願いします。
