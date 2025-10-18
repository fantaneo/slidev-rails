class SlidesChannel < ApplicationCable::Channel
  def subscribed
    # ユーザーが "slides" チャネルにサブスクライブされると呼ばれる
    stream_from "slides"
  end

  def unsubscribed
    # ユーザーがチャネルからアンサブスクライブされるときにクリーンアップ
  end
end
