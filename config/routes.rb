Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "welcome#index"

  namespace :auth do
    match "/salesforce/callback", :to => "session#callback", :via => [:get, :post]
  end
end
