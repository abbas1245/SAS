class Teacher::AttendanceController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher
  before_action :set_class_standard, only: [:students, :mark]

  def index
    @class_standards = current_user.teaching_class_standards
    
    # If a class is selected, preload the students
    if params[:class_standard_id].present?
      begin
        @selected_class = @class_standards.find(params[:class_standard_id])
        @students = @selected_class.students.order(:first_name, :last_name)
        
        # Get today's attendance records
        student_ids = @students.pluck(:id)
        @today_attendance = Attendance.where(
          student_id: student_ids, 
          date: Date.current,
          class_standard: @selected_class.code
        ).index_by(&:student_id)
        
      rescue ActiveRecord::RecordNotFound
        flash.now[:alert] = "Selected class not found."
      end
    end
    
    # Debug information
    Rails.logger.debug "Teacher #{current_user.id} (#{current_user.email}) has #{@class_standards.count} active classes"
    
    if @class_standards.empty?
      # Check if there are any teacher_class_standards records assigned but not showing up
      assigned_records = current_user.teacher_class_standards
      Rails.logger.debug "Teacher has #{assigned_records.count} teacher_class_standards records"
      assigned_records.each do |tcs|
        class_std = tcs.class_standard
        Rails.logger.debug "  - Class ID: #{class_std.id}, Name: #{class_std.name}, Active (class): #{class_std.active}, Active (assignment): #{tcs.active}"
      end
    end
  end

  def class_standards
    @class_standards = current_user.teaching_class_standards
    Rails.logger.debug "API: Teacher #{current_user.id} has #{@class_standards.count} active classes: #{@class_standards.map(&:display_name).join(', ')}"
    
    result = @class_standards.map { |cs| { id: cs.id, name: cs.display_name } }
    Rails.logger.debug "Returning JSON with #{result.length} classes: #{result.inspect}"
    
    render json: result
  end

  def students
    begin
      Rails.logger.debug "Finding students for class_standard_id: #{params[:class_standard_id]}"
      @students = @class_standard.students.order(:first_name, :last_name)
      
      if @students.empty?
        Rails.logger.debug "No students found for class standard #{@class_standard.display_name}"
      else
        Rails.logger.debug "Found #{@students.count} students for class standard #{@class_standard.display_name}"
      end
      
      result = @students.map { |s| 
        attendance = s.attendances.where(date: Date.current).first
        { 
          id: s.id, 
          name: s.full_name,
          roll_number: s.roll_number,
          attendance: attendance&.status 
        } 
      }
      
      Rails.logger.debug "Returning JSON with #{result.length} students"
      render json: result
    rescue => e
      Rails.logger.error "Error fetching students: #{e.message}"
      render json: { error: "Error loading students: #{e.message}" }, status: :unprocessable_entity
    end
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

    respond_to do |format|
      format.html { 
        flash[:notice] = "Attendance marked successfully"
        redirect_to teacher_root_path 
      }
      format.json { render json: { message: 'Attendance marked successfully' } }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.html { 
        flash[:alert] = "Error: #{e.message}"
        redirect_to teacher_attendance_index_path(class_standard_id: params[:class_standard_id])
      }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
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