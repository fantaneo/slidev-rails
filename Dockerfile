# Rails + Node.js環境を構築
FROM ruby:3.2.2

# 必要なパッケージのインストール
RUN apt-get update -qq && \
    apt-get install -y \
    nodejs \
    npm \
    build-essential \
    libsqlite3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node.jsのバージョンを20.xにアップグレード
RUN npm install -g n && \
    n 20 && \
    hash -r

# 作業ディレクトリを設定
WORKDIR /app

# Gemfileをコピーしてbundle install
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && \
    bundle install

# package.jsonをコピーしてnpm install
COPY package*.json ./
RUN npm install

# アプリケーションのソースコードをコピー
COPY . .

# 必要なディレクトリを作成
RUN mkdir -p tmp/pids tmp/sockets tmp/cache slidev_projects public/slides log

# entrypointスクリプトに実行権限を付与
RUN chmod +x /app/bin/docker-entrypoint.sh

# ポート3000を公開
EXPOSE 3000

# エントリーポイントを設定
ENTRYPOINT ["/app/bin/docker-entrypoint.sh"]

# デフォルトコマンド
CMD ["rails", "server", "-b", "0.0.0.0"]

