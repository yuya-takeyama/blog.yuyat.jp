+++
date = "2017-01-09T03:02:40+09:00"
title = "Ruby で週をオブジェクトとして扱うライブラリ ActiveWeek を作った"

+++
仕事で必要があって作ったものから仕事固有の事情とかを取り除いた形で作り直してみた。

* [yuya-takeyama/activeweek](https://github.com/yuya-takeyama/activeweek)

<!--more-->

## インストール

名前が強すぎるので一旦 RubyGems.org への publish はしていない。  
いろんな人に見てもらって良さそうならする予定。

なので `Gemfile` では `github` オプションを使う。

```rb
gem 'activeweek', github: 'yuya-takeyama/activeweek'
```

## 使い方

[README.md](https://github.com/yuya-takeyama/activeweek#activeweek) を訳しただけだけど以下のような感じ。

API がキモのライブラリだと思うので、Ruby ライブラリの API に一家言ある方は[是非お願いします](https://twitter.com/yuya_takeyama)。

### 現在の週を取得

```rb
require 'activeweek'

week = ActiveWeek::Week.current
```

### 特定のタイムゾーンにおける現在の週を取得

```rb
week = Time.use_zone('Asia/Tokyo') { ActiveWeek::Week.current }
```

### 週の中の日付を `Date` オブジェクトとして列挙する

```rb
week.each_day { |date| p date }
```

### 前後の週を取得する

```rb
next_week = week.next_week
prev_week = week.prev_week
```
