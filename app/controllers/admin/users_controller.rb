class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy, :update_role]
  before_action :load_class_standards, only: [:new, :create, :edit, :update]

  def index
    @users = User.all.order(created_at: :desc)
    
    # Filter by role if specified
    if params[:role].present?
      @users = @users.where(role: params[:role])
    end
  end

  def new
    @user = User.new
    @roles = [['Teacher', 'teacher'], ['Student', 'student']]
  end

  def create
    @user = User.new(user_params)
    
    # Special handling for student creation
    if @user.student?
      # Set a default password for students (6 characters)
      @user.password = "pucit1"
      
      # Handle class_standard for students
      if params[:user][:class_standard].present?
        class_code = params[:user][:class_standard]
        class_standard = ClassStandard.find_by(code: class_code)
        
        if class_standard
          # Set the class_standard field to the class code directly
          # DO NOT USE write_attribute or @user.class_standard = to avoid model methods
          @user[:class_standard] = class_code
          Rails.logger.info "Setting class_standard to #{class_code} for student (direct attribute access)"
        else
          # If the class doesn't exist, add a flash message
          flash.now[:alert] = "Could not find class with code #{class_code}"
          Rails.logger.error "Class with code #{class_code} not found"
          render :new and return
        end
      end
    elsif @user.teacher?
      # Generate a random password for teachers
      generated_password = SecureRandom.hex(8)
      @user.password = generated_password
    end
    
    # Try to save the user
    if @user.save
      # Handle assigned class standards for teachers
      if @user.teacher? && params[:user][:assigned_class_standard_ids].present?
        params[:user][:assigned_class_standard_ids].each do |class_id|
          ClassStandardTeacherAssignment.create(teacher_id: @user.id, class_standard_id: class_id)
        end
        redirect_to admin_users_path, notice: "Teacher #{@user.full_name} was successfully created. Generated password: #{generated_password}"
      elsif @user.student?
        redirect_to admin_users_path, notice: "Student #{@user.full_name} (#{@user.roll_number}) was successfully created and assigned to class #{@user.class_standard}. Default password: pucit1"
      else
        redirect_to admin_users_path, notice: "User #{@user.full_name} was successfully created."
      end
    else
      @roles = [['Teacher', 'teacher'], ['Student', 'student']]
      Rails.logger.error "Failed to save user: #{@user.errors.full_messages.join(', ')}"
      flash.now[:alert] = "Could not create user: #{@user.errors.full_messages.join(', ')}"
      render :new
    end
  end

  def edit
    @roles = [['Teacher', 'teacher'], ['Student', 'student']]
  end

  def update
    old_role = @user.role
    new_role = params[:user][:role]
    
    # Special handling for role changes
    if old_role != new_role
      flash.now[:info] = "Changing user role from #{old_role.humanize} to #{new_role.humanize}."
      
      # If changing to student, ensure proper fields
      if new_role == 'student'
        # Ensure roll number is present
        unless params[:user][:roll_number].present?
          params[:user][:roll_number] = "HSS#{(800 + rand(100)).to_s}"
        end
        
        # Ensure class is assigned
        unless params[:user][:class_standard].present?
          flash.now[:alert] = "Warning: Student must be assigned to a class."
        end
      end
      
      # If changing from student to another role, ensure email is present
      if old_role == 'student' && new_role != 'student'
        unless params[:user][:email].present?
          default_email = "#{@user.first_name.downcase}#{@user.last_name.downcase}@example.com"
          params[:user][:email] = default_email.gsub(/[^a-z0-9@.]/, '')
        end
      end
    end
    
    # Handle class_standard for students
    if params[:user][:role] == 'student' && params[:user][:class_standard].present?
      class_code = params[:user][:class_standard]
      class_standard = ClassStandard.find_by(code: class_code)
      
      # Only update if a valid class standard was found
      if class_standard
        params[:user][:class_standard] = class_code
      else
        # If invalid class code, don't update this field
        params[:user].delete(:class_standard)
        flash[:alert] = "Warning: Invalid class code provided."
      end
    end
    
    if @user.update(user_params)
      redirect_to admin_users_path, notice: 'User was successfully updated.'
    else
      @roles = [['Admin', 'admin'], ['Teacher', 'teacher'], ['Student', 'student']]
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: 'User was successfully deleted.'
  end

  def update_role
    old_role = @user.role
    
    # Apply similar role change handling as in update method
    if params[:role] == 'student'
      # For student role, set defaults
      @user.roll_number ||= "HSS#{(800 + rand(100)).to_s}"
    elsif old_role == 'student'
      # For changing from student, set email if not present
      @user.email = "#{@user.first_name.downcase}#{@user.last_name.downcase}@example.com".gsub(/[^a-z0-9@.]/, '') if @user.email.blank?
    end
    
    if @user.update(role: params[:role])
      redirect_to admin_users_path, notice: 'User role was successfully updated.'
    else
      redirect_to admin_users_path, alert: "Failed to update user role: #{@user.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def load_class_standards
    @class_standards = ClassStandard.active.order(:year, :section).map do |cs|
      ["#{cs.year} - #{cs.name}#{cs.section ? " (#{cs.section})" : ''}", cs.code]
    end
  end

  def user_params
    params.require(:user).permit(
      :email, 
      :first_name, 
      :last_name, 
      :role, 
      :class_standard,
      :roll_number,
      assigned_class_standard_ids: []
    )
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 