class Teacher::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher

  def index
    @teacher = current_user
    @class_standards = @teacher.teaching_class_standards.active
    @recent_attendances = @teacher.marked_attendances
                                .includes(:student)
                                .order(created_at: :desc)
                                .limit(5)
    @today_stats = calculate_today_stats
  end

  private

  def require_teacher
    unless current_user&.teacher?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end

  def calculate_today_stats
    today = Date.current
    attendances = @teacher.marked_attendances.where(date: today)
    
    {
      total_classes: @class_standards.count,
      classes_today: attendances.select(:class_standard).distinct.count,
      total_students: attendances.count,
      present_students: attendances.present.count,
      absent_students: attendances.absent.count,
      late_students: attendances.late.count
    }
  end
end 