class Slide < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :project_path, presence: true, on: :save
  validates :status, inclusion: { in: %w(pending building completed failed), message: "%{value} は有効なステータスではありません" }

  before_validation :generate_slug, on: :create
  after_update_commit :broadcast_update

  # ステータススコープ
  scope :pending, -> { where(status: 'pending') }
  scope :building, -> { where(status: 'building') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }

  # ステータスチェックメソッド
  def building?
    status == 'building'
  end

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def pending?
    status == 'pending'
  end

  private

  def generate_slug
    self.slug ||= name.parameterize if name.present?
  end

  # Turbo Streamsで更新をブロードキャスト
  def broadcast_update
    broadcast_replace_to "slides", partial: "slides/slide", locals: { slide: self }
  end
end
