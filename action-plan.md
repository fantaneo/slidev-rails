# 実行計画要件

## 要件
Slidevとruby on railsを用いて、プレゼンテーション用のスライドを管理を行いたい。
以下の要件は実現できますか？

* Slidevでスライドを作成できること
* Slidevのスライド（プロジェクト）を追加・削除できること
* SlidevのスライドはURL指定で行えること（ 例: http://localhost:3000/slide-01/）

## 要件の実現可能性について

ご質問いただいた要件について、Slidevとruby on railsを組み合わせた実装の実現可能性を検討します。

### 各要件の実現可能性

**1. Slidevでスライドを作成できること**

これは完全に実現可能です。SlidevはMarkdownベースのスライド作成ツールで、開発者向けに設計されています[1][2]。以下のような特徴があります:

- Markdownでスライドを記述できる
- Vue.jsコンポーネントを埋め込み可能
- リアルタイムプレビュー機能
- PDFやSPAとしてのエクスポートが可能[2]

**2. Slidevのスライド(プロジェクト)を追加・削除できること**

この要件も実現可能です。複数のSlidevプロジェクトを管理する方法として、以下のアプローチが考えられます:

- **モノレポ管理**: yarn workspacesやnpm workspacesを使用して、複数のSlidevプロジェクトを一元管理できます[34][35]
- **Rails側での管理**: Railsアプリケーションでスライドプロジェクトのメタデータ(名前、パス、作成日など)をデータベースで管理し、ファイルシステム上でSlidevプロジェクトを追加・削除する仕組みを構築できます

**3. SlidevのスライドはURL指定で行えること**

この要件の実現には工夫が必要です。Slidevは通常、単一のプロジェクトを`localhost:3030`などで起動しますが[3]、複数のスライドをURL指定で表示するには以下の方法が考えられます:

**実装アプローチ:**

- **静的ファイルとしてビルド**: 各Slidevプロジェクトを静的ファイル(SPA)としてビルドし、Railsの`public`ディレクトリ配下に配置する方法[2][15]
- **Railsのルーティング**: `config/routes.rb`で各スライドへのルーティングを設定し、対応する静的ファイルを提供
- **リバースプロキシ**: 複数のSlidevインスタンスを異なるポートで起動し、Railsからリバースプロキシとして各スライドにアクセスする方法

## 推奨される実装方法

最も実用的なアプローチは以下の構成です:

1. **Slidevプロジェクトの管理**
   - 各スライドを個別のSlidevプロジェクトとして作成
   - プロジェクトをビルドしてSPAとして出力[2]

2. **Railsでの統合**
   - スライドのメタデータをActiveRecordで管理
   - ビルドされたSlidevの静的ファイルを`public/slides/`配下に配置
   - ルーティングで`/slide-01/`などのパスを設定

3. **管理機能の実装**
   - 新規スライド作成時: Slidevプロジェクトのテンプレートを生成し、ビルド
   - 削除時: データベースレコードと静的ファイルを削除
   - 編集時: Slidevの開発サーバーを起動するか、Markdownファイルを直接編集

# SlidevとRuby on Railsを用いたスライド管理システムの実行計画

前回提示した推奨実装方法に基づき、具体的な実行計画を作成します。

## フェーズ1: プロジェクト基盤の構築

### 1.1 Railsプロジェクトの初期化

**タスク:**
- 新規Railsプロジェクトの作成
- SQLite3をデータベースとして設定[5]
- 基本的なディレクトリ構造の構築

**成果物:**
```bash
slidev_manager/
├── app/
├── config/
├── db/
├── lib/
├── public/
│   └── slides/  # Slidevビルド成果物の配置先
└── slidev_projects/  # Slidevプロジェクトの管理ディレクトリ
```

### 1.2 データベース設計

**スライド管理用のモデル設計:**

```ruby
# app/models/slide.rb
class Slide < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :project_path, presence: true
  
  before_validation :generate_slug
  
  private
  
  def generate_slug
    self.slug ||= name.parameterize
  end
end
```

**マイグレーション:**
```ruby
class CreateSlides < ActiveRecord::Migration[7.0]
  def change
    create_table :slides do |t|
      t.string :name, null: false
      t.string :slug, null: false, index: { unique: true }
      t.string :project_path, null: false
      t.text :description
      t.timestamps
    end
  end
end
```

## フェーズ2: Slidev統合の実装

### 2.1 Slidevプロジェクト管理サービスの作成

Railsの設計原則に従い、ビジネスロジックを適切に分離します[3]。

```ruby
# app/services/slidev_project_service.rb
class SlidevProjectService
  PROJECTS_DIR = Rails.root.join('slidev_projects')
  PUBLIC_SLIDES_DIR = Rails.root.join('public', 'slides')
  
  def initialize
    FileUtils.mkdir_p(PROJECTS_DIR)
    FileUtils.mkdir_p(PUBLIC_SLIDES_DIR)
  end
  
  def create_project(name)
    project_path = PROJECTS_DIR.join(name)
    
    # Slidevプロジェクトの初期化
    system("cd #{PROJECTS_DIR} && npm create slidev@latest #{name} -- --template basic")
    
    project_path.to_s
  end
  
  def build_project(slide)
    project_path = slide.project_path
    output_dir = PUBLIC_SLIDES_DIR.join(slide.slug)
    
    # Slidevプロジェクトのビルド
    system("cd #{project_path} && npm install && npm run build -- --base /slides/#{slide.slug}/ --out #{output_dir}")
    
    output_dir.to_s
  end
  
  def delete_project(slide)
    FileUtils.rm_rf(slide.project_path)
    FileUtils.rm_rf(PUBLIC_SLIDES_DIR.join(slide.slug))
  end
end
```

### 2.2 コントローラーの実装

```ruby
# app/controllers/slides_controller.rb
class SlidesController < ApplicationController
  before_action :set_slide, only: [:show, :edit, :update, :destroy, :build]
  
  def index
    @slides = Slide.all.order(created_at: :desc)
  end
  
  def new
    @slide = Slide.new
  end
  
  def create
    @slide = Slide.new(slide_params)
    service = SlidevProjectService.new
    
    ActiveRecord::Base.transaction do
      project_path = service.create_project(@slide.slug)
      @slide.project_path = project_path
      
      if @slide.save
        service.build_project(@slide)
        redirect_to slides_path, notice: 'スライドを作成しました'
      else
        render :new, status: :unprocessable_entity
      end
    end
  rescue => e
    @slide.errors.add(:base, "プロジェクト作成エラー: #{e.message}")
    render :new, status: :unprocessable_entity
  end
  
  def build
    service = SlidevProjectService.new
    service.build_project(@slide)
    redirect_to slides_path, notice: 'スライドをビルドしました'
  end
  
  def destroy
    service = SlidevProjectService.new
    service.delete_project(@slide)
    @slide.destroy
    redirect_to slides_path, notice: 'スライドを削除しました'
  end
  
  private
  
  def set_slide
    @slide = Slide.find(params[:id])
  end
  
  def slide_params
    params.require(:slide).permit(:name, :description)
  end
end
```

## フェーズ3: ルーティングとビューの実装

### 3.1 ルーティング設定

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root 'slides#index'
  
  resources :slides do
    member do
      post :build
    end
  end
  
  # Slidevビルド成果物へのアクセス
  # public/slides配下の静的ファイルは自動的に配信される
end
```

### 3.2 ビューの実装

```erb
<!-- app/views/slides/index.html.erb -->
<h1>スライド一覧</h1>

<%= link_to '新規作成', new_slide_path, class: 'btn btn-primary' %>

<table class="table">
  <thead>
    <tr>
      <th>名前</th>
      <th>説明</th>
      <th>URL</th>
      <th>操作</th>
    </tr>
  </thead>
  <tbody>
    <% @slides.each do |slide| %>
      <tr>
        <td><%= slide.name %></td>
        <td><%= slide.description %></td>
        <td>
          <%= link_to "#{request.base_url}/slides/#{slide.slug}/", 
                      "/slides/#{slide.slug}/", 
                      target: '_blank' %>
        </td>
        <td>
          <%= button_to 'ビルド', build_slide_path(slide), method: :post, class: 'btn btn-sm btn-info' %>
          <%= button_to '削除', slide_path(slide), method: :delete, 
                        data: { confirm: '本当に削除しますか?' }, 
                        class: 'btn btn-sm btn-danger' %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

## フェーズ4: 開発環境の整備

### 4.1 必要なNode.js環境の準備

Dockerを使用した環境構築[5]:

```dockerfile
# Dockerfile
FROM ruby:3.2

# Node.jsのインストール
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json package-lock.json ./
RUN npm install

COPY . .
```

### 4.2 依存関係の管理

```json
// package.json
{
  "name": "slidev-manager",
  "private": true,
  "dependencies": {
    "@slidev/cli": "^0.48.0",
    "@slidev/theme-default": "latest"
  }
}
```

## フェーズ5: テストとデプロイ準備

### 5.1 テストの実装

```ruby
# test/services/slidev_project_service_test.rb
require 'test_helper'

class SlidevProjectServiceTest < ActiveSupport::TestCase
  setup do
    @service = SlidevProjectService.new
  end
  
  test "should create slidev project" do
    name = "test-slide-#{Time.now.to_i}"
    project_path = @service.create_project(name)
    
    assert File.directory?(project_path)
    assert File.exist?(File.join(project_path, 'slides.md'))
  end
end
```

### 5.2 本番環境への配慮

- ビルド処理を非同期化(Sidekiq等を使用)
- ファイルストレージをS3等のクラウドストレージに移行
- CDNの活用

## 実装スケジュール

**Week 1-2:** フェーズ1-2(基盤構築とSlidev統合)
**Week 3:** フェーズ3(UI実装)
**Week 4:** フェーズ4-5(環境整備とテスト)
