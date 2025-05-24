class Student::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_student

  def index
    @student = current_user
    @recent_attendances = @student.attendances
                                .includes(:teacher)
                                .order(created_at: :desc)
                                .limit(5)
    @attendance_stats = calculate_attendance_stats
    
    # Group attendances by class/subject
    @attendance_by_subject = @student.attendances
                                    .select('class_standard, COUNT(*) as total_count, SUM(CASE WHEN status = \'present\' THEN 1 ELSE 0 END) as present_count')
                                    .group(:class_standard)
                                    .each_with_object({}) do |data, hash|
                                      percentage = (data.present_count.to_f / data.total_count * 100).round(2)
                                      class_obj = ClassStandard.find_by(code: data.class_standard)
                                      class_name = class_obj ? class_obj.display_name : data.class_standard
                                      hash[data.class_standard] = {
                                        name: class_name,
                                        total: data.total_count,
                                        present: data.present_count,
                                        percentage: percentage,
                                        status: percentage >= 75 ? 'good' : 'warning'
                                      }
                                    end
  end

  private

  def require_student
    unless current_user&.student?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end

  def calculate_attendance_stats
    total_classes = @student.attendances.count
    present_classes = @student.attendances.present.count
    attendance_percentage = total_classes.positive? ? (present_classes.to_f / total_classes * 100).round(2) : 0
    
    {
      total_classes: total_classes,
      present_classes: present_classes,
      attendance_percentage: attendance_percentage,
      short_attendance: @student.short_attendance?
    }
  end
end 