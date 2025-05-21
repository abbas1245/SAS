class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :validate_user_role

  def index
    @user = current_user
    @dashboard_settings = @user.dashboard_settings || {}
    
    # If user has no role, render a different view
    if @user.role.blank?
      render :role_required
      return
    end
    
    case @user.role
    when 'student'
      @recent_attendances = @user.attendances.order(created_at: :desc).limit(5)
      @attendance_stats = calculate_student_stats
    when 'teacher'
      @recent_classes = @user.marked_attendances.order(created_at: :desc).limit(5)
      @class_stats = calculate_teacher_stats
    when 'admin'
      @total_students = User.students.count
      @total_teachers = User.teachers.count
      @recent_activities = Attendance.order(created_at: :desc).limit(10)
    else
      flash[:alert] = "Invalid user role. Please contact administrator."
      redirect_to role_management_index_path and return
    end
  end

  private

  def validate_user_role
    # Only redirect if we're not already on the role management page
    if current_user&.role.blank? && !request.path.start_with?('/role-management')
      flash[:alert] = "User role not set. Please set your role to continue."
      redirect_to role_management_index_path
    end
  end

  def calculate_student_stats
    total_classes = Attendance.where(student_id: @user.id).count
    present_classes = Attendance.where(student_id: @user.id, status: 'present').count
    attendance_percentage = total_classes.positive? ? (present_classes.to_f / total_classes * 100).round(2) : 0
    
    {
      total_classes: total_classes,
      present_classes: present_classes,
      attendance_percentage: attendance_percentage
    }
  end

  def calculate_teacher_stats
    total_classes = @user.marked_attendances.count
    total_students = Attendance.where(teacher_id: @user.id).select(:student_id).distinct.count
    
    {
      total_classes: total_classes,
      total_students: total_students
    }
  end
end 