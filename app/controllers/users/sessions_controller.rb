class Users::SessionsController < Devise::SessionsController
  protected

  def after_sign_in_path_for(resource)
    case resource.role
    when 'admin'
      admin_root_path
    when 'teacher'
      teacher_root_path
    when 'student'
      student_root_path
    else
      root_path
    end
  end
end 