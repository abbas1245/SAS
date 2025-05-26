class Teacher::AttendanceController < ApplicationController
  before_action :authenticate_user!
  before_action :require_teacher
  before_action :set_class_standards
  before_action :set_class_standard, only: [:mark]
  before_action :set_today_attendance, only: [:index]

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
      @students = @class_standard.students.order(:first_name, :last_name)
      result = @students.map { |s| 
        attendance = s.attendances.where(date: Date.current).first
        { 
          id: s.id, 
          name: s.full_name,
          roll_number: s.roll_number,
          attendance: attendance&.status 
        } 
      }
      render json: result
    rescue => e
      render json: { error: "Error loading students: #{e.message}" }, status: :unprocessable_entity
    end
  end

  def mark
    Rails.logger.info "Starting attendance marking process for class: #{@class_standard.code}"
    Rails.logger.info "Attendance params: #{params[:attendance].inspect}"

    ActiveRecord::Base.transaction do
      params[:attendance].each do |student_id, status|
        # Skip if status is not set
        next if status.blank?
        
        Rails.logger.info "Processing attendance for student #{student_id} with status: #{status}"
        
        # Find or initialize attendance record
        attendance = Attendance.find_or_initialize_by(
          student_id: student_id,
          teacher_id: current_user.id,
          date: Date.current,
          class_standard: @class_standard.code
        )
        
        # Set the status and save
        attendance.status = status.to_s.downcase.strip # Ensure status is a string, lowercase, and trimmed
        if attendance.save
          Rails.logger.info "Successfully saved attendance for student #{student_id}: #{attendance.inspect}"
        else
          Rails.logger.error "Failed to save attendance for student #{student_id}: #{attendance.errors.full_messages.join(', ')}"
          raise ActiveRecord::RecordInvalid.new(attendance)
        end
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
    Rails.logger.error "Error marking attendance: #{e.message}"
    respond_to do |format|
      format.html { 
        flash[:alert] = "Error: #{e.message}"
        redirect_to teacher_attendance_index_path(class_standard_id: params[:class_standard_id])
      }
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
    end
  end

  private

  def set_class_standards
    @class_standards = current_user.teaching_class_standards
  end

  def set_class_standard
    if params[:class_standard_id].present?
      @class_standard = @class_standards.find(params[:class_standard_id])
    else
      flash[:alert] = "Please select a class first."
      redirect_to teacher_attendance_index_path
    end
  end

  def set_today_attendance
    return unless @selected_class

    @today_attendance = Attendance.where(
      student_id: @selected_class.students.pluck(:id),
      teacher_id: current_user.id,
      date: Date.current,
      class_standard: @selected_class.code
    ).index_by(&:student_id)
  end

  def require_teacher
    unless current_user&.teacher?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 