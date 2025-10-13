# Slidev Manager

SlidevとRuby on Railsを用いたプレゼンテーション用のスライド管理システムです。

## 要件

このプロジェクトは以下の要件を満たしています：

* ✅ Slidevでスライドを作成できること
* ✅ Slidevのスライド（プロジェクト）を追加・削除できること
* ✅ SlidevのスライドはURL指定で行えること（例: `http://localhost:3000/slides/slide-01/`）

## 技術スタック

- **Ruby**: 3.2.2
- **Rails**: 7.1.5
- **Database**: SQLite3
- **Node.js**: 20.x以上
- **Slidev**: 0.48.0

## セットアップ

### Docker を使用する場合（推奨）

Dockerを使用すると、環境構築が簡単になり、すぐに開始できます。

#### 前提条件

- Docker Desktop がインストールされていること
- Docker Compose が利用可能であること

#### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd rails-slidev
```

#### 2. Dockerコンテナの起動

```bash
docker-compose up -d
```

初回起動時は、Dockerイメージのビルドと依存関係のインストールが行われるため、数分かかる場合があります。

#### 3. アプリケーションへのアクセス

ブラウザで `http://localhost:3000` にアクセスしてください。

#### その他のDockerコマンド

```bash
# コンテナを停止
docker-compose down

# ログを確認
docker-compose logs -f web

# Railsコンソールを起動
docker-compose exec web bundle exec rails console

# データベースをリセット
docker-compose exec web bundle exec rails db:reset

# コンテナに入る（シェルアクセス）
docker-compose exec web bash

# イメージを再ビルド（Gemfileやpackage.json変更時）
docker-compose build --no-cache
docker-compose up -d
```

### ローカル環境で直接実行する場合

Dockerを使用せず、ローカル環境で直接実行することもできます。

#### 前提条件

- Ruby 3.2.2
- Node.js 20.x以上
- SQLite3

#### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd rails-slidev
```

#### 2. 依存関係のインストール

**Ruby依存関係**

```bash
bundle install --path vendor/bundle
```

**Node.js依存関係**

```bash
npm install
```

#### 3. データベースのセットアップ

```bash
bundle exec rails db:migrate
```

#### 4. サーバーの起動

```bash
bundle exec rails server
```

ブラウザで `http://localhost:3000` にアクセスしてください。

## 使い方

### スライドの作成

1. トップページの「新規作成」ボタンをクリック
2. スライド名と説明（任意）を入力
3. 「作成」ボタンをクリック
4. Slidevプロジェクトが自動的に作成され、ビルドされます（数分かかる場合があります）

### スライドの表示

一覧画面のURL列にあるリンクをクリックすると、ビルドされたスライドが新しいタブで開きます。

URLの形式: `http://localhost:3000/slides/<slug>/`

例: `http://localhost:3000/slides/rails-introduction/`

### スライドの再ビルド

スライドのソースファイルを編集した後、一覧画面の「ビルド」ボタンをクリックすることで、スライドを再ビルドできます。

### スライドの削除

一覧画面の「削除」ボタンをクリックすると、Slidevプロジェクトとビルド成果物の両方が削除されます。

## ディレクトリ構成

```
rails-slidev/
├── app/
│   ├── controllers/
│   │   └── slides_controller.rb      # スライド管理のコントローラー
│   ├── models/
│   │   └── slide.rb                  # スライドモデル
│   ├── services/
│   │   └── slidev_project_service.rb # Slidevプロジェクト管理サービス
│   └── views/
│       └── slides/                   # スライド管理のビュー
├── config/
│   ├── routes.rb                     # ルーティング設定
│   └── database.yml                  # データベース設定
├── db/
│   └── migrate/                      # マイグレーションファイル
├── public/
│   └── slides/                       # ビルドされたスライドの配置先
├── slidev_projects/                  # Slidevソースプロジェクト
└── package.json                      # Node.js依存関係
```

## 実装の詳細

### Slidevプロジェクトの管理

- 各スライドは `slidev_projects/` ディレクトリ内に個別のSlidevプロジェクトとして保存されます
- スライド作成時に `npm create slidev@latest` コマンドで初期化されます
- ビルド時に `npm run build` でSPA（Single Page Application）として出力されます

### ビルド成果物の配信

- ビルドされたスライドは `public/slides/<slug>/` に配置されます
- Railsの静的ファイル配信機能により、`/slides/<slug>/` でアクセス可能になります
- Slidevのビルド時に `--base` オプションでベースパスを指定しています

### エラーハンドリング

- ビルドエラー時には、ユーザーフレンドリーなエラーメッセージを表示します
- slides.mdの構文エラーの場合、エラー箇所（行番号・列番号）とヒントを表示します
- 詳細なビルドログは `log/slidev_build_<slug>.log` に保存されます

### データベース構造

**slidesテーブル:**

| カラム       | 型      | 説明                          |
|--------------|---------|-------------------------------|
| id           | integer | 主キー                        |
| name         | string  | スライド名                    |
| slug         | string  | URL用のスラッグ（ユニーク）   |
| project_path | string  | Slidevプロジェクトのパス      |
| description  | text    | スライドの説明（任意）        |
| created_at   | datetime| 作成日時                      |
| updated_at   | datetime| 更新日時                      |

## 制限事項

- スライドの作成・ビルドは同期処理のため、完了まで待機が必要です
- 大量のスライドを作成する場合、ディスク容量に注意が必要です
- スライドの編集機能は含まれていません（直接 `slidev_projects/` 内のファイルを編集してください）

## Docker環境について

### ボリュームの管理

Docker環境では、以下のデータがボリュームとして永続化されています：

- `slidev_projects`: Slidevプロジェクトのソースファイル
- `public_slides`: ビルドされたスライド
- `db`: SQLiteデータベース
- `node_modules`: Node.js依存関係
- `bundle`: Ruby gem依存関係

### ボリュームの削除

すべてのデータをクリーンアップする場合：

```bash
docker-compose down -v
```

**注意**: このコマンドは、作成したスライドもすべて削除されます。

### トラブルシューティング

#### ポート3000が使用中の場合

`docker-compose.yml` の `ports` セクションを変更してください：

```yaml
ports:
  - "8080:3000"  # ホスト側を8080に変更
```

#### パーミッションエラーが発生する場合

コンテナ内でファイルの所有権を修正：

```bash
docker-compose exec web chown -R $(id -u):$(id -g) /app
```

#### メモリ不足エラー（heap out of memory）が発生する場合

Slidevのビルド時にメモリ不足が発生する場合、以下の対策が実装されています：

- **Node.jsヒープメモリ**: 4GB（`NODE_OPTIONS=--max-old-space-size=4096`）
- **コンテナメモリ制限**: 6GB

Docker Desktopのメモリ割り当てが不足している場合は、Docker Desktopの設定から増やしてください：

1. Docker Desktop → Settings → Resources → Memory
2. 推奨: 8GB以上に設定

## 今後の改善案

- [ ] ビルド処理の非同期化（Sidekiqなどのジョブキュー使用）
- [ ] スライドの編集インターフェース
- [ ] ビルドステータスの表示
- [ ] プレビュー機能
- [ ] テーマのカスタマイズ機能
- [ ] スライドのエクスポート機能（PDF等）

## ライセンス

MIT License

