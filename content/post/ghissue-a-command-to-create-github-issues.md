+++
date = "2016-11-27T02:43:58+09:00"
title = "コマンドラインから GitHub の Issue を作るコマンドを作った"

+++
作りました。

* [yuya-takeyama/ghissue](https://github.com/yuya-takeyama/ghissue)

## なぜ作ったか

いろいろな自動化スクリプトを書く中で、[Octokit](https://octokit.github.io/) とかで毎回実装するのは面倒だったので、標準入力だけ食わせればいい感じにやってくれるものが欲しいな、と思って作りました。

タイトル・本文だけを標準出力に書き出すスクリプトだけ書けば、それをパイプで繋げるだけで ghissue が Issue を立ててくれます。  
タイトル・本文だけうまく組み立てることに集中すればよくなり、テストも楽になるでしょう。

類似ツールとしては [ghi](https://github.com/stephencelis/ghi) というツールがありますが、これは標準入力からタイトル・本文を指定することができないので、他のコマンドと組み合わせて使うのはやや面倒です。  
また、ghi が Ruby なのに対して、ghissue は Go で実装されていてコンパイル済みのバイナリも GitHub 上で作っています。

## 使い方

### アクセストークンの指定

GitHub のアクセストークンを `GITHUB_ACCESS_TOKEN` という環境変数で指定します。

### Issue を作る

```
$ some_command | ghissue yuya-takeyama/test --labels Bug,Major --assignees yuya-takeyama
```

`some_command` は Issue のタイトル・本文を生成するためのコマンドです。  
1 行目がタイトルになり、残りは本文になります。

`--labels` (`-l`) ではラベルを指定します。カンマ区切りで複数指定可能です。

`--assignees` (`-a`) では assignee を指定します。これもカンマ区切りで複数指定可能です。

## その他

Issue を編集する機能・コメントを記入するための機能もあっていいだろうと思うものの、今のところ個人的には必要としてないので、まぁそのうち。

よければご利用ください。
