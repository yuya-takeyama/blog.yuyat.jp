+++
date = "2016-09-19T14:12:38+09:00"
draft = false
title = "Let's Encrypt の証明書を Ansible と certbot で Nginx にインストール & 自動更新"

+++
これも[リニューアル](/post/brand-new-blog/)ネタです。

## やりたいこと

* Let's Encrypt の証明書を Ansible でインストールする
* その後の証明書の更新も自動で行うようにする
  * その設定もやはり Ansible で行う

## 前提とする環境

Ubuntu 16.04 だと certbot が apt-get でインストールできますが、それ未満だと [certbot-auto](https://certbot.eff.org/all-instructions/#ubuntu-14-04-trusty-apache) というコマンドを手動でインストールする必要があります。  
中身はほぼ同じだと思いますが、そちらについての説明はしません。

* Ubuntu 16.04
* Ansible 2.1.1.0
* nginx 1.10.1

## 手順

### certbot のインストール

certbot とは Let's Encrypt の証明書の取得や更新を自動化するためのコマンドラインツールです。

こんな感じの playbook でインストールします。

```yml
- name: install certbot
  apt: name=letsencrypt state=present update_cache=yes
```

### 証明書の取得

certbot は [Automated Certificate Management Environment (ACME)](https://github.com/letsencrypt/acme-spec) というプロトコルにより証明書の取得を行います。  
これは、Let's Encrypt のサーバが証明書を取得しようとしているドメインのある URL にアクセスし、ちゃんとレスポンスを返すことができるかチェックするというものです。

そのため事前に nginx 等の Web サーバを起動して、インターネットからリーチできる状態にしておく必要があります。  
(`--standalone` オプションを使えば certbot 自身が Web サーバを立ち上げてくれるが、すでに立っている Web サーバを止める必要があるので今回は使いませんでした)

nginx の設定は以下のようにしておきます。  

```nginx
server {
  listen 80;
  server_name blog.yuyat.jp;

  location /.well-known/ {
    default_type "text/plain";
    root /var/www/html;
  }
}
```

そして証明書を取得する playbook はこんな感じ。

```yml
- name: obtains cert keys
  command: letsencrypt certonly --webroot -d blog.yuyat.jp -w /var/www/html --email YOUR_EMAIL@example.com --agree-tos --keep-until-expiring --non-interactive
```

* `-d`: 取得対象のドメイン
* `-w`: Web サーバのルートディレクトリ (nginx.conf に合わせる)
* `--email`: 自分のメールアドレス
* `--agree-tos`: [規約](https://letsencrypt.org/repository/)への同意の意思表示。自動化においては必須のコマンドです。
* `--keep-until-expiring`: 証明書取得済みの場合、期限切れでなければ取得を行わない。Ansible で再実行するときのために必要です。

証明書が取得できたら nginx に証明書の設定を追加します。  
証明書ファイルはドメイン名に応じたパスに格納されます。

```
server {
  listen 443 ssl http2;
  server_name blog.yuyat.jp;

  ssl_certificate     /etc/letsencrypt/live/blog.yuyat.jp/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/blog.yuyat.jp/privkey.pem;
}
```

### 証明書の自動更新

certbot には自動更新のためのサブコマンドも用意されています。  
これを cron に登録しておくことで、証明書の有効期限を気にする必要がなくなります。

```yml
- name: auto update cert keys
  cron:
    name: letsencrypt
    cron_file: letsencrypt
    user: root
    special_time: daily
    job: sh -c 'letsencrypt renew && /usr/sbin/service nginx reload' >> /var/log/letsencrypt/cron.log
```

デフォルトだと `/usr/sbin` には `$PATH` が通ってないところに注意が必要です。

実際には [cronlog](https://github.com/kazuho/kaztools/blob/master/cronlog) を使うなどしてうまく通知を受け取れるようにしておくのが良いでしょう。
