Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  devise_for :users

  ActiveAdmin.routes(self)

  namespace :api do
    namespace :v1 do
      namespace :webhooks do
        resources :events, only: :create
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  authenticated :user do
    root "dashboard#show", as: :authenticated_root
    resources :cashout_requests, only: :create
  end

  unauthenticated do
    root to: redirect("/users/sign_in"), as: :unauthenticated_root
  end
end
