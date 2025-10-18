class BuildSlidevProjectJob < ApplicationJob
  queue_as :default

  # ジョブ実行時に呼ばれるメインロジック
  def perform(slide_id)
    slide = Slide.find(slide_id)
    service = SlidevProjectService.new

    begin
      # ステータスをビルド中に更新
      slide.update(status: 'building', error_message: nil)

      # ビルド処理を実行
      service.build_project(slide)

      # ビルド成功時はステータスを完了に更新
      slide.update(status: 'completed')
    rescue => e
      # エラーログを出力
      Rails.logger.error("BuildSlidevProjectJob Error for Slide ID: #{slide_id}")
      Rails.logger.error("Error Message: #{e.message}")
      Rails.logger.error("Error Class: #{e.class}")
      Rails.logger.error("Backtrace: #{e.backtrace.first(5).join("\n")}")

      # ビルド失敗時はエラーメッセージを保存
      slide.update(status: 'failed', error_message: e.message)
      raise e
    end
  end
end
