# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Clear existing data
puts "Cleaning up existing data..."
TeacherClassStandard.destroy_all
User.destroy_all
ClassStandard.destroy_all

# Create class standards
puts "Creating class standards..."
class_standards = {
  'STD-1' => { name: 'Standard 1', code: 'STD-1', year: 1, section: 'A' },
  'STD-2' => { name: 'Standard 2', code: 'STD-2', year: 2, section: 'A' },
  'STD-3' => { name: 'Standard 3', code: 'STD-3', year: 3, section: 'A' }
}

class_standards.each do |code, attrs|
  ClassStandard.create!(attrs)
end

# Create admin users
puts "Creating admin users..."
admin_users = [
  { email: 'admin@school.com', password: 'password123', role: :admin },
  { email: 'superadmin@school.com', password: 'password123', role: :admin }
]

admin_users.each do |admin|
  User.create!(admin)
  puts "Created admin: #{admin[:email]}"
end

# Create teacher users
puts "Creating teacher users..."
teacher_users = [
  { 
    email: 'john.teacher@school.com',
    password: 'password123',
    role: :teacher,
    first_name: 'John',
    last_name: 'Smith'
  },
  {
    email: 'mary.teacher@school.com',
    password: 'password123',
    role: :teacher,
    first_name: 'Mary',
    last_name: 'Johnson'
  }
]

teacher_users.each do |teacher|
  User.create!(teacher)
  puts "Created teacher: #{teacher[:email]}"
end

# Create student users
puts "Creating student users..."
student_users = [
  {
    password: 'password123',
    first_name: 'Alice',
    last_name: 'Brown',
    class_standard: 'STD-1',
    roll_number: 'HSS101'
  },
  {
    password: 'password123',
    first_name: 'Bob',
    last_name: 'Wilson',
    class_standard: 'STD-2',
    roll_number: 'HSS201'
  },
  {
    password: 'password123',
    first_name: 'Carol',
    last_name: 'Davis',
    class_standard: 'STD-3',
    roll_number: 'HSS301'
  }
]

student_users.each do |student_attrs|
  student = User.new(student_attrs)
  student.role = :student
  student.save!
  puts "Created student: #{student.first_name} #{student.last_name} (#{student.roll_number})"
end

puts "\nSeed data created successfully!"
puts "Created:"
puts "- #{User.admins.count} admin users"
puts "- #{User.teachers.count} teacher users"
puts "- #{User.students.count} student users"
puts "- #{ClassStandard.count} class standards"
