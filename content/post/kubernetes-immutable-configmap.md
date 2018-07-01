---
title: "Kubernetes の ConfigMap を Immutable に管理する"
date: 2018-07-01T21:00:00+09:00
---
Quipper では Microservices 基盤として Kubernetes によるクラスタを構築し、もうすぐ本番環境にリリースしようとしています。本当は [Deis Workflow](https://deis.com/docs/workflow/) で使う Kubernetes クラスタを既に本番で運用していますが、Deis なしでの運用に変えようとしているのが最近の状況です。

そこら辺の背景は 2018/07/19 に行われる [Quipper Product Meetup](https://techplay.jp/event/680406) でお話しするとして、今は YAML の管理どうするかみたいなところから試行錯誤している状態で、基本的には Pull Request ベースでレビューしてマージされたらデプロイ、みたいなことをアプリでもクラスタでもやる感じになっています。

今日は、その中でも `ConfigMap` をどう扱うか、について Mutable/Immutable 2 つのアプローチについて実際に動く設定・スクリプト付きで紹介します。

<!--more-->

設定・スクリプトは全て GitHub のリポジトリに置いています: [yuya-takeyama/kubernetes-immutable-configmap-example](https://github.com/yuya-takeyama/kubernetes-immutable-configmap-example)

## 背景

Kubernetes における `ConfigMap` は設定値や設定ファイルを保持するためのリソースで、`Deployment` (`Pod`) からは環境変数として読み込んだり、ファイルとして Volume にマウントしたりして使用します。

`ConfigMap` を更新するだけでは、それを参照する `Deployment` (`Pod`) はロールアウトされず、環境変数等にも反映されません。ロールアウトするために何か工夫が必要です。

## 元ネタ

「`ConfigMap` を immutable にせよ」というのは GitHub/Stack Overflow はじめ様々なところで言及されています。

ですが、実際に動く例というものがなさそうなので、そういった言及を元に想像で作ってみたのが今回の例です。

実際に参考にしたのは以下のコメントです。

* [https://github.com/kubernetes/kubernetes/pull/31701#issuecomment-252110430](https://github.com/kubernetes/kubernetes/pull/31701#issuecomment-252110430)
  * Kubernetes/GKE/CNCF のメンバーである [Brian Grant](https://github.com/bgrant0607) によるコメント

## Mutable なアプローチ

まずはより素朴なアプローチとして Mutable なアプローチです。大まかには以下のような仕組みです。

* 環境変数を保持する `ConfigMap` は常に同一のものを更新する
* それを参照する `Pod` には `annotations` として `ConfigMap` ファイルのチェックサムを保持する
* `ConfigMap` に変更があると `Pod` が持つチェックサムも変更されるので、`kubectl apply` 時にロールアウトが実行される

### Deployment

注目すべきは以下の 2 点です。

* 環境変数は `envFrom` を使って `nginx-config` という `ConfigMap` を参照している
* `Pod` の `annotations` にはチェックサムを保持するためのプレースホルダ `"${config_checksum}"` を含む
  * `envsubst` で埋め込む前提

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
  namespace: cm-deploy-mutable
spec:
  replicas: 1
  selector:
    matchLabels:
      run: nginx
  template:
    metadata:
      labels:
        run: nginx
      annotations:
        yuyat.jp/configmap.checksum.nginx-config: "${config_checksum}"
    spec:
      containers:
      - envFrom:
        - configMapRef:
            name: nginx-config
        image: nginx:alpine
        name: nginx
```

### ConfigMap

`ConfigMap` は `APP_VERSION=1` という値を保持するだけのプレーンな YAML なのでここでは割愛。

### デプロイスクリプト

事前に `ConfigMap` ファイルの SHA-1 チェックサムを取っておき、それを `envsubst` を使って `Deployment` に埋め込んでいます。

```bash
#!/bin/bash
config_checksum=$(shasum mutable/nginx-config.cm.yaml | awk '{ print $1 }')

kubectl apply --record -n cm-deploy-mutable \
  -f mutable/cm-deploy-mutable.ns.yaml \
  -f mutable/nginx-config.cm.yaml \
  -f <(cat mutable/nginx.deploy.yaml.tpl | config_checksum=$config_checksum envsubst '$config_checksum')
```

### デプロイしてみる

初回はそれぞれのリソースが生成されます。

```
$ ./mutable/deploy.sh
namespace "cm-deploy-mutable" created
configmap "nginx-config" created
deployment "nginx" created
```

この状態で環境変数 `APP_VERSION` には `1` がセットされています。

```
$ ./mutable/version.sh
1
```

何も変更せずに再度デプロイしても、何も起こりません。

```
$ ./mutable/deploy.sh
namespace "cm-deploy-mutable" configured
configmap "nginx-config" unchanged
deployment "nginx" unchanged
```

`APP_VERSION` を `2` に変更してデプロイすると、ロールアウトが行われます。

```
$ ./mutable/deploy.sh
namespace "cm-deploy-mutable" configured
configmap "nginx-config" configured
deployment "nginx" configured
```

コンテナ内の環境変数も正常に変更されました。

```
$ ./mutable/version.sh
2
```

### Mutable なアプローチの問題点

ここまでは上手くいっていますが、問題となるのはロールバックする時です。

```
$ kubectl rollout undo deploy/nginx -n cm-deploy-mutable
```

この状態で環境変数を確認すると、`2` のままで、元に戻っていないことがわかります。

```
$ ./mutable/version.sh
2
```

ロールバックされるのはあくまでも `Deployment` なので、それにひもづく `ConfigMap` が変わらない以上は当然の結果です。

ですが、環境変数等の設定値も含めてロールバックしたい場合には困りますね。

## Imuutable なアプローチ

Mutable なアプローチの問題点を解決するための Immutable なアプローチは以下のようなものです。

* 環境変数を保持する `ConfigMap` の name には suffix としてチェックサムを不可する
  * 内容が変わると新しいチェックサムを持った `ConfigMap` を毎回新しく作成する
* `Pod` からもそのチェックサム付きの名前で参照する
* `ConfigMap` に変更があると `Pod` 参照する `ConfigMap` が毎回変わるので、`kubectl apply` 時にロールアウトが実行される

### Deployment

Mutable なものとだいたい似ていますが、差分は以下の 2 点です。

* チェックサムを保持する `annotations` を削除
  * これは敢えて持たせたままにするのもありだと思います
* `envFrom` で参照する `ConfigMap` の名前の suffix 部分がプレースホルダになっている
  * やはり `envsubst` で値を埋め込む前提

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: nginx
  namespace: cm-deploy-immutable
spec:
  replicas: 1
  selector:
    matchLabels:
      run: nginx
  template:
    metadata:
      labels:
        run: nginx
    spec:
      containers:
      - envFrom:
        - configMapRef:
            name: "nginx-config-${config_checksum}"
        image: nginx:alpine
        name: nginx

```

### ConfigMap

Mutable なアプローチではプレーンな YAML でしたが、こちらでは `ConfigMap` も `envsubst` による値の埋め込みを行います。

```yaml
apiVersion: v1
data:
  APP_VERSION: "1"
kind: ConfigMap
metadata:
  name: nginx-config-${config_checksum}
  namespace: cm-deploy-immutable
```

### デプロイスクリプト

事前に `ConfigMap` ファイル (テンプレート) のチェックサムを取るのは同じですが、`Deployment` だけでなく `ConfigMap` にも `envsubst` での値の埋め込みを行います。

```bash
#!/bin/bash
config_checksum=$(shasum immutable/nginx-config.cm.yaml.tpl | awk '{ print $1 }')

kubectl apply --record -n cm-deploy-immutable \
  -f immutable/cm-deploy-immutable.ns.yaml \
  -f <(cat immutable/nginx-config.cm.yaml.tpl | config_checksum=$config_checksum envsubst '$config_checksum') \
  -f <(cat immutable/nginx.deploy.yaml.tpl | config_checksum=$config_checksum envsubst '$config_checksum')
```

### デプロイしてみる

初回はやはりそれぞれのリソースが生成されます。`ConfigMap` の名前にチェックサムが含まれることがわかります。

```
$ ./immutable/deploy.sh
namespace "cm-deploy-immutable" created
configmap "nginx-config-12db160438b100c95eb77c821899f524d6027405" created
deployment "nginx" created
```

環境変数は当然ちゃんとセットされています。

```
$ ./immutable/version.sh
1
```

`ConfigMap` に変更がない状態で再度適用しても、何も変更が起こらないのは Mutable なときと同じです。

```
$ ./immutable/deploy.sh
namespace "cm-deploy-immutable" configured
configmap "nginx-config-12db160438b100c95eb77c821899f524d6027405" unchanged
deployment "nginx" unchanged
```

ここで `APP_VERSION` を `2` に変更してデプロイすると、今度はロールアウトが行われます。`ConfigMap` は新しく作られていることがわかります。

```
$ ./immutable/deploy.sh
namespace "cm-deploy-immutable" configured
configmap "nginx-config-b6fe7e2f2edca16c3778836541a399245ca2372e" created
deployment "nginx" configured
```

コンテナ内の環境変数も正常に変更されました。

```
$ ./immutable/version.sh
2
```

### ロールバックしてみる

Mutable なアプローチで問題になったロールバックをこちらでもやってみます。そちらではロールバックしたにもかかわらず、`APP_VERSION` は `2` のままで元に戻ってくれませんでした。

```
$ kubectl rollout undo deploy/nginx -n cm-deploy-immutable
```

ここでコンテナ内の環境変数を確認すると、見事 `1` に戻っています！

```
$ ./immutable/version.sh
1
```

ロールバックすることで `Pod` が参照する `ConfigMap` が一つ前のものに書き換わり、その `ConfigMap` には作成時のままの値が入っているので、今度は `ConfigMap` ごとロールバックされました。

今回は `ConfigMap` のみの変更でしたが、`Deployment` に同時に変更を加えていた場合、その変更もアトミックになるのでロールバックも同様にアトミックに行われることになります。

### Immutable なアプローチの問題点

Mutable なアプローチで問題になったロールバックも上手く行きましたが、こちらは `ConfigMap` に変更があるごとに毎回新しく `ConfigMap` が作られてしまいます。

気にせず放置、というのも一つのやり方だと思いますが、気になるのであれば以下のような手順で対処することが考えられます。

* `ConfigMap` には `label` で共通の値 (`nginx-config` 等) を持たせておく
* `label` に紐付く `ConfigMap` を全て取得し、`metadata` が持つ `creationTimestamp` でソートし、新しいものいくつかを残して残りは全て削除する
  * ということを `CronJob` とかでやると良いのかも

## まとめ

`Pod` にとっての `ReplicaSet` のようなものが `ConfigMap` にも欲しいですね。

[kustomize](https://github.com/kubernetes-sigs/kustomize) で実現する方法もあるっぽいのでそれはまた今度調べてみます。

* [https://github.com/kubernetes-sigs/kustomize/tree/730597b77e0a3a4d4c73668e5b1b414c13c76f5a/examples/helloWorld#how-this-works-with-kustomize](https://github.com/kubernetes-sigs/kustomize/tree/730597b77e0a3a4d4c73668e5b1b414c13c76f5a/examples/helloWorld#how-this-works-with-kustomize)

なお、Quipper では Kubernetes を使って最高の Microservices 基盤を作りたい SRE を大募集中です。

* [https://www.quipper.com/career/Japan/](https://www.quipper.com/career/Japan/)
