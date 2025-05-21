class AttendancesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_attendance, only: [:show, :edit, :update, :destroy]
  before_action :authorize_teacher, only: [:new, :create, :edit, :update, :destroy]

  def index
    @attendances = if current_user.teacher?
      current_user.marked_attendances.includes(:student).recent
    else
      current_user.attendances.includes(:teacher).recent
    end
  end

  def show
  end

  def new
    @attendance = Attendance.new
    @students = User.students
  end

  def create
    @attendance = current_user.marked_attendances.build(attendance_params)

    if @attendance.save
      redirect_to attendances_path, notice: 'Attendance was successfully marked.'
    else
      @students = User.students
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @students = User.students
  end

  def update
    if @attendance.update(attendance_params)
      redirect_to attendances_path, notice: 'Attendance was successfully updated.'
    else
      @students = User.students
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @attendance.destroy
    redirect_to attendances_path, notice: 'Attendance was successfully deleted.'
  end

  private

  def set_attendance
    @attendance = if current_user.teacher?
      current_user.marked_attendances.find(params[:id])
    else
      current_user.attendances.find(params[:id])
    end
  end

  def attendance_params
    params.require(:attendance).permit(:student_id, :date, :status)
  end

  def authorize_teacher
    unless current_user.teacher?
      redirect_to root_path, alert: 'You are not authorized to perform this action.'
    end
  end
end 