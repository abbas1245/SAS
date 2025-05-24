class Student::AttendanceController < ApplicationController
  before_action :authenticate_user!
  before_action :require_student
  
  def index
    @student = current_user
    @attendances = @student.attendances.includes(:teacher)
                          .order(date: :desc)
    
    # Group attendances by month
    @attendances_by_month = @attendances.group_by { |a| a.date.beginning_of_month }
    
    # Group by subject/class
    @attendance_by_subject = {}
    @attendances.group_by(&:class_standard).each do |code, records|
      class_obj = ClassStandard.find_by(code: code)
      subject_name = class_obj ? class_obj.display_name : code
      total = records.count
      present = records.count { |r| r.status == 'present' }
      percentage = total > 0 ? ((present.to_f / total) * 100).round(2) : 0
      
      @attendance_by_subject[code] = {
        name: subject_name,
        total: total,
        present: present,
        percentage: percentage,
        status: percentage >= 75 ? 'good' : 'warning',
        records: records.first(5)  # Include the 5 most recent records for each subject
      }
    end
  end
  
  def report
    @student = current_user
    @attendances = @student.attendances.includes(:teacher)
                          .order(date: :desc)
    
    # Calculate statistics
    @total_classes = @attendances.count
    @present_classes = @attendances.where(status: 'present').count
    @absent_classes = @attendances.where(status: 'absent').count
    @late_classes = @attendances.where(status: 'late').count
    
    @attendance_percentage = @total_classes > 0 ? ((@present_classes.to_f / @total_classes) * 100).round(2) : 0
    
    # Group attendances by subject/class
    @attendance_by_subject = {}
    @attendances.group_by(&:class_standard).each do |code, records|
      class_obj = ClassStandard.find_by(code: code)
      subject_name = class_obj ? class_obj.display_name : code
      total = records.count
      present = records.count { |r| r.status == 'present' }
      percentage = total > 0 ? ((present.to_f / total) * 100).round(2) : 0
      
      @attendance_by_subject[code] = {
        name: subject_name,
        total: total,
        present: present,
        percentage: percentage,
        status: percentage >= 75 ? 'good' : 'warning'
      }
    end
    
    # Monthly attendance trend
    @monthly_trend = @attendances.group_by { |a| a.date.beginning_of_month }
                                .transform_values do |records|
                                  total = records.count
                                  present = records.count { |r| r.status == 'present' }
                                  percentage = total > 0 ? ((present.to_f / total) * 100).round(2) : 0
                                  {
                                    total: total,
                                    present: present,
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