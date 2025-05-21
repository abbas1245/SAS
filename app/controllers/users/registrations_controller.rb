class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]
  before_action :check_existing_teacher, only: [:new, :create]

  protected

  def configure_sign_up_params
    # Only allow email and password for registration
    # Role will be set to admin by default for new registrations
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email, :password, :password_confirmation])
  end

  def configure_account_update_params
    # Allow updating additional fields only for existing users
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name, :class_standard])
  end

  def build_resource(hash = {})
    # For new registrations, check if it's a teacher trying to set password
    if action_name == 'new' && params[:email].present?
      existing_user = User.find_by(email: params[:email], role: :teacher)
      if existing_user && !existing_user.encrypted_password.present?
        # If it's a teacher without a password, use that user
        self.resource = existing_user
        return
      end
    end
    
    # For normal registration, set role to admin
    hash[:role] = :admin
    super(hash)
  end

  def after_sign_up_path_for(resource)
    if resource.teacher?
      teacher_root_path
    else
      admin_root_path
    end
  end

  def after_update_path_for(resource)
    if resource.teacher?
      teacher_root_path
    else
      admin_root_path
    end
  end

  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  private

  def check_existing_teacher
    if action_name == 'new' && params[:email].present?
      @existing_teacher = User.find_by(email: params[:email], role: :teacher)
      if @existing_teacher
        if @existing_teacher.encrypted_password.present?
          # If teacher already has a password, redirect to login
          redirect_to new_user_session_path, alert: "This email is already registered. Please login."
        end
      end
    end
  end
end 