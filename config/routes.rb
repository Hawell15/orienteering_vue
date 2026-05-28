Rails.application.routes.draw do
  devise_for :users
  resources :memberships do
    get :filters, on: :collection
  end

  resources :results do
    get :filters, on: :collection
  end

  resources :groups do
    get :filters, on: :collection
    member do
      post "count_rang"
    end
  end
  resources :competitions do
    get :distance_types, on:  :collection
    get :filters, on: :collection
    get :ecn_ranking, on: :collection
    get :ecn_runner_results, on: :collection
    member do
      get "group_filters"
      get "new_runners"
      post "group_ecn_coeficients"
      post "update_group_clasa"
      post "reimport_wre_points"
    end
  end
  resources :runners do
     get :filters, on: :collection
     get :category_check, on: :collection
     member do
       post "merge_runners"
     end
  end

  post "/clubs/merge_clubs/:id", to: "clubs#merge_clubs"

  resources :clubs do
  end

  resources :categories do
    get :expired, on: :collection
  end

  root "home#index"
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  get "parser/index", as: "parser"
  get "parser/iof_runners", as: "iof_runners"
  get "parser/iof_results", as: "iof_results"
  get "parser/file_results", as: "file_results"
  post "parser/file_results"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
