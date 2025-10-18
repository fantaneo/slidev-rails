# 非同期処理の実装ガイド

このドキュメントは、Slidev ManagerのビルドとエクスポートプロセスがActive Job + Delayed Jobを使用して非同期化されたことを説明しています。

## 概要

以前は、スライド作成やビルドリクエスト時にブロッキング処理が発生していました。これにより、ユーザーは処理完了まで待機する必要がありました。

現在は、これらの時間のかかるタスクがバックグラウンドジョブとして非同期で実行されるようになりました。

## アーキテクチャ

### コンポーネント

```
User Request
    ↓
[Rails Controller]
    ↓
Enqueue Job → [Delayed Job DB]
    ↓
Return Response (Immediate)
    ↓
[Delayed Job Worker] (別プロセス)
    ↓
Process Job → Update Status
    ↓
User can refresh to see updated status
```

### 使用技術

- **Active Job**: Railsの標準的なジョブスケジューリングシステム
- **Delayed Job**: SQLiteをバックエンドとするジョブキュー
- **SQLite**: `delayed_jobs`テーブルにジョブを永続化

## ジョブの種類

### 1. CreateSlidevProjectJob

**目的**: 新しいSlidevプロジェクトを作成し、初期ビルドを実行

**フロー**:
```
create_project()
  ↓
write_slides_md()
  ↓
build_project()
  ↓
status = 'completed'
```

**エラーハンドリング**:
- エラー発生時にプロジェクトディレクトリを削除
- status = 'failed'に更新
- error_messageにエラー内容を保存

**パラメータ**:
- `slide_id` (Integer): 処理対象のSlideレコードID
- `initial_content` (String, optional): 初期content (default: "Hello, World!")

### 2. BuildSlidevProjectJob

**目的**: 既存のSlidevプロジェクトを再ビルド

**フロー**:
```
build_project()
  ↓
status = 'completed'
```

**エラーハンドリング**:
- status = 'failed'に更新
- error_messageにエラー内容を保存

**パラメータ**:
- `slide_id` (Integer): 処理対象のSlideレコードID

## ステータス遷移

### スライド作成時

```
[新規作成リクエスト]
  ↓
status = 'pending' (DB保存時)
  ↓
CreateSlidevProjectJob をエンキュー
  ↓
[ユーザーはすぐにリダイレクト]
  ↓
[ワーカーが処理開始]
  ↓
status = 'building'
  ↓
プロジェクト作成・ビルド実行
  ↓
status = 'completed' (成功時)
  OR
status = 'failed' (失敗時)
```

### スライド再ビルド時

```
[ビルドボタンクリック]
  ↓
BuildSlidevProjectJob をエンキュー
  ↓
[ユーザーはすぐにリダイレクト]
  ↓
[ワーカーが処理開始]
  ↓
status = 'building'
  ↓
ビルド実行
  ↓
status = 'completed' (成功時)
  OR
status = 'failed' (失敗時)
```

## UIの状態管理

### スライド一覧ビュー

各スライドに対して以下の情報が表示されます：

1. **ステータスバッジ**
   - 準備中（灰色）
   - ビルド中（黄色）
   - 完了（緑色）
   - 失敗（赤色）

2. **操作ボタンの制御**
   - ビルド中の場合、編集・ビルド・削除は無効化
   - テキスト「ビルド中のため操作不可」が表示される

3. **エラーメッセージ**
   - 失敗時はエラーメッセージを短縮表示
   - ユーザーはエラーの概要を確認可能

### SlidesController での制御

```ruby
# 編集・更新・再ビルドの前に状態チェック
if @slide.building?
  redirect_to slides_path, alert: 'このスライドは現在ビルド中です'
  return
end
```

## ワーカーの管理

### ローカル環境での起動

```bash
# ワーカープロセスを起動
bundle exec delayed_job start

# バックグラウンドで複数ワーカーを起動
bundle exec delayed_job -n 2 start

# ワーカーを停止
bundle exec delayed_job stop

# ワーカーを再起動
bundle exec delayed_job restart

# ログを確認
tail -f log/delayed_job.log
```

### Docker環境での実装例

`docker-compose.yml`に以下を追加：

```yaml
services:
  web:
    # ... existing web service config ...

  delayed_job:
    build: .
    command: bundle exec delayed_job run
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=sqlite3:db/development.sqlite3
    volumes:
      - .:/app
      - bundle:/bundle
      - slidev_projects:/app/slidev_projects
      - public_slides:/app/public/slides
    depends_on:
      - web
    restart: unless-stopped
```

起動:
```bash
docker-compose up -d delayed_job
```

## パフォーマンス上の考慮事項

### ジョブの実行順序

Delayed Jobはデフォルトで以下の順序でジョブを処理：
1. 優先度が高いジョブ
2. 同じ優先度内では FIFO（First In First Out）

現在のデフォルト設定：
- すべてのジョブは優先度 0（デフォルト）
- 1つのワーカープロセスで順序実行

### スケーリング

複数のビルドを並行処理したい場合：

```bash
# 4つのワーカープロセスを起動
bundle exec delayed_job -n 4 start
```

### リソース管理

各ビルドプロセスのメモリ使用量：
- Node.js: 最大4GB（NODE_OPTIONS設定）
- Rails: 約100-200MB
- 合計: ワーカーあたり約4.5GB

複数ワーカーを実行する場合、メモリ容量を確認してください。

## トラブルシューティング

### ジョブが実行されない

1. ワーカープロセスが起動しているか確認：
   ```bash
   ps aux | grep delayed_job
   ```

2. ジョブがキューに存在するか確認：
   ```bash
   rails console
   > Delayed::Job.all.count
   ```

3. ジョブの詳細を確認：
   ```bash
   rails console
   > Delayed::Job.last.inspect
   ```

### ジョブが失敗する

1. ログを確認：
   ```bash
   tail -f log/delayed_job.log
   ```

2. DBでジョブの失敗情報を確認：
   ```bash
   rails console
   > Delayed::Job.where(failed_at: Time.now - 1.day..Time.now)
   ```

### メモリ不足エラー

1. ワーカープロセス数を減らす
2. Node.jsのヒープサイズを調整：
   ```bash
   NODE_OPTIONS='--max-old-space-size=2048' bundle exec delayed_job start
   ```

## 今後の拡張

- [ ] Sidekiqへの移行（より高速、パフォーマンス重視）
- [ ] ジョブの優先度制御
- [ ] ビルド進捗のWebSocket通知
- [ ] 定期的なジョブクリーンアップ
- [ ] メール通知機能（ビルド完了時）
