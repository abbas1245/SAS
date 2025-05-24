namespace :demo do
  desc "Assign classes to a teacher"
  task assign_classes: :environment do
    # Find a teacher account (use email to identify)
    teacher_email = ENV['TEACHER_EMAIL'] || User.teachers.first&.email
    
    unless teacher_email
      puts "No teacher found. Please create a teacher account first."
      exit
    end
    
    teacher = User.find_by(email: teacher_email)
    unless teacher&.teacher?
      puts "User #{teacher_email} is not a teacher."
      exit
    end
    
    # Find or create class standards
    class_standards = []
    
    # Class 1: Grade 8
    class1 = ClassStandard.find_or_create_by(
      name: "Grade 8",
      code: "G8",
      year: 8,
      section: "A",
      active: true
    )
    class_standards << class1
    
    # Class 2: Grade 9
    class2 = ClassStandard.find_or_create_by(
      name: "Grade 9",
      code: "G9",
      year: 9,
      section: "B",
      active: true
    )
    class_standards << class2
    
    # Assign classes to teacher
    class_standards.each do |cs|
      assignment = TeacherClassStandard.find_or_initialize_by(
        teacher_id: teacher.id,
        class_standard_id: cs.id
      )
      
      if assignment.new_record?
        assignment.start_date = Date.current
        assignment.active = true
        if assignment.save
          puts "Successfully assigned #{cs.display_name} to #{teacher.email}"
        else
          puts "Failed to assign #{cs.display_name}: #{assignment.errors.full_messages.join(', ')}"
        end
      else
        puts "#{cs.display_name} already assigned to #{teacher.email}"
      end
    end
  end
end 