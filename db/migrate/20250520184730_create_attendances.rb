class CreateAttendances < ActiveRecord::Migration[7.0]
  def change
    create_table :attendances do |t|
      t.date :date, null: false
      t.string :status, null: false
      t.text :notes
      t.references :student, null: false, foreign_key: { to_table: :users }
      t.references :teacher, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
