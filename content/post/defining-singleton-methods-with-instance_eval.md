+++
date = "2016-12-25T04:29:36+09:00"
title = "instance_eval で特異メソッドを定義する"

+++
最近 [Flagship](https://github.com/yuya-takeyama/flagship) という機能フラグを Ruby の言語内 DSL で定義する gem を作っていて、その中で出てきた DSL 定義パターンっぽいものをメモ。

## 特異メソッド

特異メソッドというのはインスタンスメソッドとは違って特定のオブジェクト固有のメソッドです。

普通は以下のように定義します。

```
class Foo
end

foo = Foo.new

# Foo オブジェクトに定義
def foo.bar
  puts "bar!"
end

foo.bar
# => bar!

# Foo クラスの Class オブジェクトに定義
def Foo.baz
  puts "baz!"
end

Foo.baz
# => baz!
```

## 特異メソッドを instance_eval で

で、本題ですが、これを `instance_eval` でも定義できることに気づいたという話。

```rb
class Foo
end

foo = Foo.new
foo.instance_eval do
  def bar
    puts "bar!"
  end
end

foo.bar
# => bar!

foo2 = Foo.new
foo2.bar
# => NoMethodError
```

このように最初の `foo` では `#bar` を呼び出すことはできましたが、別オブジェクトである `foo2` に対しては呼び出せないので、`Foo` クラスのインスタンスメソッドではなく `foo` の特異メソッドであることがわかります。

## DSL に応用する


