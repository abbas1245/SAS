class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  
  def index
    if user_signed_in?
      if current_user.admin?
        redirect_to admin_root_path
      elsif current_user.teacher?
        redirect_to teacher_root_path
      elsif current_user.student?
        redirect_to student_root_path
      else
        redirect_to dashboard_path
      end
    end
  end
end
