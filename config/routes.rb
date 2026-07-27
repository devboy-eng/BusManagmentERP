Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: "users/sessions" }

  devise_scope :user do
    get  "users/verify_otp", to: "users/sessions#verify_otp", as: :verify_otp
    post "users/confirm_otp", to: "users/sessions#confirm_otp", as: :confirm_otp
    post "users/resend_otp", to: "users/sessions#resend_otp", as: :resend_otp
  end

  # WhatsApp webhook — unauthenticated, must be outside Devise scope
  scope "webhooks" do
    get "whatsapp", to: "whatsapp_webhooks#verify"
    post "whatsapp", to: "whatsapp_webhooks#receive"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"
  get "dashboard", to: "dashboard#index"

  resources :customers do
    member do
      patch :toggle_status
    end
    collection do
      get :bulk_upload
      post :import
    end
    resources :comments, only: [:create]
  end

  resources :vehicles do
    member do
      get :service_history
    end
  end

  resources :job_cards do
    member do
      patch :advance_status
      post :send_estimate
      post :generate_invoice
      post :issue_gate_pass
    end
    resources :inspections, only: [:new, :create, :show]
    resources :estimates, only: [:new, :create, :show, :edit, :update]
    resources :technician_assignments, only: [:create, :update, :destroy]
  end

  resources :invoices, only: [:index, :show, :edit, :update]
  resources :payments, only: [:index, :new, :create]
  resources :technicians
  resources :service_types, except: [:show]
  resources :branches, except: [:show]
  resources :spare_parts do
    collection do
      get :low_stock
    end
  end
  resources :suppliers
  resources :warehouses
  resources :purchase_orders do
    member do
      patch :receive
    end
  end
  resources :inventory_movements, only: [:index]
  resources :service_reminders, except: [:show]

  # Reports
  get "reports", to: "reports#show"
  get "reports/revenue", to: "reports#revenue"
  get "reports/technician_productivity", to: "reports#technician_productivity"
  get "reports/parts_usage", to: "reports#parts_usage"
  get "reports/vehicle_turnaround", to: "reports#vehicle_turnaround"
  get "reports/inventory_valuation", to: "reports#inventory_valuation"

  # Public approval routes (no auth)
  get "approve/:token", to: "approvals#show", as: :customer_approval
  post "approve/:token", to: "approvals#approve"
  post "approve/:token/reject", to: "approvals#reject", as: :customer_rejection
  get "manager-approve/:token", to: "approvals#manager_show", as: :manager_approval
  post "manager-approve/:token", to: "approvals#manager_approve"

  # WhatsApp
  resources :whatsapp_chats, only: [:index, :show] do
    member do
      post :send_reply
      patch :mark_read
      post :send_to_lead
      post :send_media
      post :react
      post :assign
      delete :unassign
      post :schedule_message
    end
    collection do
      get :search
    end
  end

  resources :quick_responses, except: [:show]
  resources :auto_reply_rules, except: [:show] do
    member { patch :toggle }
  end
  resources :scheduled_messages, only: [:index, :destroy] do
    member { patch :cancel }
  end

  resource :whatsapp_guide, only: [:show], controller: "whatsapp_guide"

  resources :whatsapp_marketing, only: [:index] do
    collection do
      post :send_quick_whatsapp
      post :send_bulk_whatsapp
      get :templates
      get :template_analytics
      get :compose
      post :send_message
      post :send_template
      post :send_bulk
      post :send_quick
      get :message_log
    end
  end

  resource :whatsapp_setting, only: [:edit, :update] do
    post :test_connection
    post :sync_quality
  end

  resources :uploads, only: [:create]

  resources :whatsapp_menus, except: [:show] do
    member do
      patch :toggle
      post :send_menu
    end
  end

  resources :whatsapp_templates, except: [:show] do
    collection do
      post :sync_all
    end
    member do
      post :sync_to_meta
      post :sync_status
      post :delete_from_meta
    end
  end

  # Users/Roles
  resources :users do
    member do
      patch :toggle_active
    end
  end
  resources :roles
end
