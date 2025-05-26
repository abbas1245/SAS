class Student::DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :require_student

  def index
    @student = current_user
    
    # Get enrolled subjects through class standard
    @enrolled_subjects = if @student.class_standard
      [@student.class_standard]
    else
      []
    end
    
    # Get recent attendance records with detailed logging
    @recent_attendances = @student.attendances
                                .includes(:teacher)
                                .order(date: :desc)
                                .limit(5)
    
    # Debug logging for recent attendances
    Rails.logger.debug "=== Recent Attendance Records ==="
    @recent_attendances.each do |attendance|
      Rails.logger.debug "Record ID: #{attendance.id}"
      Rails.logger.debug "Date: #{attendance.date}"
      Rails.logger.debug "Class: #{attendance.class_standard}"
      Rails.logger.debug "Status (raw): #{attendance.status.inspect}"
      Rails.logger.debug "Status (type): #{attendance.status.class}"
      Rails.logger.debug "Teacher: #{attendance.teacher&.full_name}"
      Rails.logger.debug "---"
    end
    
    # Calculate attendance statistics for each subject
    @attendance_stats = {}
    @enrolled_subjects.each do |subject|
      # Get all attendance records for this subject
      subject_attendances = @student.attendances.where(class_standard: subject.code)
      
      # Calculate statistics
      total = subject_attendances.count
      present = subject_attendances.where(status: 'present').count
      absent = subject_attendances.where(status: 'absent').count
      late = subject_attendances.where(status: 'late').count
      
      # Calculate percentage
      percentage = total > 0 ? (present.to_f / total * 100).round(2) : 0
      
      # Debug logging
      Rails.logger.debug "=== Subject Statistics: #{subject.code} ==="
      Rails.logger.debug "Total records: #{total}"
      Rails.logger.debug "Present: #{present}"
      Rails.logger.debug "Absent: #{absent}"
      Rails.logger.debug "Late: #{late}"
      Rails.logger.debug "Percentage: #{percentage}"
      
      # Log individual records for this subject
      subject_attendances.each do |attendance|
        Rails.logger.debug "Record ID: #{attendance.id}"
        Rails.logger.debug "Date: #{attendance.date}"
        Rails.logger.debug "Status: #{attendance.status.inspect}"
        Rails.logger.debug "---"
      end
      
      @attendance_stats[subject.code] = {
        name: subject.display_name,
        total: total,
        present: present,
        absent: absent,
        late: late,
        percentage: percentage,
        status: percentage >= 75 ? 'good' : 'warning'
      }
    end
    
    # Calculate overall attendance statistics
    @overall_stats = calculate_attendance_stats(@student.attendances)
  end

  private

  def calculate_attendance_stats(attendances)
    total = attendances.count
    present = attendances.where(status: 'present').count
    absent = attendances.where(status: 'absent').count
    late = attendances.where(status: 'late').count
    
    # Debug logging
    Rails.logger.debug "=== Overall Statistics ==="
    Rails.logger.debug "Total records: #{total}"
    Rails.logger.debug "Present: #{present}"
    Rails.logger.debug "Absent: #{absent}"
    Rails.logger.debug "Late: #{late}"
    
    # Log all attendance records
    attendances.each do |attendance|
      Rails.logger.debug "Record ID: #{attendance.id}"
      Rails.logger.debug "Date: #{attendance.date}"
      Rails.logger.debug "Class: #{attendance.class_standard}"
      Rails.logger.debug "Status: #{attendance.status.inspect}"
      Rails.logger.debug "---"
    end
    
    percentage = total > 0 ? (present.to_f / total * 100).round(2) : 0
    
    {
      total: total,
      present: present,
      absent: absent,
      late: late,
      percentage: percentage,
      status: percentage >= 75 ? 'good' : 'warning'
    }
  end

  def require_student
    unless current_user&.student?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 