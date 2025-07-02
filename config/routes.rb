Rails.application.routes.draw do
  root "home#index"

  # get "radprofile/new"
  # get "radprofile/show"
  # get "radprofile/index"
  #
  get "/hotspot/new", to: "hotspot#new", as: :hotspot_new
  post "/hotspot/choose_subscription", to: "hotspot#choose_subscription", as: :hotspot_choose_subscription
  get "/hotspot/waiting", to: "hotspot#waiting", as: :hotspot_waiting # For payment waiting page
  get "/hotspot/payment_status", to: "hotspot#payment_status", as: :hotspot_payment_status

  # M-Pesa callback endpoint (this needs to be publicly accessible)
  resources :radprofile, param: :group_name
  post "radprofile", to: "radprofile#create"

  # the route for mpesa API
  post "/webhooks/mpesa", to: "payments#create"

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
