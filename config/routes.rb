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

  # CSAT Feedback — public, token-authenticated
  get  "feedback/:token", to: "feedback#show",   as: :feedback
  post "feedback/:token", to: "feedback#submit", as: :submit_feedback

  get "up" => "rails/health#show", as: :rails_health_check
  root "dashboard#index"

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

  resources :leads do
    member do
      patch :update_status
    end
    collection do
      get :bulk_upload
      post :import
    end
    resources :comments, only: [:create]
  end

  resources :users do
    member do
      patch :toggle_status
    end
  end
  resources :roles

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
  end

  resources :uploads, only: [:create]

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

  resources :follow_ups, only: [:index, :new, :create, :destroy] do
    member do
      patch :cancel
    end
  end

  resources :csat, only: [:index] do
    collection do
      post :generate_link
    end
    member do
      get :agent
    end
  end
end
