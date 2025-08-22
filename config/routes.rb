Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # get "client_sessions/index"
  root "home#index"

  # get "radprofile/new"
  # get "radprofile/show"
  # get "radprofile/index"
  #
  get "/hotspot/new", to: "hotspot#new", as: :hotspot_new
  post "/hotspot/choose_subscription", to: "hotspot#choose_subscription", as: :hotspot_choose_subscription
  get "/hotspot/waiting", to: "hotspot#waiting", as: :hotspot_waiting # For payment waiting page
  get "/hotspot/payment_status", to: "hotspot#payment_status", as: :hotspot_payment_status
  get "initiate_login", to: "hotspot#initiate_login", as: :initiate_login
  resources :hotspot do
    # ... other routes ...
    get :gift, on: :collection
    get :redeem_gift, on: :collection
  end

  # M-Pesa callback endpoint (this needs to be publicly accessible)
  resources :radprofile, param: :group_name
  post "radprofile", to: "radprofile#create"
  resources :client_sessions, only: [ :index ] do
    collection do
      get :refresh # Route for the auto-refresh endpoint
    end
  end

  # the route for mpesa API
  post "/webhooks/mpesa", to: "payments#create"

  # the route for field A/B testing
  mount FieldTest::Engine, at: "field_test"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
