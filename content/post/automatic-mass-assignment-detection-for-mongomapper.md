+++
date = "2017-04-13T01:14:30+09:00"
title = "MongoMapper で Mass Assignment を自動検出する"

+++
GitHub が [Mass Assignment 脆弱性を突かれて](https://www.infoq.com/jp/news/2012/03/GitHub-Compromised)からもう 5 年も経っているんですね。

`ActiveRecord` (というか `ActiveModel`) では適切に `.permit` したパラメータ以外は `ActiveModel::ForbiddenAttributesError` が発生するようになっていますが、`MongoMapper` ではそうなってなかったので対応させてみました。

<!--more-->

## プラグインの実装

`ActiveModel` の [`ForbiddenAttributesProtection`](https://apidock.com/rails/ActiveModel/ForbiddenAttributesProtection) をそのまま利用します。

```rb
module MongoMapper
  module Plugins
    module ForbiddenAttributesProtection
      extend ActiveSupport::Concern

      included do
        include ::ActiveModel::ForbiddenAttributesProtection
      end

      def attributes=(attrs = {})
        super sanitize_for_mass_assignment(attrs)
      end
    end
  end
end
```

## 利用する

とりあえず `MongoMapper::Document` を `include` した全てのクラスに適用するには以下を呼ぶ。

```rb
MongoMapper::Document.plugin(MongoMapper::Plugins::ForbiddenAttributesProtection)
```

ただし、各クラスが `MongoMapper::Document` を `include` するのより先に実行されている必要があると思います。

もしくは個別のクラスに適用する場合は普通に `include` でも良いです。

```rb
class User
  include MongoMapper::Document
  include MongoMapper::Plugins::ForbiddenAttributesProtection
end
```

これで、適切に `.permit` していない `ActionController::Parameters` をセットしたりしようとすると `ActiveModel::ForbiddenAttributesError` が発生するようになります。

もちろん雑に `.to_h` したりしたものを渡したりするとそれは検出できないので、そういうのは人間が気づく必要があります。
