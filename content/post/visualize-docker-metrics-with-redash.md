+++
date = "2016-10-02T14:56:46+09:00"
title = "Docker のメトリクスを Re:dash でビジュアライズ"
images = ["/images/visualize-docker-metrics-with-redash/chart.png", "/images/visualize-docker-metrics-with-redash/stack-chart.png"]

+++
しばらく前から [Dokku](http://dokku.viewdocs.io/dokku/) という Docker ベースの Heroku ライクな PaaS 基盤を趣味で運用していて、その中で旧ブログの WordPress や 自分用のツールなんかを動かしたりしている。

サーバのメトリクス収集には [Mackerel](https://mackerel.io/) を利用しているが、Docker コンテナ単位での計測は行っていなかった。  
Mackerel はホスト数に応じた課金を行っていて、5 ホストまでは無料だが、コンテナまで追加してしまうとすぐにその枠を溢れてしまう。

というわけで簡単な仕組みを自分で用意いてみた。

## できたもの

<img src="/images/visualize-docker-metrics-with-redash/chart.png" width="414" height="319">

<img src="/images/visualize-docker-metrics-with-redash/stack-chart.png" width="416" height="342">

どちらもメモリ使用量 (MB) をコンテナ名ごとにグラフ化したもので、どちらもデータは同じものを使っている。  
後者はグラフを積み上げることでコンテナ全体で使用しているメモリの使用量もわかるようになっている。

今のところ Docker のリソースに関して困っているのはメモリだけなので、とりあえずはこれだけ。

なお、Dokku ではコンテナ名が `アプリ名.プロセス名.プロセス番号` という感じになる (例えば `blog.web.1` といった具合) になるので、アプリを再起動してコンテナ ID が変わっても連続的にモニタリングできる。  
グラフ中異常値っぽいのが出ているところはまさにアプリを再起動したりしているところ。

## 概要

以下のような流れでこのグラフを作り出している。

1. [fluent-plugin-docker-metrics](https://github.com/kiyoto/fluent-plugin-docker-metrics) で Docker のメトリクスを td-agent に収集
1. [fluent-plugin-bigquery](https://github.com/kaizenplatform/fluent-plugin-bigquery) でメトリクスを BigQuery に送信
1. [Re:dash](http://redash.io/) で BigQuery 上のデータをグラフ化

## 手順

### fluent-plugin-docker-metrics のセットアップ

`td-agent.conf` の設定はこんな感じ。

```
<source>
  @type docker_metrics
  stats_interval 1m
  tag_prefix docker.metrics
</source>
```

`tag_prefix` はデフォルトだと `docker` だが、別の機会で Docker の何かを収集することもあるかもしれないので `docker.metrics` としてみた。

`stats_interval` はとりあえず 1 分ごとにしているが、すべてのコンテナの値を収集するとデータ量がそこそこ多くなるので 5 分ごととかに減らしてもいいかもしれない。

これでこんな感じのデータが収集できる。

```
20161002T062409+0000	docker.metrics.memory.stat	{"key":"memory_stat_cache","value":9039872,"type":"gauge","hostname":"HOSTNAME","id":"6008f80ef7f6c6747edf01019846074d27e29a7d217c6e3f3301fcdb435cef73","name":"/blog-legacy.web.1"}
20161002T062409+0000	docker.metrics.memory.stat	{"key":"memory_stat_rss","value":14028800,"type":"gauge","hostname":"HOSTNAME","id":"6008f80ef7f6c6747edf01019846074d27e29a7d217c6e3f3301fcdb435cef73","name":"/blog-legacy.web.1"}
20161002T062409+0000	docker.metrics.memory.stat	{"key":"memory_stat_rss_huge","value":0,"type":"gauge","hostname":"HOSTNAME","id":"6008f80ef7f6c6747edf01019846074d27e29a7d217c6e3f3301fcdb435cef73","name":"/blog-legacy.web.1"}
```

コンテナ ID とコンテナ名の両方が記録されるので、どちらでもグループ化して集計することが可能である。

### fluent-plugin-bigquery のセットアップ

```
<match docker.metrics.**>
  @type bigquery

  auth_method json_key
  email ***@PROJECT.iam.gserviceaccount.com
  json_key /etc/td-agent/bigquery/key.json

  project PROJECT
  dataset docker
  table   metrics_%Y%m%d
  ignore_unknown_values true
  auto_create_table true

  time_format %s
  time_field time

  field_timestamp time
  field_integer   value
  field_string    key,type,hostname,id,name
</match>
```

日別にテーブルに保存されるよう、`table` は `metrics_%Y%m%d` としている。

また、テーブルは自動で作られるが、データセットはあらかじめ作っておく必要があるらしい。

### Re:dash でグラフ化

Re:dash 自体のセットアップについては割愛するが、個人的にはこれを Dokku で動かしていて、その手順については以前 Qiita に書いている。

* [Dokku に Re:dash をインストールする](http://qiita.com/yuya_takeyama/items/9915f5ae3953a9c2c14b)

クエリはこんな感じ。  
Standard SQL を使っている。

```sql
SELECT
  time,
  name,
  value / 1024 / 1024 AS size
FROM
  `PROJECT.docker.metrics_*`
WHERE
  key = 'memory_stat_rss'
ORDER BY
  name,
  time
```

とりあえず全データを対象にしているが、データ量が増えてきたらテーブル名を日付で絞ったほうが良いかもしれない。

あとは適当に Visualize の設定を行う。

<img src="/images/visualize-docker-metrics-with-redash/chart-setting.png" width="531" height="608">

<img src="/images/visualize-docker-metrics-with-redash/stack-setting.png" width="526" height="607">

これで先に載せた感じのグラフが出来上がる。

<img src="/images/visualize-docker-metrics-with-redash/chart.png" width="414" height="319">

<img src="/images/visualize-docker-metrics-with-redash/stack-chart.png" width="416" height="342">

## まとめ

グラフ化した結果、メモリを一番使っているのは Re:dash の Worker だということがわかった。
