Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "slides#index"

  # ActionCable WebSocket サーバー
  mount ActionCable.server => '/cable'

  resources :slides do
    member do
      post :build
      get :slide_html
    end
  end
end
