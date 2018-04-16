---
title: "bundle install には --clean を指定する (特に Circle CI では)"
date: 2018-04-16T21:28:11+09:00
---

## TL;DR

`bundle install` を `--clean` オプション付きで実行することで、もう使っていない gem や古いバージョンの gem が削除されます。

さもないと、Circle CI 上における Bundler のキャッシュの restore はどんどん遅くなります。

<!--more-->

## 前提

この記事では Circle CI 2.0 において、`store_cache` と `restore_cache` を使って、Bundler の gem をキャッシュしているプロジェクトを対象としています。

## キャッシュの restore が遅い！！

ある日ふと、Circle CI におけるキャッシュの restore にすごく時間がかかっていることに気づきました。

その時のプロジェクトにおいては Bundler のキャッシュだけでなんと **1.2 GB**、時間にして **2 分** もかかっていました。
そのプロジェクトは Workflow が三段階になっていたので、全体で 2 x 3 = **6 分** もキャッシュの restore にかかっていることになります。

素の状態から `bundle install` はもっともっと時間がかかるので、これでも意味なくはないけど、もっと速くしたいですね。

## 起きていた問題

`bundle install` では、`Gemfile` から削除された gem であったり、バージョンアップ前の古い gem を削除することなく、ディレクトリ中に保持します。

そのため、プロジェクトを続けていると、主に gem をアップデートするごとに、もう使っていない gem がどんどん増えて行くことになります。

Circle CI の場合、ディレクトリ内を丸ごとキャッシュするので、gem のアップデート時にも古いバージョンが残ったまま、また新たにキャッシュを store し直すことになるため、キャッシュが時間を追うごとに肥大化します。

## キャッシュをクリアしてみる

とりあえずキャッシュキーを変更することで、丸ごとキャッシュをクリアしてみました。

キャッシュの設定は以下のようになっていました。

```yaml
    steps:
      - checkout
      - restore_cache:
          keys:
            - v1-api-bundle-{{ arch }}-{{ checksum "Gemfile.lock" }}
            - v1-api-bundle-
      - run: bundle check --path=vendor/bundle || bundle install --path=vendor/bundle --jobs=4 --retry=3
      - save_cache:
          key: v1-api-bundle-{{ arch }}-{{ checksum "Gemfile.lock" }}
          paths:
            - ~/api/vendor/bundle
```

キーの prefix の `v1-` を `v2-` に変更することで、キャッシュがヒットしなくなるので、とりあえずキャッシュがクリアされました。

一度キャッシュをゼロから再生成した後、`restore_cache` を確認したところ、ファイルサイズが **154MB**、restore にかかる時間は **11 秒** と、大幅に改善されました。

## 別の方法を検討してみる

とりあえずキャッシュをクリアすることで restore の時間を大幅に改善することはわかりましたが、いつのまにか遅くなっていって、気づいた頃に手動でクリアする、というのはダルいですね。

というわけでいいオプションが Bundler にないものかと `bundle install --help` したところ、良さそうななオプションが見つかりました。

```
--clean
       On finishing the installation Bundler is going to remove any gems not present in the current Gemfile(5). Don't worry, gems currently in use will not be removed.
```

こちらが意図している通りの挙動なのか、試してみましょう。

まずは以下のような `Gemfile` を用意します。あとでアップデートするために、あえて現時点でやや古いバージョンを指定します。

```rb
source 'https://rubygems.org'

gem 'concurrent-ruby', '1.0.0'
```

この状態で `bundle install --path=vendor/bundle` し、ディレクトリ内をチェックします。


```
$ bundle install --path=vendor/bundle
Fetching gem metadata from https://rubygems.org/..
Resolving dependencies...
Using bundler 1.16.1
Fetching concurrent-ruby 1.0.0
Installing concurrent-ruby 1.0.0
Bundle complete! 1 Gemfile dependency, 2 gems now installed.
Bundled gems are installed into `./vendor/bundle`

$ ls -l vendor/bundle/ruby/2.5.0/gems/
total 0
drwxr-xr-x  6 yuya  staff  204 Apr 16 21:24 concurrent-ruby-1.0.0
```

ここまではいいですが、ここで `Gemfile` 中のバージョンを `'1.0.5'` に変えてもう一度 `bundle install` し、もう一度ディレクトリの中身を確認してみましょう。

```
$ bundle install --path=vendor/bundle
Fetching gem metadata from https://rubygems.org/..
Resolving dependencies...
Using bundler 1.16.1
Using concurrent-ruby 1.0.5 (was 1.0.0)
Bundle complete! 1 Gemfile dependency, 2 gems now installed.
Bundled gems are installed into `./vendor/bundle`

$ ls -l vendor/bundle/ruby/2.5.0/gems/
total 0
drwxr-xr-x  6 yuya  staff  204 Apr 16 23:10 concurrent-ruby-1.0.0
drwxr-xr-x  6 yuya  staff  204 Apr 16 23:09 concurrent-ruby-1.0.5
```

やはりバージョン違いの同一 gem が重複してしまいました。

ここで `--clean` オプション付きでやってみます。

```
$ bundle install --path=vendor/bundle --clean
Using bundler 1.16.1
Using concurrent-ruby 1.0.5
Bundle complete! 1 Gemfile dependency, 2 gems now installed.
Bundled gems are installed into `./vendor/bundle`
Removing concurrent-ruby (1.0.0)

$ ls -l vendor/bundle/ruby/2.5.0/gems/
total 0
drwxr-xr-x  6 yuya  staff  204 Apr 16 23:13 concurrent-ruby-1.0.5
```

古いバージョンが消えました！

なお、一度 `--clean` で実行すると、設定が `.bundle/config` に保存され、次回以降は `--clean` なしでも同じ挙動になるようです。

## まとめ

Ruby/Bundler ではこのようになっていましたが、他のパッケージマネージャーでも同様の問題には気をつけた方が良いでしょう。

JavaScript における `yarn` はデフォルトで同じような挙動になるので、気にする必要はないと思います。

`--path` を指定している場合は基本的に思考停止で `--clean` を指定するのが良いでしょう。

逆に `--path` を指定せずに、グローバルに gem を共有している場合はおそらく `--clean` を使わない方が良いと思います。意図せず別プロジェクトではまだ使っている gem を消しちゃうので。
