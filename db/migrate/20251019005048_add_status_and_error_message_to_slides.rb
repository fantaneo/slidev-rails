class AddStatusAndErrorMessageToSlides < ActiveRecord::Migration[7.1]
  def change
    add_column :slides, :status, :string, default: 'pending', null: false
    add_column :slides, :error_message, :text
  end
end
