#!/bin/bash
set -e

# PIDファイルが残っている場合は削除
if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle install

# データベースが存在しない場合は作成とマイグレーションを実行
if [ ! -f db/development.sqlite3 ]; then
  echo "データベースを初期化しています..."
  bundle exec rails db:create
  bundle exec rails db:migrate
else
  echo "データベースが存在します。マイグレーションをチェックしています..."
  bundle exec rails db:migrate:status || bundle exec rails db:migrate
fi

# 必要なディレクトリを確認
mkdir -p slidev_projects public/slides log tmp/pids tmp/sockets tmp/cache

# 渡されたコマンドを実行
exec "$@"

