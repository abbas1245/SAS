class AddNameFieldsToUsers < ActiveRecord::Migration[7.0]
  def up
    # Add columns as nullable first
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :class_standard, :string
    
    # Update existing records
    User.find_each do |user|
      if user.admin?
        # For admins, set a default name but keep it nullable
        user.update_columns(
          first_name: 'Admin',
          last_name: 'User'
        )
      elsif user.teacher?
        # For teachers, set a default name
        user.update_columns(
          first_name: user.email.split('@').first,
          last_name: 'Teacher'
        )
      else
        # For students, set a default name and class
        user.update_columns(
          first_name: user.email.split('@').first,
          last_name: 'Student',
          class_standard: 'Standard-1'
        )
      end
    end

    # Add index for faster lookups
    add_index :users, :class_standard
    
    # Add validation for class_standard presence only for students
    # and name presence for teachers and students
    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT check_user_fields
      CHECK (
        (role = 0 AND class_standard IS NOT NULL AND first_name IS NOT NULL AND last_name IS NOT NULL) OR
        (role = 1 AND first_name IS NOT NULL AND last_name IS NOT NULL) OR
        (role = 2)
      )
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS check_user_fields
    SQL

    remove_index :users, :class_standard
    remove_column :users, :class_standard
    remove_column :users, :last_name
    remove_column :users, :first_name
  end
end
