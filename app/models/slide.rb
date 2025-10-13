class Slide < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :project_path, presence: true, on: :save

  before_validation :generate_slug, on: :create

  private

  def generate_slug
    self.slug ||= name.parameterize if name.present?
  end
end
