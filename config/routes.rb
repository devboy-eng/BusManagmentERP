Rails.application.routes.draw do
  devise_for :users

  # WhatsApp webhook — unauthenticated, must be outside Devise scope
  scope "webhooks" do
    get "whatsapp", to: "whatsapp_webhooks#verify"
    post "whatsapp", to: "whatsapp_webhooks#receive"
  end

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

  resources :whatsapp_marketing, only: [:index] do
    collection do
      get :compose
      post :send_message
      post :send_bulk
      post :send_quick
      get :message_log
    end
  end

  resource :whatsapp_setting, only: [:edit, :update] do
    post :test_connection
  end

  resources :whatsapp_templates, except: [:show]

  resources :follow_ups, only: [:index, :new, :create, :destroy] do
    member do
      patch :cancel
    end
  end
end
