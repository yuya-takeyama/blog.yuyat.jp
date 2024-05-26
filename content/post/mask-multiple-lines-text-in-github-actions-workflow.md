+++
date = "2024-05-26T22:00:00+09:00"
title = "GitHub Actions の Workflow 内で複数行の文字列をマスクする"

+++
## tl; dr

バッドノウハウ感が強いですが、以下のワンライナーで `$multiple_lines_text` の中身をマスクすることが可能です。

```yaml
      - run: |
          echo "::add-mask::$(echo "$multiple_lines_text" | sed ':a;N;$!ba;s/%/%25/g' | sed ':a;N;$!ba;s/\r/%0D/g' | sed ':a;N;$!ba;s/\n/%0A/g')"
```

<!--more-->

## GitHub Actions における add-mask コマンド

GitHub Actions には workflow commands という機能があります。

* [Workflow commands for GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions)

`add-mask` コマンドは以降の出力上の特定の文字列をマスクするのに使われます。例えば、以下のようなコマンドを実行することで、以降の出力上の「Hello, World!」は「***」にマスクされます。

```
echo "::add-mask::Hello, World!"
```

Secretから取り出した値についてもこのようにマスクされるのですが、`add-mask` コマンドを使うことで、動的にマスクすべき文字列を指定することが可能になります。

また、このコマンドは [@actions/core](https://github.com/actions/toolkit/tree/main/packages/core) という NPM パッケージにも実装されており、JavaScript コード内で `core.setSecret('Hello, World!');` などとすることで同様のことが可能です。

この `setSecret` 関数も、内部的には `::add-mask::~~~` という文字列をいい感じに組み立てて標準出力に出力しているだけなので、仕組みとしては全く同一ということになります。

## 複数行をマスクする時の問題

シェルスクリプト上で何も考えず `Foo\nBar\nBaz` という感じの文字列へのマスクを試みると、以下のようになるでしょう。

```
::add-mask::Foo
Bar
Baz
```

このように途中で改行が入ることによりコマンドが壊れてしまい、これでは Foo だけしかマスクされません。これでは「Foo Fighters」という文字列が「*** Fighters」になってしまうという、不要な副作用もあります。

複数文字列の取り扱いについて、上記の workflow commands のドキュメントには一応言及が見つかります。

* [Multiline strings](https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings)

ですが、これらは `$GITHUB_ENV` や `$GITHUB_OUTPUT` に複数行の環境変数・output 値を入力するのには使えますが、自分が試した限りでは workflow commands には使えないようでした。

## `core.setSecret` のコードを読んでみる

@actions/core の `core.setSecret` 関数の中身を読んでみると、マスクする値が `escapeData` という関数でエスケープされているらしいことが読み取れます。

https://github.com/actions/toolkit/blob/d1df13e178816d69d96bdc5c753b36a66ad03728/packages/core/src/command.ts#L80-L85

```ts
function escapeData(s: any): string {
  return toCommandValue(s)
    .replace(/%/g, '%25')
    .replace(/\r/g, '%0D')
    .replace(/\n/g, '%0A')
}
```

まず、`toCommandValue` は文字列型の場合はそのまま何の加工もせずに返すだけなので無視できます。

https://github.com/actions/toolkit/blob/d1df13e178816d69d96bdc5c753b36a66ad03728/packages/core/src/utils.ts#L11-L18

そして、`replace` メソッドによって `%` は `%25` に、`\r` は `%0D` に、`\n` は `%0A` に置換されています。

試しに以下のようにコマンドを実行してみると、`Foo\nBar\nBaz` が正しくマスクされました。

```sh
echo "::add-mask::Foo%0ABar%0ABaz"
```

そして、このような置換をシェルスクリプト上で行う方法を ChatGPT に質問したりして、以下のような結論に辿り着きました。

```sh
echo "::add-mask::$(echo "$multiple_lines_text" | sed ':a;N;$!ba;s/%/%25/g' | sed ':a;N;$!ba;s/\r/%0D/g' | sed ':a;N;$!ba;s/\n/%0A/g')"
```

`s/%/%25/g` の部分はともかく、その前の `:a;N;$!ba;` の部分は意味がわかりませんね。ChatGPT に質問して、改行を扱うために必要であるということはなんとなくわかりましたが、正確に理解できているとは言えないのでここでは説明しません。

## いつこれが必要なのか

この記事は、用途はさておき「複数行の文字列のマスクはどうやるんだぜ？！」という方々がたどり着けるように、ということで書いていますが、私としては明確なユースケースがあって必要でした。

GitHub App の Private Key を安全に保管して利用するためです。

これを実現するためには、以下のような手順で行う必要があると考えています。

1. Private Key を Base64 でエンコードして、AWS Secrets Manager に保存しておく
2. OIDC を利用して AWS への連携認証を行う
3. Workflow 上で Secret から取り出して、Base64 でデコードして Private Key を得る

ここでは AWS を使う前提で上記のようにしましたが、Google Cloud の場合も Secret Manager 等を使うことで同様のことが実現できるでしょう。 (未検証)

これをより具体的な Workflow に落とし込むと以下のような感じになります。

```yaml
steps:
  - name: Configure AWS credentials
    id: aws-credentials
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::012345678901:role/role-name
      aws-region: ap-northeast-1

  - name: Retrieve secret from AWS Secrets Manager
    id: aws-secrets
    run: |
      secrets=$(aws secretsmanager get-secret-value --secret-id secret-name --query SecretString --output text)
      gh_app_private_key="$(echo "$secrets" | jq .GH_APP_PRIVATE_KEY_BASE64 -r | base64 -d)"
      echo "::add-mask::$(echo "$gh_app_private_key" | sed ':a;N;$!ba;s/%/%25/g' | sed ':a;N;$!ba;s/\r/%0D/g' | sed ':a;N;$!ba;s/\n/%0A/g')"
      echo "gh-app-private-key<<__EOF__"$'\n'"$gh_app_private_key"$'\n'__EOF__ >> "$GITHUB_OUTPUT"

  - uses: actions/create-github-app-token@v1
    id: app-token
    with:
      app-id: ${{ vars.GH_APP_ID }}
      private-key: ${{ steps.aws-secrets.outputs.gh-app-private-key }}
```

さらに細かい点について、以下に Q&A 形式で説明していきます。

### Organization Secrets や Repository Secrets に入れないのは何故？

安全ではないと考えているからです。

色々と細かい前提はありますが、Secret の値はそのリポジトリに Pull Request を出して GitHub Actions の Workflow のファイルを置くことさえできれば、覗き見ることができてしまいます。

この辺の話について、ちょっと前にイベントで発表しているので、詳しくはこちらを参照してください。 (会社ブログ)

* [AWS知見共有会でTerraformのCI/CDパイプラインのセキュリティ等について発表してきました + GitHub新機能Push rulesについて](https://tech.layerx.co.jp/entry/scalable-and-secure-infrastructure-as-code-pipeline-for-a-compound-startup)

### Private Key をマスクする必要があるのは何故？

マスクしないと、`actions/create-github-app-token@v1` への入力として渡された Private Key が GitHub Actions の UI 上で閲覧可能だからです。

### AWS Secrets Manager に Base64 エンコードをして入れているのは何故？

これは必須ではありませんが、改行なしで AWS Secrets Manager に保存するためです。

AWS Secrets Manager には改行ありのシークレットを保存することもできますが、Management Console 上の Key/value モードでは改行をうまく入力することができません。Plaintext モードでは改行コードとして入力することもできますが、色々面倒なので Base64 エンコードして改行なしで入力した方がマシかなと思ってそうしています。
