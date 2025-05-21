class CreateClassStandards < ActiveRecord::Migration[7.0]
  def change
    create_table :class_standards do |t|
      t.string :name, null: false
      t.text :description
      t.string :code, null: false, unique: true
      t.integer :year, null: false
      t.string :section
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :class_standards, :code, unique: true
    add_index :class_standards, [:year, :section], unique: true
  end
end
