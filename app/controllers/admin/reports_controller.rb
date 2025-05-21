class Admin::ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin

  def index
    @start_date = params[:start_date] || Date.today.beginning_of_month
    @end_date = params[:end_date] || Date.today.end_of_month
    @student_id = params[:student_id]
    @teacher_id = params[:teacher_id]

    @attendances = Attendance.includes(:student, :teacher)
    
    if @student_id.present?
      @attendances = @attendances.for_student(@student_id)
    end

    if @teacher_id.present?
      @attendances = @attendances.for_teacher(@teacher_id)
    end

    @attendances = @attendances.where(date: @start_date..@end_date)
    
    @students = User.students
    @teachers = User.teachers

    @attendance_stats = {
      total: @attendances.count,
      present: @attendances.present.count,
      absent: @attendances.absent.count,
      late: @attendances.late.count
    }

    respond_to do |format|
      format.html
      format.csv { send_data generate_csv, filename: "attendance-report-#{Date.today}.csv" }
    end
  end

  private

  def authorize_admin
    unless current_user.admin?
      redirect_to root_path, alert: 'You are not authorized to perform this action.'
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