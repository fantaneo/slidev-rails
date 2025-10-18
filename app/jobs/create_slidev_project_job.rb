class CreateSlidevProjectJob < ApplicationJob
  queue_as :default

  # ジョブ実行時に呼ばれるメインロジック
  def perform(slide_id, initial_content = "Hello, World!")
    slide = Slide.find(slide_id)
    service = SlidevProjectService.new

    begin
      # ステータスをビルド中に更新
      slide.update(status: 'building', error_message: nil)

      # Slidevプロジェクトを作成
      project_path = service.create_project(slide.slug)
      slide.update(project_path: project_path)

      # slides.mdの初期内容を書き込み
      service.write_slides_md(slide, initial_content)

      # ビルド処理を実行
      service.build_project(slide)

      # 完了時はステータスを更新
      slide.update(status: 'completed')
    rescue => e
      # エラーログを出力
      Rails.logger.error("CreateSlidevProjectJob Error for Slide ID: #{slide_id}")
      Rails.logger.error("Error Message: #{e.message}")
      Rails.logger.error("Error Class: #{e.class}")
      Rails.logger.error("Backtrace: #{e.backtrace.first(5).join("\n")}")

      # エラー発生時：プロジェクトがあれば削除してエラーメッセージを保存
      if slide.project_path.present? && slide.project_path != "pending" && File.exist?(slide.project_path)
        begin
          FileUtils.rm_rf(slide.project_path)
          Rails.logger.info("Project directory deleted: #{slide.project_path}")
        rescue => cleanup_error
          Rails.logger.warn("Failed to delete project directory: #{cleanup_error.message}")
        end
      end

      # ステータスを失敗に更新（project_pathは変更しない）
      slide.update(status: 'failed', error_message: e.message)
      raise e
    end
  end
end
