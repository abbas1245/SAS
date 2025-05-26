class Teacher::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher
  before_action :set_class_standard, only: [:class_attendance]

  def index
    @class_standards = current_user.teaching_class_standards
  end

  def class_attendance
    @students = @class_standard.students.order(:first_name, :last_name)
    
    # Calculate attendance statistics for each student
    @attendance_stats = @students.map do |student|
      attendances = student.attendances.where(class_standard: @class_standard.code)
      total_classes = attendances.count
      present_classes = attendances.where(status: 'present').count
      absent_classes = attendances.where(status: 'absent').count
      late_classes = attendances.where(status: 'late').count
      attendance_percentage = total_classes > 0 ? (present_classes.to_f / total_classes * 100).round(2) : 0

      {
        student: student,
        total_classes: total_classes,
        present_classes: present_classes,
        absent_classes: absent_classes,
        late_classes: late_classes,
        attendance_percentage: attendance_percentage,
        status: attendance_percentage >= 75 ? 'good' : 'warning'
      }
    end

    # Calculate class-wide statistics
    @class_stats = {
      total_students: @students.count,
      total_classes: @class_standard.attendances.select(:date).distinct.count,
      average_attendance: @attendance_stats.sum { |s| s[:attendance_percentage] } / @students.count,
      students_with_good_attendance: @attendance_stats.count { |s| s[:status] == 'good' }
    }

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "class_attendance_report_#{@class_standard.code}",
               template: "teacher/reports/class_attendance",
               layout: "pdf",
               page_size: "A4",
               orientation: "Portrait",
               lowquality: true,
               zoom: 1,
               dpi: 75
      end
    end
  end

  private

  def set_class_standard
    @class_standard = current_user.teaching_class_standards.find(params[:class_standard_id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Class not found"
    redirect_to teacher_reports_path
  end

  def require_teacher
    unless current_user&.teacher?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 