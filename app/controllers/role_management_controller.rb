class RoleManagementController < ApplicationController
  before_action :set_user, only: [:edit, :update]
  before_action :require_admin_or_role_setup

  def index
    @users = User.all.order(created_at: :desc)
  end

  def edit
    @dashboard_settings = @user.dashboard_settings || {}
  end

  def update
    if @user.update(user_params)
      redirect_to role_management_index_path, notice: 'User role and settings updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:role, dashboard_settings: {
      show_attendance_stats: :boolean,
      show_recent_activities: :boolean,
      show_quick_actions: :boolean,
      default_view: :string,
      notification_preferences: {
        email: :boolean,
        dashboard: :boolean
      }
    })
  end

  def require_admin_or_role_setup
    # Allow access if user is admin
    return if current_user&.admin?

    # Allow access if user has no role (for role setup)
    return if current_user&.role.blank?

    # Otherwise, redirect to dashboard
    flash[:alert] = 'You are not authorized to access this page.'
    redirect_to dashboard_path
  end
end 