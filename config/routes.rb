Rails.application.routes.draw do
  resource :registration, only: [:new, :create]
  resource :session
  resources :passwords, param: :token
  resources :picks, only: [:index, :create, :update]

  get "up" => "rails/health#show", as: :rails_health_check

  root "picks#index"
end
