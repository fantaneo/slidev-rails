# Slidev Manager

SlidevとRuby on Railsを用いたプレゼンテーション用のスライド管理システムです。

## 要件

このプロジェクトは以下の要件を満たしています：

* ✅ Slidevでスライドを作成できること
* ✅ Slidevのスライド（プロジェクト）を追加・削除できること
* ✅ SlidevのスライドはURL指定で行えること（例: `http://localhost:3000/slides/slide-01/`）
* ✅ スライドの編集機能
* ✅ ビルド処理の非同期化（Delayed Jobを使用）
* ✅ ビルドステータスの表示

## 技術スタック

- **Ruby**: 3.2.2
- **Rails**: 7.1.5
- **Database**: SQLite3
- **Node.js**: 20.x以上
- **Slidev**: 0.48.0
- **Background Jobs**: Delayed Job

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

#### 3.5. Delayed Jobワーカーの起動

```bash
# Docker環境でワーカーを起動
docker-compose exec web ./bin/delayed_job start

# ワーカーログを確認
docker-compose logs -f web | grep delayed_job

# ワーカーを停止
docker-compose exec web ./bin/delayed_job stop
```

**注意**: ワーカーをコンテナ内で常に実行させるには、`docker-compose.yml` に専用の `delayed_job` サービスを追加することをお勧めします（[DELAYED_JOB_SETUP.md](./DELAYED_JOB_SETUP.md) 参照）。

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

#### 5. Delayed Jobワーカーの起動（別のターミナルウィンドウ）

```bash
./bin/delayed_job start
```

**注意**: ジョブキューを処理するため、ワーカーは常に実行している必要があります。開発環境ではバックグラウンドで実行してください。

ログを確認する:
```bash
tail -f log/delayed_job.log
```

ワーカーを停止する:
```bash
./bin/delayed_job stop
```

詳細は [DELAYED_JOB_SETUP.md](./DELAYED_JOB_SETUP.md) を参照してください。

## 使い方

### スライドの作成

1. トップページの「新規作成」ボタンをクリック
2. スライド名と説明（任意）を入力
3. 「作成」ボタンをクリック
4. Slidevプロジェクトがバックグラウンドで作成・ビルドされます
5. スライド一覧画面でステータスを確認できます
   - 「準備中」→「ビルド中」→「完了」の順に遷移します

### スライドのステータス確認

スライド一覧画面にそれぞれのスライドのビルドステータスが表示されます：

- **準備中**: スライド作成待ち中
- **ビルド中**: 現在ビルド処理を実行中
- **完了**: ビルドが正常に完了
- **失敗**: ビルドに失敗（エラーメッセージが表示されます）

### スライドの表示

ステータスが「完了」の場合、一覧画面のURL列にあるリンクをクリックすると、ビルドされたスライドが新しいタブで開きます。

URLの形式: `http://localhost:3000/slides/<slug>/`

例: `http://localhost:3000/slides/rails-introduction/`

### スライドの再ビルド

スライドのソースファイルを編集した後、一覧画面の「ビルド」ボタンをクリックすることで、スライドを再ビルドできます。

**注意**: ビルド中のスライドに対しては、編集・ビルド・削除操作はできません。

### スライドの編集

一覧画面の「編集」ボタンをクリックすると、スライドの`slides.md`ファイルをWebエディタで編集できます。

**注意**: ビルド中のスライドは編集できません。ビルドが完了するまでお待ちください。

1. 編集画面を開く
   - 一覧画面の「編集」ボタンをクリック
   
2. Markdownを編集
   - `slides.md`の内容を直接編集
   - Slidev形式の構文に従う
   
3. 保存する
   - 「保存して編集画面を閉じる」ボタンをクリック
   
4. 再ビルドする
   - 編集内容を反映させるため、一覧画面から「ビルド」ボタンをクリック

**注意**: 編集後は必ず「ビルド」ボタンをクリックして、スライドを再ビルドしてください。

### スライドの削除

一覧画面の「削除」ボタンをクリックすると、Slidevプロジェクトとビルド成果物の両方が削除されます。

**注意**: ビルド中のスライドは削除できません。ビルドが完了するまでお待ちください。

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
| status       | string  | ビルドステータス（pending/building/completed/failed） |
| error_message| text    | ビルド失敗時のエラーメッセージ |
| created_at   | datetime| 作成日時                      |
| updated_at   | datetime| 更新日時                      |

### バックグラウンドジョブの処理

このアプリケーションはDelayed Jobを使用して、スライド作成とビルド処理を非同期で実行します：

- **CreateSlidevProjectJob**: Slidevプロジェクトの作成と初期ビルド
- **BuildSlidevProjectJob**: スライドの再ビルド

ジョブはDelayed Job テーブル(`delayed_jobs`)で管理され、キューから順序に従って処理されます。

#### ワーカーの起動

ローカル環境でワーカーを実行するには：

```bash
# ワーカープロセスを起動（ジョブを処理）
bundle exec delayed_job start

# ワーカープロセスを停止
bundle exec delayed_job stop

# ワーカープロセスを再起動
bundle exec delayed_job restart

# ワーカーログを確認
tail -f log/delayed_job.log
```

#### Docker環境でのワーカー実行

Docker Composeを使用している場合、`docker-compose.yml`に以下のようなワーカーサービスを追加できます：

```yaml
delayed_job:
  build: .
  command: bundle exec delayed_job run
  volumes:
    - .:/app
    - bundle:/bundle
    - node_modules:/app/node_modules
    - slidev_projects:/app/slidev_projects
    - public_slides:/app/public/slides
  environment:
    - RAILS_ENV=development
    - DATABASE_URL=sqlite3:db/development.sqlite3
  depends_on:
    - web
```

## 制限事項

- 大量のスライドを同時にビルドする場合、ディスク容量とメモリに注意が必要です

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

- [ ] Delayed Jobワーカーのスケーリング
- [ ] スライドのプレビュー機能
- [ ] テーマのカスタマイズ機能
- [ ] スライドのエクスポート機能（PDF等）
- [ ] 複数ユーザーのサポート

## ライセンス

MIT License

