class AddStatusToSlides < ActiveRecord::Migration[7.1]
  def change
    add_column :slides, :status, :string, default: 'pending'
    add_column :slides, :error_message, :text
    add_index :slides, :status
  end
end
