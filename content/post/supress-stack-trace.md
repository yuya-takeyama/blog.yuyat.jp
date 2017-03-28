+++
date = "2017-03-29T02:21:11+09:00"
title = "Node.js のスタックトレースを控えめにする supress-stack-trace 書いた"

+++
最近仕事で React/Redux で構築されたアプリを触っていて、[mocha](https://mochajs.org/) でテストがコケたときのスタックトレースがうるさい感じだったので `node_modules` 内のエラーを除外するためのものを作ってみた。

* [supress-stack-trace](https://github.com/yuya-takeyama/supress-stack-trace)

<!--more-->

## 使い方

まだ npm には登録してないのでとりあえず GitHub から直接インストールする必要があります。

```
$ yarn add -D yuya-takeyama/supress-stack-trace
```

使い方は読み込むだけで OK

```
require('supress-stack-trace')
```

mocha の場合は `mocha.opts` に `--require supress-stack-trace` とかしてあげるだけでいいと思います。

今の仕事では [mocha-webpack](https://www.npmjs.com/package/mocha-webpack) を使っていて、`mocha-webpack.opts` に同じ感じに指定すればうまくできました。

なお、[source-map-support](https://github.com/evanw/node-source-map-support) のように `Error.prepareStackTrace` をオーバーライドするライブラリを既に使っている場合は、そのあとで読み込むのが良いと思います。ライブラリの組み合わせによっては動かないこともあると思います。

## 使用感

このようにすっきりします。

### Before

```
     Error: aghhhhhhhhhhhh!!!
      at app/components/foo/Foo.jsx:18:11
      at Object.LinkedValueUtils.executeOnChange (node_modules/react-dom/lib/LinkedValueUtils.js:129:1)
      at ReactDOMComponent._handleChange (node_modules/react-dom/lib/ReactDOMInput.js:232:1)
      at Object.invokeGuardedCallback [as invokeGuardedCallbackWithCatch] (node_modules/react-dom/lib/ReactErrorUtils.js:26:1)
      at executeDispatch (node_modules/react-dom/lib/EventPluginUtils.js:83:1)
      at Object.executeDispatchesInOrder (node_modules/react-dom/lib/EventPluginUtils.js:108:1)
      at executeDispatchesAndRelease (node_modules/react-dom/lib/EventPluginHub.js:43:1)
      at executeDispatchesAndReleaseSimulated (node_modules/react-dom/lib/EventPluginHub.js:51:1)
      at forEachAccumulated (node_modules/react-dom/lib/forEachAccumulated.js:26:1)
      at Object.EventPluginHub.processEventQueue (node_modules/react-dom/lib/EventPluginHub.js:255:1)
      at node_modules/react-dom/lib/ReactTestUtils.js:340:1
      at ReactDefaultBatchingStrategyTransaction.TransactionImpl.perform (node_modules/react-dom/lib/Transaction.js:140:1)
      at Object.ReactDefaultBatchingStrategy.batchedUpdates (node_modules/react-dom/lib/ReactDefaultBatchingStrategy.js:62:1)
      at Object.batchedUpdates (node_modules/react-dom/lib/ReactUpdates.js:97:1)
      at node_modules/react-dom/lib/ReactTestUtils.js:338:1
      at ReactWrapper.<anonymous> (node_modules/enzyme/build/ReactWrapper.js:776:1)
      at ReactWrapper.single (node_modules/enzyme/build/ReactWrapper.js:1421:1)
      at ReactWrapper.simulate (node_modules/enzyme/build/ReactWrapper.js:769:1)
      at Context.<anonymous> (test/components/foo/Foo-test.js:168:20)
```

### After

```
     Error: error
      at app/components/foo/Foo.jsx:18:11
      at Context.<anonymous> (test/components/foo/Foo-test.js:168:20)
```

## 仕組み

V8 には [Stack Trace API](https://github.com/v8/v8/wiki/Stack-Trace-API) というものがあって、`Error.prepareStackTrace` という関数をセットすることでスタックトレースの出力をいじることができます。

ただこれは API 的にはあまりイケてなくて、エラーとスタックトレースを受け取って文字列を返す関数なので、チェインすることはちょっと難しい感じです。

`source-map-support` も `Error.prepareStackTrace` をセットしているので、既にセットされた関数があった場合は、その出力の文字列から `node_modules/` と含まれた行だけ消す、みたいなことをしています。

なので例えばエラーメッセージに `node_modules/` と含まれていた場合はそこまで省略されてしまいます。 (気が向いたらなおす)

## その他

あとはやっぱり環境変数で supress しないモードとかもあったらいいと思うんですが、いい名前が思いつかないのでとりあえず後回し。

思いついたら npm に公開しようと思います。
