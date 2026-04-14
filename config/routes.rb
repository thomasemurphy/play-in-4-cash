Rails.application.routes.draw do
  resource :registration, only: [:new, :create]
  resource :session
  resources :passwords, param: :token
  resources :picks, only: [:index, :create, :update]
  get "leaderboard", to: "leaderboard#index", as: :leaderboard
  resource :account, only: [:edit, :update]

  namespace :admin do
    root to: "games#index"
    resources :games, only: [:index, :update]
    resources :picks, only: [:index] do
      collection do
        patch :upsert
      end
    end
    resources :users, only: [:index]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "picks#index"
end
