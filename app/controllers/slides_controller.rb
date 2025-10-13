class SlidesController < ApplicationController
  before_action :set_slide, only: [:show, :destroy, :build]

  def index
    @slides = Slide.all.order(created_at: :desc)
  end

  def show
    # スライドの詳細表示（必要に応じて実装）
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

      # Slidevプロジェクトを作成
      project_path = service.create_project(@slide.slug)
      @slide.project_path = project_path

      # データベースに保存
      if @slide.save
        # ビルド処理を実行
        service.build_project(@slide)
        redirect_to slides_path, notice: 'スライドを作成しました'
      else
        # プロジェクト作成は成功したが保存に失敗した場合、プロジェクトを削除
        FileUtils.rm_rf(project_path) if File.exist?(project_path)
        render :new, status: :unprocessable_entity
      end
    rescue => e
      # エラーが発生した場合、作成済みのプロジェクトがあれば削除
      if @slide.project_path.present? && File.exist?(@slide.project_path)
        FileUtils.rm_rf(@slide.project_path)
      end
      @slide.errors.add(:base, "プロジェクト作成エラー: #{e.message}")
      render :new, status: :unprocessable_entity
    end
  end

  def build
    service = SlidevProjectService.new
    begin
      service.build_project(@slide)
      redirect_to slides_path, notice: 'スライドをビルドしました'
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

  private

  def set_slide
    @slide = Slide.find(params[:id])
  end

  def slide_params
    params.require(:slide).permit(:name, :description)
  end
end
