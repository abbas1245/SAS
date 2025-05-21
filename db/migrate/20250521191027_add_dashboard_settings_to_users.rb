class AddDashboardSettingsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :dashboard_settings, :json, default: {
      show_attendance_stats: true,
      show_recent_activities: true,
      show_quick_actions: true,
      default_view: 'overview',
      notification_preferences: {
        email: true,
        dashboard: true
      }
    }
  end
end
