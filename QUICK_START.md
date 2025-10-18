# Delayed Job クイックスタート

## ⚠️ 重要な注意点

`bundle exec delayed_job` コマンドは動作しません。代わりに以下を使用してください：

## ✅ 正しいコマンド

### ローカル開発環境

```bash
# ターミナル1: Railsサーバー
bundle exec rails server

# ターミナル2: Delayed Jobワーカー（別のターミナルウィンドウで実行）
./bin/delayed_job start
```

### Docker環境

```bash
# ワーカーを起動
docker-compose exec web ./bin/delayed_job start

# ログを確認
docker-compose logs -f web | grep delayed_job

# ワーカーを停止
docker-compose exec web ./bin/delayed_job stop
```

## 3ステップで始める

### 1. アプリケーションを起動

**ローカル環境:**
```bash
bundle exec rails server
```

**Docker環境:**
```bash
docker-compose up -d
```

### 2. ワーカーを起動

**ローカル環境（別のターミナルで）:**
```bash
./bin/delayed_job start
```

**Docker環境:**
```bash
docker-compose exec web ./bin/delayed_job start
```

### 3. ブラウザでアクセス

```
http://localhost:3000
```

スライドを作成すると、ワーカーが自動的にビルド処理を実行します。

## よくある問題

| 問題 | 原因 | 解決方法 |
|------|------|--------|
| `bundler: command not found: delayed_job` | 誤ったコマンド | `./bin/delayed_job start` を使用 |
| `command not found: ./bin/delayed_job` | 実行可能でない | `chmod +x bin/delayed_job` を実行 |
| ジョブが実行されない | ワーカーが起動していない | `./bin/delayed_job start` で起動 |
| ワーカーが落ちている | エラーが発生 | `./bin/delayed_job run` でログを確認 |

## 詳細情報

より詳しい情報は [DELAYED_JOB_SETUP.md](./DELAYED_JOB_SETUP.md) をご覧ください。
