class Student::AttendanceController < ApplicationController
  before_action :authenticate_user!
  before_action :require_student
  
  def index
    @student = current_user
    
    # Base query with includes to avoid N+1 queries
    base_query = @student.attendances.includes(:teacher)
    
    # If a specific subject is selected, filter attendances
    if params[:subject].present?
      @attendances = base_query.where(class_standard: params[:subject])
    else
      @attendances = base_query
    end
    
    # Order all attendances by date
    @attendances = @attendances.order(date: :desc)
    
    # Debug logging for attendance records
    Rails.logger.debug "Found #{@attendances.count} attendance records"
    @attendances.each do |attendance|
      Rails.logger.debug "Attendance record: date=#{attendance.date}, status=#{attendance.status.inspect}, class=#{attendance.class_standard}"
    end
    
    # Group attendances by month
    @attendances_by_month = @attendances.group_by { |a| a.date.beginning_of_month }
    
    # Group by subject/class with proper counting and recent records
    @attendance_by_subject = {}
    
    # Get all unique class standards from attendances
    class_standards = @student.attendances.distinct.pluck(:class_standard)
    
    class_standards.each do |code|
      # Get all attendances for this subject with status
      subject_attendances = @student.attendances.where(class_standard: code)
      
      # Calculate statistics
      total = subject_attendances.count
      present = subject_attendances.where(status: 'present').count
      absent = subject_attendances.where(status: 'absent').count
      late = subject_attendances.where(status: 'late').count
      
      # Calculate percentage
      percentage = total > 0 ? (present.to_f / total * 100).round(2) : 0
      
      # Get subject name
      class_obj = ClassStandard.find_by(code: code)
      subject_name = class_obj ? class_obj.display_name : code
      
      # Get recent records (last 5) with status
      recent_records = subject_attendances.includes(:teacher)
                                        .order(date: :desc)
                                        .limit(5)
                                        .to_a # Ensure records are loaded
      
      # Debug logging
      Rails.logger.debug "Subject: #{code}"
      Rails.logger.debug "Total records: #{total}"
      Rails.logger.debug "Present: #{present}"
      Rails.logger.debug "Absent: #{absent}"
      Rails.logger.debug "Late: #{late}"
      recent_records.each do |record|
        Rails.logger.debug "Record date: #{record.date}, Status: #{record.status.inspect}"
      end
      
      @attendance_by_subject[code] = {
        name: subject_name,
        total: total,
        present: present,
        absent: absent,
        late: late,
        percentage: percentage,
        status: percentage >= 75 ? 'good' : 'warning',
        records: recent_records
      }
    end
  end
  
  def report
    @student = current_user
    @attendances = @student.attendances.includes(:teacher)
                          .order(date: :desc)
    
    # Calculate statistics with proper counting
    @total_classes = @attendances.count
    @present_classes = @attendances.where(status: 'present').count
    @absent_classes = @attendances.where(status: 'absent').count
    @late_classes = @attendances.where(status: 'late').count
    
    @attendance_percentage = @total_classes > 0 ? ((@present_classes.to_f / @total_classes) * 100).round(2) : 0
    
    # Group attendances by subject/class with proper counting
    @attendance_by_subject = {}
    
    # Get all unique class standards from attendances
    class_standards = @student.attendances.distinct.pluck(:class_standard)
    
    class_standards.each do |code|
      # Get all attendances for this subject
      subject_attendances = @student.attendances.where(class_standard: code)
      
      # Calculate statistics
      total = subject_attendances.count
      present = subject_attendances.where(status: 'present').count
      absent = subject_attendances.where(status: 'absent').count
      late = subject_attendances.where(status: 'late').count
      
      # Calculate percentage
      percentage = total > 0 ? (present.to_f / total * 100).round(2) : 0
      
      # Get subject name
      class_obj = ClassStandard.find_by(code: code)
      subject_name = class_obj ? class_obj.display_name : code
      
      @attendance_by_subject[code] = {
        name: subject_name,
        total: total,
        present: present,
        absent: absent,
        late: late,
        percentage: percentage,
        status: percentage >= 75 ? 'good' : 'warning'
      }
    end
    
    # Monthly attendance trend with proper counting
    @monthly_trend = @attendances.group_by { |a| a.date.beginning_of_month }
                                .transform_values do |records|
      total = records.count
      present = records.count { |r| r.status == 'present' }
      absent = records.count { |r| r.status == 'absent' }
      late = records.count { |r| r.status == 'late' }
      percentage = total > 0 ? ((present.to_f / total) * 100).round(2) : 0
      
      {
        total: total,
        present: present,
        absent: absent,
        late: late,
        percentage: percentage
      }
    end
    
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "attendance_report_#{@student.id}",
               template: "student/attendance/report",
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
  
  def require_student
    unless current_user&.student?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 