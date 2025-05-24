class Admin::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @total_students = User.students.count
    @total_teachers = User.teachers.count
    @total_classes = ClassStandard.active.count
  end

  private

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 