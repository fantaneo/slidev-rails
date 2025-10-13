class CreateSlides < ActiveRecord::Migration[7.1]
  def change
    create_table :slides do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :project_path, null: false
      t.text :description

      t.timestamps
    end
    add_index :slides, :slug, unique: true
  end
end
