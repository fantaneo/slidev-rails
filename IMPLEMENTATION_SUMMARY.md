# 非同期処理実装サマリー

## 実装日: 2025年10月18日

### 概要
SlidevプロジェクトのビルドとエクスポートをActive Job + Delayed Jobを使用して非同期化しました。

### 主な改善点

1. **レスポンス時間の改善**
   - スライド作成時: 同期 → すぐにリダイレクト（ジョブはバックグラウンドで実行）
   - ビルド再実行時: 同期 → すぐにリダイレクト（ジョブはバックグラウンドで実行）

2. **ユーザーエクスペリエンスの向上**
   - ステータスバッジでビルド進行状況を表示
   - ビルド中のスライドは操作不可に（整合性を保証）
   - エラーメッセージをUIに表示

3. **スケーラビリティの向上**
   - 複数のワーカープロセスで並行処理が可能
   - SQLiteのDelayed Jobでジョブを永続化

## 変更ファイル一覧

### 新規作成ファイル

1. **app/jobs/build_slidev_project_job.rb**
   - スライドの再ビルド処理をカプセル化
   - ステータス管理とエラーハンドリング

2. **app/jobs/create_slidev_project_job.rb**
   - Slidevプロジェクト作成と初期ビルドをカプセル化
   - エラー時のリソースクリーンアップ

3. **db/migrate/20251018062548_add_status_to_slides.rb**
   - `status`カラム（pending/building/completed/failed）を追加
   - `error_message`カラムを追加
   - `status`カラムにインデックスを作成

4. **db/migrate/20251018062603_create_delayed_jobs.rb**
   - Delayed Jobのテーブルを作成（自動生成）

5. **ASYNC_IMPLEMENTATION.md**
   - 非同期処理の詳細実装ガイド
   - ワーカー管理方法
   - トラブルシューティング

6. **bin/delayed_job**
   - Delayed Jobワーカー起動スクリプト（自動生成）

### 修正ファイル

1. **Gemfile**
   - `delayed_job_active_record` gem を追加
   - `daemons` gem を追加

2. **Gemfile.lock**
   - 依存関係を更新

3. **app/models/slide.rb**
   - `status`カラムのバリデーション追加
   - ステータススコープ（pending, building, completed, failed）を追加
   - ステータスチェックメソッドを追加（building?, completed?, failed?, pending?）

4. **app/controllers/slides_controller.rb**
   - `create`アクション: ジョブエンキューに変更、同期ビルドを削除
   - `build`アクション: ジョブエンキューに変更、ビルド中チェックを追加
   - `edit`アクション: ビルド中のチェック処理を追加
   - `update`アクション: ビルド中のチェック処理を追加

5. **app/views/slides/index.html.erb**
   - ステータスカラムを追加
   - ステータスバッジを表示（色付き）
   - エラーメッセージを表示
   - ビルド中のスライドは操作ボタンを無効化

6. **config/environments/development.rb**
   - Active Job バックエンドを `delayed_job` に設定

7. **README.md**
   - 非同期処理について説明を追加
   - ビルドステータスの説明を追加
   - ワーカー起動方法を説明
   - Docker環境でのワーカー実装例を追加
   - 技術スタックにDelayed Jobを追加

## データベーススキーマの変更

### slidesテーブルに追加されたカラム

| カラム名 | 型 | デフォルト値 | 説明 |
|---------|-----|------------|------|
| status | string | 'pending' | ビルドステータス |
| error_message | text | NULL | ビルドエラーメッセージ |

### 新規作成テーブル

**delayed_jobs**: Delayed Jobで使用されるジョブキューテーブル
- priority: ジョブの優先度
- attempts: 実行試行回数
- handler: ジョブのシリアライズされたデータ
- last_error: 最後のエラーメッセージ
- run_at: 実行予定時刻
- locked_at: ロック時刻
- failed_at: 失敗時刻
- locked_by: ロック者

## 使用方法

### ローカル開発環境

```bash
# ワーカーを起動（別ターミナル）
bundle exec delayed_job start

# ワーカーログを確認
tail -f log/delayed_job.log

# ワーカーを停止
bundle exec delayed_job stop
```

### Docker環境での実装例

`docker-compose.yml` に以下のサービスを追加：

```yaml
delayed_job:
  build: .
  command: bundle exec delayed_job run
  volumes:
    - .:/app
    - bundle:/bundle
    - slidev_projects:/app/slidev_projects
    - public_slides:/app/public/slides
  environment:
    - RAILS_ENV=development
    - DATABASE_URL=sqlite3:db/development.sqlite3
  depends_on:
    - web
```

## テスト方法

1. **Webインターフェースでテスト**
   - http://localhost:3000 にアクセス
   - 「新規作成」でスライドを作成
   - ステータスが「準備中」→「ビルド中」→「完了」に変わることを確認
   - ビルド中に編集・ビルド・削除ボタンが無効化されることを確認

2. **Railsコンソールでテスト**
   ```ruby
   rails console
   
   # ジョブをキューに入れる
   BuildSlidevProjectJob.perform_later(slide_id)
   
   # キューに入っているジョブ数を確認
   Delayed::Job.count
   
   # ジョブの詳細を確認
   Delayed::Job.last.inspect
   ```

## パフォーマンス上の注意点

1. **メモリ使用量**
   - 各ワーカーあたり約4.5GB（Node.jsと合わせて）
   - 複数ワーカーを実行する場合、メモリを十分に確保してください

2. **ジョブ実行順序**
   - デフォルトは FIFO（First In First Out）
   - 同じ優先度のジョブは順序通り実行

3. **スケーリング**
   - 複数ワーカーで並行処理が可能
   - `bundle exec delayed_job -n 4 start` で4つのワーカーを起動

## 今後の改善案

- [ ] Sidekiqへの移行（Redis必須）
- [ ] WebSocketでビルド進捗をリアルタイム通知
- [ ] ビルド完了時のメール通知
- [ ] 定期的なジョブクリーンアップ
- [ ] ジョブの優先度管理

## 動作確認完了

✅ マイグレーション実行完了  
✅ Gem依存関係インストール完了  
✅ ジョブクラス作成完了  
✅ コントローラー修正完了  
✅ ビュー修正完了  
✅ 設定ファイル修正完了  
✅ スキーマ更新完了  

すべての変更が正常に反映されています。
