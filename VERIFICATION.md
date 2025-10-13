# ビルドエラーメッセージ改善 - 検証ドキュメント

## 変更概要

slides.mdの構文エラー時に、ユーザーにとって有用なエラーメッセージを表示するように改善しました。

### 変更前の問題点

ビルドエラー時に以下のような技術的なスタックトレースが表示されていました：

```
ビルドエラー: Slidevのビルドに失敗しました。終了コード: 1 
最後のログ: '/Users/.../node_modules/@vue/devtools-api/lib/esm/api/util.js', 
'/Users/.../node_modules/@antfu/utils/dist/index.mjs', ... 168 more items ], 
[Symbol(augmented)]: true }
```

これでは、実際のエラー原因がユーザーに伝わりません。

### 変更後の改善点

ビルドエラー時に、以下のようなユーザーフレンドリーなメッセージを表示するようになりました：

```
Slidevのビルドに失敗しました:

slides.md__slidev_1.md (5:1): Element is missing end tag.
エラー箇所: slides.md の 5行目、1列目付近
ヒント: HTMLタグが正しく閉じられていません。<div>には</div>が必要です。

slides.mdの構文を確認してください。
```

## 実装内容

### 修正ファイル

- `app/services/slidev_project_service.rb`

### 追加されたメソッド

1. **`extract_build_error(log_file, slug)`**
   - ビルドログファイルから実際のエラー原因を抽出します
   - Viteエラーと一般的なエラーの両方を処理します

2. **`extract_vite_error(lines, slug)`**
   - Vite/Vueのコンパイルエラーを抽出します
   - エラーメッセージ、ファイル名、行番号、列番号を特定します
   - エラーの種類に応じたヒントを追加します

3. **`extract_general_error(lines)`**
   - Viteエラー以外の一般的なエラーを抽出します
   - "Error:"や"ERROR"キーワードを含む行を検出します

4. **`get_error_hint(error_message)`**
   - エラーメッセージに基づいて、解決のためのヒントを提供します
   - 以下のエラーパターンに対応：
     - "Element is missing end tag" → HTMLタグの閉じ忘れ
     - "Unexpected token" → 構文エラー、Markdown記法の誤り
     - "Cannot find module" → モジュールの欠落

## テスト方法

### 1. 構文エラーのあるslides.mdでビルドを試行

```bash
# slides.mdから</div>を削除してエラーを発生させる
cd slidev_projects/hoge
# 意図的に<div>タグを閉じないようにslides.mdを編集

# Railsコンソールからビルドを実行
bin/rails runner "slide = Slide.find_by(slug: 'hoge'); service = SlidevProjectService.new; service.build_project(slide) if slide"
```

### 2. エラーメッセージの確認

以下のような分かりやすいエラーメッセージが表示されることを確認：

```
Slidevのビルドに失敗しました:

slides.md__slidev_1.md (5:1): Element is missing end tag.
エラー箇所: slides.md の 5行目、1列目付近
ヒント: HTMLタグが正しく閉じられていません。<div>には</div>が必要です。

slides.mdの構文を確認してください。
```

### 3. ログファイルの確認

詳細なビルドログは以下のファイルに保存されます：

```bash
cat log/slidev_build_<slug>.log
```

## 対応するエラーパターン

### 1. Vite/Vueコンパイルエラー

- **パターン**: `[vite:vue]` または `SyntaxError:` を含む行
- **抽出情報**:
  - エラーメッセージ本文
  - ファイル名（slides.md）
  - 行番号・列番号
  - 解決のヒント

### 2. 一般的なエラー

- **パターン**: `Error:`, `ERROR`, `failed` を含む行
- **抽出情報**: エラーメッセージの最初の5行

### 3. 不明なエラー

- エラーが特定できない場合は、ログファイルへのパスを表示

## エラーヒントの一覧

| エラーパターン | ヒント |
|----------------|--------|
| Element is missing end tag | HTMLタグが正しく閉じられていません。`<div>`には`</div>`が必要です。 |
| Unexpected token | 構文エラーがあります。Markdown記法やコードブロックの閉じ忘れを確認してください。 |
| Cannot find module | モジュールが見つかりません。package.jsonの依存関係を確認してください。 |

## 今後の改善案

1. **スライド番号の特定**
   - `slides.md__slidev_1.md` の番号から、実際のスライドページを特定する
   - 「スライド1ページ目でエラー」のようにより具体的な情報を提供

2. **エラーコンテキストの表示**
   - エラー箇所の前後数行を表示して、問題の特定を容易にする

3. **複数エラーの対応**
   - 1つのビルドで複数のエラーが発生する場合の対応

4. **エラーパターンの拡充**
   - より多くのエラーパターンに対応したヒントの追加

## 関連ドキュメント

- [README.md](README.md) - プロジェクト全体のドキュメント
- [action-plan.md](action-plan.md) - プロジェクトの実装計画
- [BUGFIX.md](BUGFIX.md) - バグ修正の記録

## 変更日時

2025年10月13日

## 検証者

AI Assistant (Claude Sonnet 4.5)
