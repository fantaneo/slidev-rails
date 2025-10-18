class SlidesController < ApplicationController
  before_action :set_slide, only: [:show, :destroy, :build, :edit, :update, :slide_html]

  def index
    @slides = Slide.all.order(created_at: :desc)
    respond_to do |format|
      format.html
      format.json { render json: @slides }
    end
  end

  def show
    # スライドの詳細表示（必要に応じて実装）
    respond_to do |format|
      format.html
      format.json { render json: @slide }
    end
  end

  def slide_html
    # ポーリング用の行HTMLを返す
    render partial: "slides/slide", locals: { slide: @slide }, layout: false
  end

  def new
    @slide = Slide.new
  end

  def create
    @slide = Slide.new(slide_params)
    service = SlidevProjectService.new

    begin
      # nameのバリデーションを実行（slugを生成するため）
      unless @slide.name.present?
        @slide.errors.add(:name, "を入力してください")
        render :new, status: :unprocessable_entity
        return
      end

      # slugを手動で生成（before_validationはsave時にしか実行されないため）
      @slide.slug = @slide.name.parameterize

      # slugが有効か確認
      if @slide.slug.blank?
        @slide.errors.add(:name, "から有効なスラッグを生成できませんでした")
        render :new, status: :unprocessable_entity
        return
      end

      # 同じslugが既に存在しないか確認
      if Slide.exists?(slug: @slide.slug)
        @slide.errors.add(:name, "から生成されたスラッグ「#{@slide.slug}」は既に使用されています")
        render :new, status: :unprocessable_entity
        return
      end

      # Slidevプロジェクト作成をジョブとしてエンキュー
      # project_pathはジョブ実行後に設定されるため、ここではnilのままにする
      @slide.project_path = "pending"
      @slide.status = "pending"

      # データベースに保存
      if @slide.save
        # バックグラウンドジョブとしてプロジェクト作成と初期ビルドをエンキュー
        CreateSlidevProjectJob.perform_later(@slide.id)
        redirect_to slides_path, notice: 'スライドを作成しています。しばらくお待ちください...'
      else
        render :new, status: :unprocessable_entity
      end
    rescue => e
      @slide.errors.add(:base, "プロジェクト作成エラー: #{e.message}")
      render :new, status: :unprocessable_entity
    end
  end

  def build
    # ビルド中や失敗状態のスライドは操作を拒否
    if @slide.building?
      redirect_to slides_path, alert: 'このスライドは現在ビルド中です'
      return
    end

    begin
      # ステータスを即座に「building」に更新してブロードキャスト
      @slide.update(status: 'building', error_message: nil)

      # バックグラウンドジョブとしてビルドをエンキュー
      BuildSlidevProjectJob.perform_later(@slide.id)
      redirect_to slides_path, notice: 'スライドをビルド中です。しばらくお待ちください...'
    rescue => e
      redirect_to slides_path, alert: "ビルドエラー: #{e.message}"
    end
  end

  def destroy
    service = SlidevProjectService.new
    begin
      service.delete_project(@slide)
      @slide.destroy
      redirect_to slides_path, notice: 'スライドを削除しました'
    rescue => e
      redirect_to slides_path, alert: "削除エラー: #{e.message}"
    end
  end

  def edit
    # ビルド中のスライドは編集を拒否
    if @slide.building?
      redirect_to slides_path, alert: 'このスライドは現在ビルド中です'
      return
    end

    service = SlidevProjectService.new
    begin
      @slides_content = service.read_slides_md(@slide)
    rescue => e
      redirect_to slides_path, alert: "編集画面の読み込みエラー: #{e.message}"
    end
  end

  def update
    # ビルド中のスライドは更新を拒否
    if @slide.building?
      redirect_to slides_path, alert: 'このスライドは現在ビルド中です'
      return
    end

    service = SlidevProjectService.new
    begin
      service.write_slides_md(@slide, params[:slide][:slides_content])
      redirect_to slides_path, notice: 'スライドを更新しました'
    rescue => e
      @slide = Slide.find(params[:id])
      @slides_content = params[:slide][:slides_content]
      flash.now[:alert] = "更新エラー: #{e.message}"
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_slide
    @slide = Slide.find(params[:id])
  end

  def slide_params
    params.require(:slide).permit(:name, :description)
  end
end
