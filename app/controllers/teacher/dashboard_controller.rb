class Teacher::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher

  def index
    @teacher = current_user
    @class_standards = @teacher.teaching_class_standards

    # Get today's attendance records
    today = Date.current
    attendances = Attendance.where(
      teacher_id: @teacher.id,
      date: today
    )

    # Calculate statistics
    @today_stats = {
      total_classes: @class_standards.count,  # Total number of classes assigned to teacher
      classes_today: attendances.select(:class_standard).distinct.count,
      total_students: attendances.count,
      present_students: attendances.where(status: 'present').count,
      absent_students: attendances.where(status: 'absent').count,
      late_students: attendances.where(status: 'late').count
    }

    # Calculate attendance percentage
    @today_stats[:attendance_percentage] = @today_stats[:total_students] > 0 ? 
      ((@today_stats[:present_students].to_f / @today_stats[:total_students]) * 100).round(2) : 0

    # Get class-wise statistics
    @class_stats = {}
    @class_standards.each do |class_standard|
      class_attendances = attendances.where(class_standard: class_standard.code)
      total = class_attendances.count
      present = class_attendances.where(status: 'present').count
      absent = class_attendances.where(status: 'absent').count
      late = class_attendances.where(status: 'late').count
      percentage = total > 0 ? ((present.to_f / total) * 100).round(2) : 0

      @class_stats[class_standard.id] = {
        name: class_standard.display_name,
        total: total,
        present: present,
        absent: absent,
        late: late,
        percentage: percentage
      }
    end

    # Get recent attendance records
    @recent_attendances = attendances
      .includes(:student)
      .order(date: :desc)
      .limit(5)

    # Debug logging
    Rails.logger.debug "Teacher #{@teacher.id} (#{@teacher.email}) has #{@class_standards.count} active classes"
    Rails.logger.debug "Today's stats: #{@today_stats.inspect}"
    Rails.logger.debug "Class-wise stats: #{@class_stats.inspect}"
  end

  private

  def require_teacher
    unless current_user&.teacher?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 