class CreateTeacherClassStandards < ActiveRecord::Migration[7.0]
  def change
    create_table :teacher_class_standards do |t|
      t.references :teacher, null: false, foreign_key: { to_table: :users }
      t.references :class_standard, null: false, foreign_key: true
      t.boolean :is_primary_teacher, default: false
      t.date :start_date, null: false
      t.date :end_date
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :teacher_class_standards, [:teacher_id, :class_standard_id], unique: true, name: 'index_teacher_class_standards_unique'
  end
end
