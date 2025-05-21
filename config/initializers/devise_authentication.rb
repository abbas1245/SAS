# Ensure Devise authentication is properly loaded
Rails.application.config.to_prepare do
  Devise::SessionsController.layout "application"
  Devise::RegistrationsController.layout "application"
  Devise::ConfirmationsController.layout "application"
  Devise::UnlocksController.layout "application"
  Devise::PasswordsController.layout "application"
end 