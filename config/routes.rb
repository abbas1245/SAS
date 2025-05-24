Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Public routes (no authentication required)
  root 'home#index'
  get '/:class_standard/report', to: 'reports#public_class_report', as: :public_class_report

  # Authenticated routes
  authenticate :user do
    # Admin routes
    namespace :admin do
      root 'dashboard#index'
      
      # Add a direct route for assigning classes to teachers
      get 'teacher/:teacher_id/assign_class', to: 'teacher_assignments#assign_class', as: :teacher_assign_class
      post 'teacher/:teacher_id/assign_class', to: 'teacher_assignments#process_assign_class', as: :process_teacher_assign_class
      
      resources :users do
        member do
          patch :update_role
        end
      end
      resources :class_standards do
        resources :teacher_assignments, only: [:new, :create, :destroy] do
          collection do
            get :check_teacher_classes
            post :activate_all_assignments
          end
        end
      end
      resources :reports, only: [:index, :show] do
        collection do
          get :class_wise
          get :teacher_wise
          get :student_wise
          get :export
        end
      end
    end

    # Teacher routes
    namespace :teacher do
      root 'dashboard#index', constraints: lambda { |req| req.env['warden'].user&.teacher? }
      resources :attendance, only: [:index, :new, :create] do
        collection do
          get :class_standards
          get :students
          post :mark
        end
      end
      resources :reports, only: [:index, :show] do
        collection do
          get :class_wise
          get :student_wise
        end
      end
    end

    # Student routes (for authenticated students)
    namespace :student do
      root 'dashboard#index', constraints: lambda { |req| req.env['warden'].user&.student? }
      resources :attendance, only: [:index] do
        collection do
          get :report
        end
      end
    end

    # Common authenticated routes
    get 'dashboard', to: 'dashboard#index', as: :dashboard
  end

  # Common routes
  resources :reports, only: [:index] do
    collection do
      get :download
    end
  end
end
