Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  post "ratings/rate"

  # Favorites
  resources :favorites
  get "favorites/add/:id", controller: "favorites", action: "add"
  get "favorites/remove/:id", controller: "favorites", action: "remove"

  devise_for :users

  resources :genders

  resources :locations

  resources :countries

  resources :radios do
    resource :comments
    member do
      get "now_playing"
    end
  end

  root to: "home#index"
end
