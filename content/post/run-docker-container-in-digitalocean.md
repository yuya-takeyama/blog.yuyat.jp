+++
date = "2016-10-11T21:29:41+09:00"
title = "Docker コンテナを DigitalOcean 上でサクッと動かす"

+++
## やりたいこと

* 任意のアプリの Docker コンテナをサクッと立ち上げたい
* かつグローバル IP アドレスを割り当てて外から接続したい

より具体的には、今回は `mitmproxy` をインターネット上で動かして iPhone 等のスマートフォン端末からつなぎたかった、という感じです。

## 手順

### DigitalOcean のアカウントを作成する

ここは割愛。

### DigitalOcean のアクセストークンを作成

API -> Tokens -> Generate New Token から適当に名前をつけて作ります。

<img src="/images/run-docker-container-in-digitalocean/generate-new-token.png" width="608" height="424">

### docker-machine で Docker 環境を作る

`docker-machine` のインストール手順については割愛。  
Mac だと Homebrew でもインストールできるので適当にやっておく。

```
$ docker-machine create --driver digitalocean --digitalocean-access-token=ACCESS_TOKEN --digitalocean-region=sgp1 mitmproxy
```

`--digitalocean-access-token` には前の手順で作ったアクセストークンを指定。

`--digitalocean-region` にはリージョンの slug を指定します。  
省略すると New York にできてレイテンシが辛いので、日本からだとシンガポールでも指定しておくのがいいでしょう。

リージョンの slug 一覧はこんな感じに最新版を取得できます。


```
$ curl -H "Content-Type: application/json" -H "Authorization: Bearer ACCESS_TOKEN" "https://api.digitalocean.com/v2/regions" -s | jq '.regions[] | "\(.slug)\t\(.name)"' -r | sort
ams2    Amsterdam 2
ams3    Amsterdam 3
blr1    Bangalore 1
fra1    Frankfurt 1
lon1    London 1
nyc1    New York 1
nyc2    New York 2
nyc3    New York 3
sfo1    San Francisco 1
sfo2    San Francisco 2
sgp1    Singapore 1
tor1    Toronto 1
```

末尾の `mitmproxy` という部分は Docker 環境に任意の名前をつけるだけなので適当に。

数分かかりますがトイレ行ってコーヒーでも淹れて来たりすれば終わっているでしょう。

### Docker コンテナの起動

Dockerfile を拾ってこれるような場合は Docker Hub のページ見ながら適当に。  
信頼していい Dockerfile なのかは注意する。

今回は [mitmproxy/mitmproxy](https://hub.docker.com/r/mitmproxy/mitmproxy/) のイメージを使いました。

```
# Docker への接続情報をターミナルのセッションに読み込む
$ eval $(docker-machine env mitmproxy)

# Docker コンテナの起動
$ docker run --rm -it -p 8080:8080 mitmproxy/mitmproxy
```

### IP アドレスの確認

今回は外部から接続する前提なので。  
DigitalOcean の Droplets の一覧から見てもいいです。

```
$ docker-machine ip mitmproxy
128.199.***.***
```

### Docker 環境を削除する

使い捨て前提なので削除しておきます。

```
$ docker-machine rm mitmproxy
```

アクセストークンも DigitalOcean のページ上から削除しておくとより安心でしょう。

## まとめ

こういうシュッとサーバなりコンテナなり必要なとき DigitalOcean は便利なのでアカウントを持っていない人は[作っておきましょう。 (アフィリエイトリンク)](https://m.do.co/c/645fac0c10f9)
