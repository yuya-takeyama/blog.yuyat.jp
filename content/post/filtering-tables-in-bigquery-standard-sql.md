+++
date = "2016-12-04T23:47:21+09:00"
title = "BigQuery の標準 SQL モードで日付テーブルのフィルタリング、または Re:dash の Query Snippets を活用する話"
images = ["/images/filtering-tables-in-bigquery-standard-sql/setting.png"]

+++
要は Legacy SQL モード で `FROM (TABLE_DATE_RANGE(dataset.table_, TIMESTAMP('2016-01-01'), TIMESTAMP('2016-01-14')))` とか書いていたのを標準 SQL でどう書くか、という話です。  
すぐ忘れるのでメモ。

テーブルは以下のような名前になっている前提です。

* table_20160101
* table_20160102
* table_20160103
* ...

これで例えば直近 14 日分のテーブルを対象にしたい場合はこんな感じ。

```sql
SELECT time
FROM `dataset.table_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY))
```

テーブル名はワイルドカードで指定しつつ、`_TABLE_SUFFIX` という擬似カラムに対して日付の条件を指定する。

詳細は以下の公式ドキュメントを参考にしましょう。

* [Wildcard table syntax](https://cloud.google.com/bigquery/docs/wildcard-tables#wildcard_table_syntax)

よく使うパターンですが、覚えていられない、という人で普段 [Re:dash](https://redash.io/) でクエリを書いている、という人は [v0.12.0](https://github.com/getredash/redash/blob/master/CHANGELOG.md#v0120---2016-11-20) で追加された Query Snippets という機能を使うと、こんな感じにキーワード補完されるようになって便利です。

![query snippets](/images/filtering-tables-in-bigquery-standard-sql/query_snippets.gif)

設定としては以下のようにしておけば `_TABLE_SUFFIX` というキーワードをトリガーに補完されます。

<img src="/images/filtering-tables-in-bigquery-standard-sql/setting.png" width="658" height="257">
