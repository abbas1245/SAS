class Teacher::AttendanceController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher
  before_action :set_class_standard, only: [:students, :mark]

  def index
    @class_standards = current_user.teaching_class_standards.active
  end

  def class_standards
    @class_standards = current_user.teaching_class_standards.active
    render json: @class_standards.map { |cs| { id: cs.id, name: cs.display_name } }
  end

  def students
    @students = @class_standard.students.order(:first_name, :last_name)
    render json: @students.map { |s| 
      { 
        id: s.id, 
        name: s.full_name,
        attendance: s.attendances.where(date: Date.current).first&.status
      } 
    }
  end

  def mark
    ActiveRecord::Base.transaction do
      params[:attendance].each do |student_id, status|
        attendance = Attendance.find_or_initialize_by(
          student_id: student_id,
          teacher_id: current_user.id,
          date: Date.current,
          class_standard: @class_standard.code
        )
        attendance.status = status
        attendance.save!
      end
    end

    render json: { message: 'Attendance marked successfully' }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_class_standard
    @class_standard = current_user.teaching_class_standards.find(params[:class_standard_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Class not found' }, status: :not_found
  end

  def require_teacher
    unless current_user&.teacher?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 