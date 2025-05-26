class Admin::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin

  def index
    @class_standards = ClassStandard.all
    @selected_class = params[:class_standard_id].present? ? ClassStandard.find(params[:class_standard_id]) : nil
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month

    # Initialize students and teachers for the filter dropdowns
    @students = User.students.order(:first_name, :last_name)
    @teachers = User.teachers.order(:first_name, :last_name)

    if @selected_class
      @attendances = Attendance.where(
        class_standard: @selected_class.code,
        date: @start_date..@end_date
      )

      # Apply student filter if selected
      if params[:student_id].present?
        @attendances = @attendances.where(student_id: params[:student_id])
      end

      # Apply teacher filter if selected
      if params[:teacher_id].present?
        @attendances = @attendances.where(teacher_id: params[:teacher_id])
      end

      @attendance_stats = {
        total: @attendances.count,
        present: @attendances.where(status: 'present').count,
        absent: @attendances.where(status: 'absent').count,
        late: @attendances.where(status: 'late').count
      }

      # Calculate attendance percentage
      @attendance_stats[:percentage] = @attendance_stats[:total] > 0 ? 
        ((@attendance_stats[:present].to_f / @attendance_stats[:total]) * 100).round(2) : 0

      # Get student-wise attendance
      @student_attendance = {}
      @selected_class.students.each do |student|
        student_attendances = @attendances.where(student_id: student.id)
        total = student_attendances.count
        present = student_attendances.where(status: 'present').count
        absent = student_attendances.where(status: 'absent').count
        late = student_attendances.where(status: 'late').count
        percentage = total > 0 ? ((present.to_f / total) * 100).round(2) : 0

        @student_attendance[student.id] = {
          name: student.full_name,
          roll_number: student.roll_number,
          total: total,
          present: present,
          absent: absent,
          late: late,
          percentage: percentage
        }
      end
    end

    respond_to do |format|
      format.html
      format.csv { send_data generate_csv, filename: "attendance-report-#{Date.today}.csv" }
    end
  end

  private

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end

  def generate_csv
    CSV.generate do |csv|
      csv << ['Date', 'Student', 'Teacher', 'Status']
      
      @attendances.each do |attendance|
        csv << [
          attendance.date,
          attendance.student.email,
          attendance.teacher.email,
          attendance.status.titleize
        ]
      end
    end
  end
end 