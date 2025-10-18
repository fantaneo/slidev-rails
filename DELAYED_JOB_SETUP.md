# Delayed Job ワーカーセットアップガイド

## ⚠️ 重要: 正しい実行コマンド

`bundle exec delayed_job` は**動作しません**。代わりに以下のコマンドを使用してください：

### ✅ 正しい実行方法

```bash
./bin/delayed_job start|stop|restart|run
```

## ローカル開発環境での実行

### 1. ワーカーをバックグラウンドで起動

```bash
# 別のターミナルウィンドウで実行
./bin/delayed_job start

# または環境を指定して実行
./bin/delayed_job -e development start
```

### 2. ワーカーログを確認

```bash
tail -f log/delayed_job.log
```

### 3. ワーカーを停止

```bash
./bin/delayed_job stop
```

### 4. ワーカーを再起動

```bash
./bin/delayed_job restart
```

### 5. ワーカーをフォアグラウンドで実行（開発用）

```bash
# プロセスをバックグラウンド化せず、コンソールで実行
# ログがリアルタイムで表示される
./bin/delayed_job run
```

## Docker環境での実行

### Docker Composeで単発実行

```bash
# ワーカーを起動
docker-compose exec web ./bin/delayed_job start

# ワーカーを停止
docker-compose exec web ./bin/delayed_job stop

# ワーカーを再起動
docker-compose exec web ./bin/delayed_job restart

# ワーカーログを確認
docker-compose exec web tail -f log/delayed_job.log
```

### Docker Composeに専用ワーカーサービスを追加

`docker-compose.yml` を以下のように修正してください：

```yaml
version: '3.8'

services:
  web:
    # ... existing web service configuration ...

  delayed_job:
    build: .
    command: ./bin/delayed_job run
    environment:
      - RAILS_ENV=development
      - DATABASE_URL=sqlite3:db/development.sqlite3
    volumes:
      - .:/app
      - bundle:/bundle
      - node_modules:/app/node_modules
      - slidev_projects:/app/slidev_projects
      - public_slides:/app/public/slides
    depends_on:
      - web
    restart: unless-stopped
    # 複数のワーカーを起動する場合
    # command: ./bin/delayed_job -n 2 run

volumes:
  bundle:
  node_modules:
  slidev_projects:
  public_slides:
```

起動:
```bash
docker-compose up -d delayed_job
```

ログ確認:
```bash
docker-compose logs -f delayed_job
```

## よくあるエラーと解決方法

### エラー: `bundler: command not found: delayed_job`

**原因**: `bundle exec delayed_job` を使用しようとした

**解決方法**: 代わりに以下を実行してください：
```bash
./bin/delayed_job start
```

### エラー: `command not found: ./bin/delayed_job`

**原因**: ファイルが実行可能ではない、または存在しない

**解決方法**: 
```bash
# 実行可能にする
chmod +x bin/delayed_job

# ファイルが存在するか確認
ls -la bin/delayed_job
```

### エラー: `PID file not writeable`

**原因**: 一般ユーザーがPIDファイルを書き込めない

**解決方法**:
```bash
# tmp/pidディレクトリを作成
mkdir -p tmp/pids

# Docker環境の場合
docker-compose exec web mkdir -p tmp/pids
```

## ワーカーの詳細オプション

```bash
# 複数ワーカーを起動（4つのワーカー）
./bin/delayed_job -n 4 start

# 優先度を指定
./bin/delayed_job --min-priority 0 --max-priority 100 start

# 特定のキューのみ処理
./bin/delayed_job --queues=default,urgent start

# プロセスIDディレクトリを指定
./bin/delayed_job --pid-dir=/tmp start

# ログディレクトリを指定
./bin/delayed_job --log-dir=/app/log start

# ワーカープロセスに識別子をつける
./bin/delayed_job -i 1 start
./bin/delayed_job -i 2 start
```

## 運用での確認方法

### ジョブキューの確認

```bash
rails console

# キューに入っているジョブ数
Delayed::Job.count

# 保留中のジョブ
Delayed::Job.where('run_at > ?', Time.now).count

# 失敗したジョブ
Delayed::Job.where('failed_at IS NOT NULL').count

# 最新のジョブを確認
Delayed::Job.last.inspect

# 特定のジョブを確認
Delayed::Job.find(1).inspect
```

### プロセスの確認

```bash
# ワーカープロセスが実行しているか確認
ps aux | grep delayed_job

# ワーカープロセス数を確認
ps aux | grep delayed_job | grep -v grep | wc -l
```

### ログの確認

```bash
# リアルタイムでログを表示
tail -f log/delayed_job.log

# 最新100行を表示
tail -n 100 log/delayed_job.log

# エラーのみ表示
grep ERROR log/delayed_job.log

# 特定の期間のログを表示
grep "2025-10-18" log/delayed_job.log
```

## 本番環境での推奨事項

1. **複数ワーカーの起動**
   ```bash
   ./bin/delayed_job -n 4 start
   ```

2. **Systemdサービス化**（Linux）
   ```ini
   [Unit]
   Description=Delayed Job Worker
   After=network.target
   
   [Service]
   Type=simple
   WorkingDirectory=/app
   ExecStart=/app/bin/delayed_job run
   Restart=always
   
   [Install]
   WantedBy=multi-user.target
   ```

3. **モニタリング**
   - ワーカープロセスの定期的な確認
   - ジョブの失敗率の監視
   - ログファイルのローテーション

4. **バックアップ**
   - 定期的にジョブログをバックアップ
