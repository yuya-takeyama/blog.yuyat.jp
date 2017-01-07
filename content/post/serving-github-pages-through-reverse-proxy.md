+++
date = "2016-09-25T17:57:40+09:00"
title = "GitHub Pages を nginx のリバースプロキシ越しに配信する"

+++
このブログは[以前の記事](/post/auto-deploy-hugo-to-github-pages-with-circleci/)にも書いた通り、[GitHub Pages](https://pages.github.com/) から配信しています。

そしてさらに、前段に nginx のリバースプロキシを置いた構成になってます。

<!--more-->

## 何故リバースプロキシを利用するか

はっきり言って普通に考えたら無駄感はありますが、良い点をいくつか挙げてみます。

### Zone apex domain を使用することができる

GitHub Pages は CNAME による Custom domain に対応していますが、CNAME では通常 Zone apex domain に対応することができません。

リバースプロキシを利用することで、ドメインの A レコードにリバースプロキシを指定し、その upstream に GitHub Pages の URL を指定することで、対応することができます。

(このブログはご覧の通り Zone apex domain ではないですが、そのうちそっちにもページを作るつもりです)

### Custom domain でも HTTPS を使用することができる

GitHub Pages はデフォルトでは USERNAME.github.io ドメインが割り当てられ、HTTPS で配信されます。

ですが、CNAME を使った場合は HTTP となってしまい、HTTPS を利用する方法は GitHub からは提供されていません。

[Let's Encrypt](https://blog.yuyat.jp/post/auto-renew-letsencrypt-cert-keys-with-ansible-and-certbot/) を使えばセットアップは簡単です。

### アクセスログをちゃんと取得できる

GitHub でもリポジトリの Graphs -> Traffic を見るとある程度わかりますが、nginx で好きなログを残せるようになります。

## 設定手順

### GitHub 上で Custom domain の設定をする

これは必須というわけではないですが、やった方がいいと思うのでその前提で進めます。  
設定しない場合、以降の設定手順も微妙に違ってくるので注意が必要です。

Custom domain はいつからか Web の UI 上から設定が可能になっていたので、そこからやるのがお手軽です。  
リポジトリの Settings -> Options からできます。

<img src="/images/serving-github-pages-through-reverse-proxy/custom-domain.png" width="349" height="125">

### nginx の設定

HTTPS で配信する場合、おそらくこれが最小限の設定です。  
(実際は `X-Forwarded-For` とかも指定しているけど多分特に影響していない)

```nginx
server {
  listen 443 ssl ;
  server_name blog.yuyat.jp;

  ssl_certificate     /etc/letsencrypt/live/blog.yuyat.jp/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/blog.yuyat.jp/privkey.pem;

  location / {
    proxy_pass https://yuya-takeyama.github.io;

    proxy_redirect http://blog.yuyat.jp https://blog.yuyat.jp;

    proxy_set_header Host $host;
  }
}
```

注意する必要があるのは `proxy_pass` の URL です。  
このブログの GitHub Pages 上の URL は本来 `https://yuya-takeyama.github.io/blog.yuyat.jp/` ですが、リポジトリ名の部分は指定しません。

その変わり、リポジトリ名は `proxy_set_header` で `Host` として指定します。  
この場合はリポジトリ名がそのままドメイン名になっているので `$host` を使っています。

HTTPS の場合は `proxy_redirect` も設定が必要です。  
これは例えば `https://blog.yuyat.jp/post` のような末尾のスラッシュを省略した URL にアクセスした場合リダイレクトが発生しますが、  
その時に http にリダイレクトしてしまうのを防ぐために必要です。
