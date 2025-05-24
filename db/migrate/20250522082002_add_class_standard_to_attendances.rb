class AddClassStandardToAttendances < ActiveRecord::Migration[8.0]
  def change
    add_column :attendances, :class_standard, :string
    add_index :attendances, :class_standard
    
    # Update existing records using student's class standard
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE attendances 
          SET class_standard = (
            SELECT class_standard FROM users WHERE users.id = attendances.student_id
          )
          WHERE class_standard IS NULL
        SQL
      end
    end
  end
end
