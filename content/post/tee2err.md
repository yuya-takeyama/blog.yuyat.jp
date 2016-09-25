+++
date = "2016-09-26T01:00:24+09:00"
title = "標準エラー出力に tee するコマンド tee2err を作った"

+++
GNU tee でも BSD tee でもできないので作りました。

[yuya-takeyama/tee2err](https://github.com/yuya-takeyama/tee2err)

## これは何か

標準入力を食わせると、標準出力と標準エラー出力に同じものを出力するだけのコマンドです。

```
$ echo foo | tee2err
foo
foo
```

foo と 2 回出力されていますが、一方は標準出力に、もう一方は標準エラー出力に出力されています。

## どういう時に使うか

標準入力からストリームを食わせるとなんらかの終端操作を行うようなツールと一緒に使います。

例えば 1 から 10 までの数列の総和を求める場合。

```
$ seq 10 | perl -ane '$i+=$_; END { print "SUM: $i\n"; }'
SUM: 55
```

これはこれで特に問題ないですが、これに `tee2err` を組み合わせるとこのようになります。

```
$ seq 10 | tee2err | perl -ane '$i+=$_; END { print "SUM: $i\n"; }'
1
2
3
4
5
6
7
8
9
10
SUM: 55
```

`seq 10` の出力を見ながら計算結果を待つことができます。  
1 ~ 10 の数値は標準エラー出力への出力なので、`perl` での計算に影響は及ぼしません。

この例であればいずれにせよ一瞬で終わるので特に問題にならないですが、以前 Qiita に書いた [`curl` コマンドでベンチマークを実行するような場合](http://qiita.com/yuya_takeyama/items/baf48a3f643e743a46b4)だとそれなりに待たされるので、ターミナルに何も出力されないまま待ち続けるのは少しストレスだったりするので作りました。


## インストール

```
$ go get github.com/yuya-takeyama/tee2err
```

または [releases](https://github.com/yuya-takeyama/tee2err/releases) にビルド済みバイナリも置いてます。
