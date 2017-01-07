+++
date = "2016-09-27T09:10:34+09:00"
title = "curl でレスポンスタイムをシュッと取るヤツ"

+++
以前 Qiita に[curl でサッと HTTP ベンチマーク](http://qiita.com/yuya_takeyama/items/baf48a3f643e743a46b4)と書いたが、それをもうちょい簡単にやるために以下のようなコマンドを用意してみた。

<!--more-->

```sh
#!/bin/sh
curl -s -o /dev/null -w '%{time_starttransfer}\n' "$@"
```

これを `curlb` という名前で `$PATH` の通ったところに置いておくと以下のようにできる。

```
$ curlb https://blog.yuyat.jp/
0.067
```
