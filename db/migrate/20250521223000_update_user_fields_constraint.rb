class UpdateUserFieldsConstraint < ActiveRecord::Migration[7.0]
  def up
    # Drop existing constraint
    execute <<-SQL
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS check_user_fields
    SQL

    # Add updated constraint
    execute <<-SQL
      ALTER TABLE users
      ADD CONSTRAINT check_user_fields
      CHECK (
        (role = 0) OR  -- Admin role has no field requirements
        (role = 1 AND first_name IS NOT NULL AND last_name IS NOT NULL) OR  -- Teacher role requires names
        (role = 2 AND class_standard IS NOT NULL AND first_name IS NOT NULL AND last_name IS NOT NULL)  -- Student role requires all fields
      )
    SQL
  end

  def down
    # Drop the updated constraint
    execute <<-SQL
      ALTER TABLE users
      DROP CONSTRAINT IF EXISTS check_user_fields
    SQL

    # Restore the original constraint
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
end 