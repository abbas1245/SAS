class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy, :update_role]
  before_action :load_class_standards, only: [:new, :create, :edit, :update]

  def index
    @users = User.all.order(created_at: :desc)
  end

  def new
    @user = User.new
    @roles = [['Teacher', 'teacher'], ['Student', 'student']]
  end

  def create
    @user = User.new(user_params)
    
    if @user.teacher?
      # Generate a random password for teachers
      generated_password = SecureRandom.hex(8)
      @user.password = generated_password
      
      if @user.save
        redirect_to admin_users_path, notice: "Teacher was successfully created. Generated password: #{generated_password}"
      else
        @roles = [['Teacher', 'teacher'], ['Student', 'student']]
        render :new
      end
    else
      # For students, no password needed
      if @user.save
        redirect_to admin_users_path, notice: 'Student was successfully created.'
      else
        @roles = [['Teacher', 'teacher'], ['Student', 'student']]
        render :new
      end
    end
  end

  def edit
    @roles = [['Teacher', 'teacher'], ['Student', 'student']]
  end

  def update
    if @user.update(user_params)
      redirect_to admin_users_path, notice: 'User was successfully updated.'
    else
      @roles = [['Teacher', 'teacher'], ['Student', 'student']]
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: 'User was successfully deleted.'
  end

  def update_role
    if @user.update(role: params[:role])
      redirect_to admin_users_path, notice: 'User role was successfully updated.'
    else
      redirect_to admin_users_path, alert: 'Failed to update user role.'
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
      :class_standard
    )
  end

  def require_admin
    unless current_user&.admin?
      flash[:alert] = "You are not authorized to access this area."
      redirect_to root_path
    end
  end
end 