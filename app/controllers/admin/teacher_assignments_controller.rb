class Admin::TeacherAssignmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_admin
  before_action :set_class_standard

  def new
    @teacher_assignment = TeacherClassStandard.new(
      start_date: Date.current,
      active: true
    )
    @available_teachers = User.where(role: :teacher).order(:first_name, :last_name)
  end

  def create
    @teacher_assignment = @class_standard.teacher_class_standards.build(teacher_assignment_params)
    # Set default values
    @teacher_assignment.start_date ||= Date.current
    @teacher_assignment.active = true
    
    if @teacher_assignment.save
      redirect_to admin_class_standard_path(@class_standard), notice: 'Teacher was successfully assigned to class.'
    else
      @available_teachers = User.where(role: :teacher).order(:first_name, :last_name)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @teacher_assignment = @class_standard.teacher_class_standards.find(params[:id])
    @teacher_assignment.destroy
    
    redirect_to admin_class_standard_path(@class_standard), notice: 'Teacher assignment was successfully removed.'
  end

  # Add a diagnostic method to check teacher's classes
  def check_teacher_classes
    @teacher = User.find(params[:teacher_id])
    
    @assigned_classes = @teacher.teacher_class_standards
    @active_assignments = @teacher.teacher_class_standards.where(active: true)
    @active_classes = @teacher.assigned_class_standards.where(active: true)
    @teaching_classes = @teacher.teaching_class_standards
    
    render :check_teacher_classes
  end
  
  # Add a dedicated UI for assigning classes to teachers
  def assign_class
    @teacher = User.find(params[:teacher_id])
    @available_classes = ClassStandard.all
    @teacher_assignment = TeacherClassStandard.new(
      teacher_id: @teacher.id,
      start_date: Date.current,
      active: true
    )
  end
  
  # Process the assignment from the dedicated UI
  def process_assign_class
    @teacher = User.find(params[:teacher_id])
    @teacher_assignment = TeacherClassStandard.new(assign_class_params)
    @teacher_assignment.start_date ||= Date.current
    @teacher_assignment.active = true
    
    if @teacher_assignment.save
      redirect_to check_teacher_classes_admin_class_standard_teacher_assignments_path(
        class_standard_id: @teacher_assignment.class_standard_id, 
        teacher_id: @teacher.id
      ), notice: 'Teacher was successfully assigned to class.'
    else
      @available_classes = ClassStandard.all
      render :assign_class, status: :unprocessable_entity
    end
  end

  # Add a method to activate all teacher class assignments
  def activate_all_assignments
    teacher_id = params[:teacher_id]
    
    # Update all assignments for this teacher to be active
    TeacherClassStandard.where(teacher_id: teacher_id).update_all(active: true)
    
    # Also ensure all assigned classes are active
    class_ids = TeacherClassStandard.where(teacher_id: teacher_id).pluck(:class_standard_id)
    ClassStandard.where(id: class_ids).update_all(active: true)
    
    redirect_to admin_class_standards_path, notice: 'All teacher class assignments have been activated'
  end

  private

  def set_class_standard
    # Only try to set the class standard if we have the parameter
    # This allows our new actions to work without a class_standard_id
    if params[:class_standard_id].present?
      @class_standard = ClassStandard.find(params[:class_standard_id])
    end
  end

  def teacher_assignment_params
    params.require(:teacher_class_standard).permit(:teacher_id, :is_primary_teacher, :start_date, :active)
  end

  def authorize_admin
    redirect_to root_path, alert: 'Not authorized.' unless current_user.admin?
  end

  def assign_class_params
    params.require(:teacher_class_standard).permit(:teacher_id, :class_standard_id, :is_primary_teacher)
  end
end 